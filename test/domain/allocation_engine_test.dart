// AllocationEngine tests — INV-3/4/5/6, sorting, want, enough/not-enough,
// completion release, deadline flags.
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/domain/allocation/allocation_engine.dart';
import 'package:wealthlens/domain/models/enums.dart';

void main() {
  WalletSnapshot snap({
    required String id,
    required WalletCategory category,
    required int priorityRank,
    int current = 0,
    int targetAmount = 1000000,
    int monthlyContribution = 100000,
    bool hasPeriod = false,
  }) =>
      WalletSnapshot(
        id: id,
        category: category,
        priorityRank: priorityRank,
        current: current,
        targetAmount: targetAmount,
        monthlyContribution: monthlyContribution,
        hasPeriod: hasPeriod,
      );

  int sumAlloc(AllocationResult r) =>
      r.allocations.values.fold(0, (a, b) => a + b);

  group('排序 + INV-5 保障優先', () {
    test('safety wallets are served before goals regardless of input order',
        () {
      // Input order scrambled; only enough money for the first two wants.
      final input = AllocationInput(
        investableAmount: 200000,
        remainingMonthsThisYear: 12,
        wallets: [
          snap(
            id: 'goal',
            category: WalletCategory.savingGoal,
            priorityRank: 3,
          ),
          snap(
            id: 'fin',
            category: WalletCategory.financialSafety,
            priorityRank: 1,
          ),
          snap(
            id: 'life',
            category: WalletCategory.lifeSafety,
            priorityRank: 2,
          ),
        ],
      );

      final r = AllocationEngine.allocate(input);
      // fin + life consume 100000 each → goal gets 0.
      expect(r.allocations['fin'], 100000);
      expect(r.allocations['life'], 100000);
      expect(r.allocations['goal'], 0);
    });
  });

  group('want', () {
    test('want = min(monthlyContribution, room); at-target consumes nothing',
        () {
      final input = AllocationInput(
        investableAmount: 1000000,
        remainingMonthsThisYear: 12,
        wallets: [
          // already at target → want 0
          snap(
            id: 'full',
            category: WalletCategory.savingGoal,
            priorityRank: 3,
            current: 1000000,
          ),
          // room 40000 < monthly 100000 → want 40000
          snap(
            id: 'near',
            category: WalletCategory.savingGoal,
            priorityRank: 4,
            current: 960000,
          ),
        ],
      );

      final r = AllocationEngine.allocate(input);
      expect(r.allocations['full'], 0);
      expect(r.allocations['near'], 40000);
    });
  });

  group('錢夠', () {
    test('everyone gets their want, leftover becomes surplus (INV-6)', () {
      final input = AllocationInput(
        investableAmount: 500000,
        remainingMonthsThisYear: 12,
        wallets: [
          snap(
            id: 'fin',
            category: WalletCategory.financialSafety,
            priorityRank: 1,
          ),
          snap(id: 'g', category: WalletCategory.savingGoal, priorityRank: 3),
        ],
      );

      final r = AllocationEngine.allocate(input);
      expect(r.allocations['fin'], 100000);
      expect(r.allocations['g'], 100000);
      expect(r.surplus, 300000);
      expect(sumAlloc(r) + r.surplus, input.investableAmount);
    });
  });

  group('錢不夠', () {
    test('top fills, last takes partial, rest take 0; deficit at the tail', () {
      final input = AllocationInput(
        investableAmount: 150000,
        remainingMonthsThisYear: 12,
        wallets: [
          snap(
            id: 'fin',
            category: WalletCategory.financialSafety,
            priorityRank: 1,
          ),
          snap(id: 'g1', category: WalletCategory.savingGoal, priorityRank: 3),
          snap(id: 'g2', category: WalletCategory.savingGoal, priorityRank: 4),
        ],
      );

      final r = AllocationEngine.allocate(input);
      expect(r.allocations['fin'], 100000); // full
      expect(r.allocations['g1'], 50000); // partial
      expect(r.allocations['g2'], 0); // nothing left
      expect(r.surplus, 0);
    });
  });

  group('不變量', () {
    test('INV-3 不超分 / INV-4 不超目標 / INV-6 守恆', () {
      final input = AllocationInput(
        investableAmount: 333333,
        remainingMonthsThisYear: 8,
        wallets: [
          snap(
            id: 'fin',
            category: WalletCategory.financialSafety,
            priorityRank: 1,
            current: 950000,
          ),
          snap(
            id: 'g1',
            category: WalletCategory.savingGoal,
            priorityRank: 3,
            monthlyContribution: 200000,
          ),
          snap(
            id: 'g2',
            category: WalletCategory.savingGoal,
            priorityRank: 4,
            monthlyContribution: 200000,
          ),
        ],
      );

      final r = AllocationEngine.allocate(input);
      // INV-3
      expect(sumAlloc(r), lessThanOrEqualTo(input.investableAmount));
      // INV-4: fin only gets its room (50000), never more
      expect(r.allocations['fin'], 50000);
      // INV-6
      expect(sumAlloc(r) + r.surplus, input.investableAmount);
    });
  });

  group('完成釋出', () {
    test('reaching target does not auto-relay; leftover goes to surplus', () {
      final input = AllocationInput(
        investableAmount: 500000,
        remainingMonthsThisYear: 12,
        wallets: [
          // room 30000 (< monthly 100000): this allocation completes it.
          snap(
            id: 'almost',
            category: WalletCategory.savingGoal,
            priorityRank: 3,
            current: 970000,
          ),
        ],
      );

      final r = AllocationEngine.allocate(input);
      expect(r.allocations['almost'], 30000); // completes, not the full monthly
      expect(r.surplus, 470000); // freed amount is NOT auto-assigned
    });
  });

  group('死線', () {
    test('goal projected to miss is flagged; amounts unchanged', () {
      final input = AllocationInput(
        investableAmount: 100000,
        remainingMonthsThisYear: 3,
        wallets: [
          // remaining 900000 / monthly 100000 = 9 months > 3 → flag
          snap(
            id: 'slow',
            category: WalletCategory.savingGoal,
            priorityRank: 3,
            current: 100000,
            hasPeriod: true,
          ),
        ],
      );

      final r = AllocationEngine.allocate(input);
      expect(r.deadlineFlags, contains('slow'));
      // flag does NOT change the allocation amount
      expect(r.allocations['slow'], 100000);
    });

    test('goal on track is not flagged', () {
      final input = AllocationInput(
        investableAmount: 100000,
        remainingMonthsThisYear: 12,
        wallets: [
          snap(
            id: 'ok',
            category: WalletCategory.savingGoal,
            priorityRank: 3,
            current: 900000,
            hasPeriod: true,
          ),
        ],
      );

      final r = AllocationEngine.allocate(input);
      expect(r.deadlineFlags, isEmpty);
    });

    test('goal without a period is never deadline-flagged', () {
      final input = AllocationInput(
        investableAmount: 0,
        remainingMonthsThisYear: 1,
        wallets: [
          snap(
            id: 'noperiod',
            category: WalletCategory.savingGoal,
            priorityRank: 3,
          ),
        ],
      );

      final r = AllocationEngine.allocate(input);
      expect(r.deadlineFlags, isEmpty);
    });
  });
}
