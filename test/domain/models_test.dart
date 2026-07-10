// Domain model unit tests — covers INV-1, INV-2, derived values,
// copyWith / == behaviour.
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/fixed_cost.dart';
import 'package:wealthlens/domain/models/holding.dart';
import 'package:wealthlens/domain/models/home_alerts.dart';
import 'package:wealthlens/domain/models/income.dart';
import 'package:wealthlens/domain/models/loan.dart';
import 'package:wealthlens/domain/models/task.dart';
import 'package:wealthlens/domain/models/transaction.dart';
import 'package:wealthlens/domain/models/wallet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Wallet _wallet({
  String id = 'w1',
  String accountRef = 'a1',
  int current = 100000, // 1,000.00 TWD in cents
  int targetAmount = 1000000,
  int monthlyContribution = 50000,
  String? period,
}) =>
    Wallet(
      id: id,
      name: 'Test Wallet',
      accountRef: accountRef,
      category: WalletCategory.savingGoal,
      targetAmount: targetAmount,
      current: current,
      monthlyContribution: monthlyContribution,
      priorityRank: 3,
      isPrimary: false,
      period: period,
    );

Account _account({List<Wallet>? wallets}) => Account(
      id: 'a1',
      name: 'DAWHO',
      type: AccountType.cash,
      isInflowHub: true,
      wallets: wallets ?? const [],
    );

