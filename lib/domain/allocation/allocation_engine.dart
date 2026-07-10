/// The allocation engine — pure Dart, no Flutter, no IO, no mutation.
///
/// Given an investable amount and a set of wallet snapshots, decides how much
/// goes to each wallet this month. Safety layers are always served before
/// goals (INV-5); allocations never exceed the investable amount (INV-3) nor
/// push a wallet past its target (INV-4); and the conservation law holds:
/// Σ allocations + surplus == investable (INV-6). All amounts are integer
/// cents.
library;

import 'package:wealthlens/domain/models/enums.dart';

/// A minimal, immutable view of a wallet for allocation.
class WalletSnapshot {
  /// Creates a [WalletSnapshot].
  const WalletSnapshot({
    required this.id,
    required this.category,
    required this.priorityRank,
    required this.current,
    required this.targetAmount,
    required this.monthlyContribution,
    this.hasPeriod = false,
  });

  /// Wallet id (key in the result map).
  final String id;

  /// Category, governing ordering (safety before goals).
  final WalletCategory category;

  /// Ordering rank within the same category band.
  final int priorityRank;

  /// Current saved amount (cents).
  final int current;

  /// Target amount (cents).
  final int targetAmount;

  /// User-set monthly top-up (cents).
  final int monthlyContribution;

  /// Whether the wallet has a deadline (only goals are deadline-checked).
  final bool hasPeriod;
}

/// Input to [AllocationEngine.allocate].
class AllocationInput {
  /// Creates an [AllocationInput].
  const AllocationInput({
    required this.investableAmount,
    required this.wallets,
    required this.remainingMonthsThisYear,
  });

  /// Amount available to allocate this month (cents).
  final int investableAmount;

  /// Wallet snapshots to allocate across (any order).
  final List<WalletSnapshot> wallets;

  /// Months left in the current year, used for the deadline check.
  final int remainingMonthsThisYear;
}

/// Result of an allocation run.
class AllocationResult {
  /// Creates an [AllocationResult].
  const AllocationResult({
    required this.allocations,
    required this.surplus,
    required this.deadlineFlags,
  });

  /// Allocated amount per wallet id (cents).
  final Map<String, int> allocations;

  /// Unassigned remainder, released for the user to direct (cents).
  final int surplus;

  /// Ids of goals projected to miss their deadline (neutral flag).
  final Set<String> deadlineFlags;
}

/// Allocates an investable amount across wallets (pure function).
class AllocationEngine {
  /// Runs the allocation. See class docs for the invariants it upholds.
  static AllocationResult allocate(AllocationInput input) {
    final sorted = [...input.wallets]..sort(_byCategoryThenRank);

    final allocations = <String, int>{};
    final deadlineFlags = <String>{};
    var remaining = input.investableAmount;

    for (final w in sorted) {
      final want = _want(w);
      final give = want < remaining ? want : remaining;
      final amount = give < 0 ? 0 : give;
      allocations[w.id] = amount;
      remaining -= amount;

      if (w.hasPeriod &&
          w.category == WalletCategory.savingGoal &&
          _projectedMonths(w) > input.remainingMonthsThisYear) {
        deadlineFlags.add(w.id);
      }
    }

    return AllocationResult(
      allocations: allocations,
      surplus: remaining < 0 ? 0 : remaining,
      deadlineFlags: deadlineFlags,
    );
  }

  static int _byCategoryThenRank(WalletSnapshot a, WalletSnapshot b) {
    final byCategory =
        _categoryOrder(a.category).compareTo(_categoryOrder(b.category));
    if (byCategory != 0) return byCategory;
    return a.priorityRank.compareTo(b.priorityRank);
  }

  static int _categoryOrder(WalletCategory c) => switch (c) {
        WalletCategory.financialSafety => 0,
        WalletCategory.lifeSafety => 1,
        WalletCategory.savingGoal => 2,
      };

  /// want = min(monthlyContribution, max(0, targetAmount − current)).
  static int _want(WalletSnapshot w) {
    final gap = w.targetAmount - w.current;
    final room = gap < 0 ? 0 : gap;
    return w.monthlyContribution < room ? w.monthlyContribution : room;
  }

  static int _projectedMonths(WalletSnapshot w) {
    final remaining = w.targetAmount - w.current;
    if (remaining <= 0) return 0;
    final mc = w.monthlyContribution < 1 ? 1 : w.monthlyContribution;
    return (remaining / mc).ceil();
  }
}