// ─────────────────────────────────────────────────────────────────────────────
// INV-1 : Account.balance == Σ wallet.current
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('INV-1 對帳一致', () {
    test('account with no wallets has balance 0', () {
      final account = _account(wallets: const []);
      expect(account.balance, 0);
    });

    test('balance equals sum of wallet.current', () {
      final w1 = _wallet(current: 300000);
      final w2 = _wallet(id: 'w2', current: 200000);
      final w3 = _wallet(id: 'w3', current: 500000);
      final account = _account(wallets: [w1, w2, w3]);

      expect(account.balance, 1000000);
      expect(account.balance, w1.current + w2.current + w3.current);
    });

    test(
        'balance updates correctly when wallet.current changes via copyWith',
        () {
      final w1 = _wallet();
      final w2 = _wallet(id: 'w2', current: 200000);
      final accountV1 = _account(wallets: [w1, w2]);
      expect(accountV1.balance, 300000);

      final w1Updated = w1.copyWith(current: 150000);
      final accountV2 = accountV1.copyWith(wallets: [w1Updated, w2]);
      expect(accountV2.balance, 350000);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // INV-2 : Wallet accountRef 必填且固定屬於一個帳戶
  // ─────────────────────────────────────────────────────────────────────────

  group('INV-2 錢包歸屬唯一', () {
    test('wallet accountRef is non-null (required field)', () {
      final w = _wallet();
      expect(w.accountRef, isNotNull);
      expect(w.accountRef, 'a1');
    });

    test('all wallets in account carry matching accountRef', () {
      final w1 = _wallet();
      final w2 = _wallet(id: 'w2');
      final account = _account(wallets: [w1, w2]);

      for (final w in account.wallets) {
        expect(
          w.accountRef,
          account.id,
          reason: 'wallet ${w.id} accountRef must match account id',
        );
      }
    });

    test('a correctly-scoped aggregate has all matching accountRefs', () {
      // INV-2 hard enforcement (reject foreign wallets) lives at the Drift
      // repository layer (FK + non-null accountRef). At the domain level we
      // verify a well-formed aggregate keeps every wallet under its account.
      final account = _account(wallets: [_wallet(), _wallet(id: 'w2')]);
      final mismatch =
          account.wallets.where((x) => x.accountRef != account.id);
      expect(mismatch, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Wallet derived values
  // ─────────────────────────────────────────────────────────────────────────

  group('Wallet derived values', () {
    test('progress = current / targetAmount', () {
      final w = _wallet(current: 250000);
      expect(w.progress, closeTo(0.25, 1e-9));
    });

    test('progress is 0 when targetAmount == 0', () {
      final w = _wallet(current: 0, targetAmount: 0);
      expect(w.progress, 0);
    });

    test('monthlyRequired when period is set (18 months out)', () {
      // remaining = 900000, 2026-01 → 2027-07 = 18 months → 50000
      final w = _wallet(period: '2027-07');
      expect(w.monthlyRequiredAsOf(DateTime(2026)), 50000);
    });

    test('monthlyRequired rounds up (ceil)', () {
      // remaining = 100001, 2026-01 → 2026-04 = 3 months → ceil/3 = 33334
      final w = _wallet(
        current: 0,
        targetAmount: 100001,
        monthlyContribution: 99999,
        period: '2026-04',
      );
      expect(w.monthlyRequiredAsOf(DateTime(2026)), 33334);
    });

    test('monthlyRequired is null when period is null', () {
      final w = _wallet();
      expect(w.monthlyRequiredAsOf(DateTime(2026)), isNull);
    });

    test('monthlyRequired is 0 when already at target', () {
      final w = _wallet(current: 1000000, period: '2027-01');
      expect(w.monthlyRequiredAsOf(DateTime(2026)), 0);
    });

    test('monthlyRequired returns full remaining when deadline is past', () {
      // remaining = 900000, deadline 2025-12 already gone as of 2026-01
      final w = _wallet(period: '2025-12');
      expect(w.monthlyRequiredAsOf(DateTime(2026)), 900000);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Holding derived values (ETF + forex)
  // ─────────────────────────────────────────────────────────────────────────

  group('Holding derived values', () {
    test('currentValue = quantity * lastPrice', () {
      const h = Holding(
        id: 'h1',
        accountRef: 'a1',
        kind: HoldingKind.etf,
        symbol: '0050',
        quantity: 100,
        avgCost: 140,
        lastPrice: 155,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );
      expect(h.currentValue, closeTo(15500, 1e-9));
    });

    test('unrealizedPnL = quantity * (lastPrice - avgCost)', () {
      const h = Holding(
        id: 'h1',
        accountRef: 'a1',
        kind: HoldingKind.etf,
        symbol: '0050',
        quantity: 100,
        avgCost: 140,
        lastPrice: 155,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );
      expect(h.unrealizedPnL, closeTo(1500, 1e-9));
    });

    test('forex negative exchange-rate loss (浮虧)', () {
      // quantity=1000 USD, avgCost=32 TWD/USD, lastPrice=30.5
      // unrealizedPnL = 1000 * (30.5 - 32) = -1500
      const forex = Holding(
        id: 'fx1',
        accountRef: 'a1',
        kind: HoldingKind.forex,
        symbol: 'USD',
        quantity: 1000,
        avgCost: 32,
        lastPrice: 30.5,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );
      expect(forex.currentValue, closeTo(30500, 1e-9));
      expect(forex.unrealizedPnL, closeTo(-1500, 1e-9));
    });

    test('forex gain scenario', () {
      const forex = Holding(
        id: 'fx2',
        accountRef: 'a1',
        kind: HoldingKind.forex,
        symbol: 'JPY',
        quantity: 50000,
        avgCost: 0.21,
        lastPrice: 0.225,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );
      expect(forex.currentValue, closeTo(11250, 1e-6));
      expect(forex.unrealizedPnL, closeTo(750, 1e-6));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // copyWith / == for Wallet
  // ─────────────────────────────────────────────────────────────────────────

  group('Wallet copyWith / ==', () {
    test('identical wallets are equal', () {
      final w1 = _wallet();
      final w2 = _wallet();
      expect(w1, w2);
    });

    test('copyWith changes only the specified field', () {
      final original = _wallet();
      final updated = original.copyWith(current: 200000);
      expect(updated.current, 200000);
      expect(updated.id, original.id);
      expect(updated.accountRef, original.accountRef);
    });

    test('copyWith can clear period (set to null)', () {
      final w = _wallet(period: '2027-01');
      final noperiod = w.copyWith(period: null);
      expect(noperiod.period, isNull);
    });

    test('different id → not equal', () {
      final w1 = _wallet();
      final w2 = _wallet(id: 'w2');
      expect(w1, isNot(w2));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // copyWith / == for Account
  // ─────────────────────────────────────────────────────────────────────────

  group('Account copyWith / ==', () {
    test('identical accounts are equal', () {
      final a1 = _account();
      final a2 = _account();
      expect(a1, a2);
    });

    test('copyWith updates wallets', () {
      final w = _wallet();
      final a = _account(wallets: const []);
      final updated = a.copyWith(wallets: [w]);
      expect(updated.wallets.length, 1);
      expect(a.wallets, isEmpty);
    });

    test('copyWith can set institution to null', () {
      const a = Account(
        id: 'a1',
        name: 'Test',
        type: AccountType.cash,
        isInflowHub: false,
        wallets: [],
        institution: 'DAWHO',
      );
      final updated = a.copyWith(institution: null);
      expect(updated.institution, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Holding copyWith / ==
  // ─────────────────────────────────────────────────────────────────────────

  group('Holding copyWith / ==', () {
    const baseHolding = Holding(
      id: 'h1',
      accountRef: 'a1',
      kind: HoldingKind.crypto,
      symbol: 'BTC',
      quantity: 0.5,
      avgCost: 2000000,
      lastPrice: 2100000,
      isCapitalGuaranteed: false,
      liquidity: 'high',
    );

    test('identical holdings are equal', () {
      expect(baseHolding, baseHolding);
    });

    test('copyWith changes lastPrice', () {
      final updated = baseHolding.copyWith(lastPrice: 1900000);
      expect(updated.lastPrice, 1900000);
      expect(
        updated.unrealizedPnL,
        closeTo(0.5 * (1900000 - 2000000), 1e-6),
      );
    });

    test('different symbol → not equal', () {
      final h2 = baseHolding.copyWith(symbol: 'ETH');
      expect(baseHolding, isNot(h2));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Income / Loan / Task / Transaction / FixedCost / HomeAlerts basic tests
  // ─────────────────────────────────────────────────────────────────────────

  group('Income', () {
    test('defaults quickEntryOnHome to false', () {
      const inc = Income(
        id: 'i1',
        name: 'Salary',
        amount: 5000000,
        type: IncomeType.fixed,
      );
      expect(inc.quickEntryOnHome, isFalse);
    });

    test('copyWith updates amount', () {
      const inc = Income(
        id: 'i1',
        name: 'Salary',
        amount: 5000000,
        type: IncomeType.fixed,
      );
      expect(inc.copyWith(amount: 6000000).amount, 6000000);
    });

    test('equality', () {
      const a =
          Income(id: 'i1', name: 'X', amount: 1000, type: IncomeType.fixed);
      const b =
          Income(id: 'i1', name: 'X', amount: 1000, type: IncomeType.fixed);
      expect(a, b);
    });
  });

  group('Loan', () {
    test('terms nullable', () {
      const loan = Loan(
        id: 'l1',
        type: LoanType.mortgage,
        monthlyPayment: 30000,
      );
      expect(loan.terms, isNull);
    });

    test('copyWith nullifies terms', () {
      const a = Loan(
        id: 'l1',
        type: LoanType.car,
        monthlyPayment: 5000,
        terms: 60,
      );
      final b = a.copyWith(terms: null);
      expect(b.terms, isNull);
      expect(a, isNot(b));
    });
  });

  group('Task', () {
    test('isDone toggles via copyWith', () {
      const t = Task(
        id: 't1',
        month: '2026-06',
        title: '補備用金',
        amount: 5000,
        kind: 'transfer',
        auto: true,
        isDone: false,
        sourceRef: 'w1',
      );
      expect(t.copyWith(isDone: true).isDone, isTrue);
    });
  });

  group('Transaction', () {
    test('optional fields are nullable', () {
      final tx = Transaction(
        id: 'tx1',
        date: DateTime(2026, 6),
        kind: 'buy',
        ref: 'h1',
        amount: 100000,
      );
      expect(tx.quantity, isNull);
      expect(tx.fee, isNull);
      expect(tx.note, isNull);
    });

    test('equality with all fields', () {
      final date = DateTime(2026, 6);
      final a = Transaction(
        id: 'tx1',
        date: date,
        kind: 'buy',
        ref: 'h1',
        amount: 100000,
        quantity: 10,
        price: 10000,
        fee: 50,
      );
      final b = Transaction(
        id: 'tx1',
        date: date,
        kind: 'buy',
        ref: 'h1',
        amount: 100000,
        quantity: 10,
        price: 10000,
        fee: 50,
      );
      expect(a, b);
    });
  });

  group('FixedCost', () {
    test('copyWith', () {
      const fc = FixedCost(livingExpense: 3000000);
      expect(fc.copyWith(livingExpense: 3500000).livingExpense, 3500000);
    });

    test('equality', () {
      expect(
        const FixedCost(livingExpense: 1000),
        const FixedCost(livingExpense: 1000),
      );
    });
  });

  group('HomeAlerts', () {
    test('default values match spec', () {
      const ha = HomeAlerts();
      expect(ha.lowLevel, isFalse);
      expect(ha.payday, isTrue);
      expect(ha.goalDueSoon, isTrue);
    });

    test('copyWith toggles lowLevel', () {
      const ha = HomeAlerts();
      expect(ha.copyWith(lowLevel: true).lowLevel, isTrue);
    });

    test('equality', () {
      expect(const HomeAlerts(), const HomeAlerts());
      expect(const HomeAlerts(lowLevel: true), isNot(const HomeAlerts()));
    });
  });
}
