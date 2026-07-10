/// Wallet domain model — pure Dart, no Flutter imports.
library;

import 'package:meta/meta.dart';
import 'package:wealthlens/domain/models/enums.dart';

/// A wallet represents a *purpose* for money within one account (INV-2).
///
/// Wallets are the logical layer: they define the goal, track progress, and
/// determine the category-driven behaviour (safety vs. saving goal).
@immutable
class Wallet {
  /// Creates an immutable [Wallet].
  const Wallet({
    required this.id,
    required this.name,
    required this.accountRef,
    required this.category,
    required this.targetAmount,
    required this.current,
    required this.monthlyContribution,
    required this.priorityRank,
    required this.isPrimary,
    this.period,
  });

  /// Unique identifier.
  final String id;

  /// User-visible name (user may rename).
  final String name;

  /// The account this wallet belongs to.
  ///
  /// Required and immutable after creation — every wallet belongs to exactly
  /// one account (INV-2). Never null.
  final String accountRef;

  /// Governs UI behaviour and allocation priority.
  final WalletCategory category;

  /// Target amount in integer cents (分).
  final int targetAmount;

  /// Current saved amount in integer cents (分).
  final int current;

  /// User-defined monthly top-up in integer cents (分).
  final int monthlyContribution;

  /// Priority rank for allocation order. Safety wallets lock to 1 / 2.
  final int priorityRank;

  /// Whether this wallet is the single primary goal shown on home.
  final bool isPrimary;

  /// Optional deadline as "YYYY-MM". Non-null only when the wallet has a
  /// deadline; null means open-ended.
  final String? period;

  // ── Derived values (getters, never stored) ──────────────────────────────

  /// Monthly amount required to reach [targetAmount] by the [period] deadline,
  /// evaluated as of [now] (injected to keep the domain pure).
  ///
  /// Returns `null` when there is no deadline, `0` when already met, and the
  /// full remaining amount when the deadline is the current month or past.
  int? monthlyRequiredAsOf(DateTime now) {
    if (period == null) return null;
    final remaining = targetAmount - current;
    if (remaining <= 0) return 0;
    final months = _monthsRemaining(now);
    if (months <= 0) return remaining;
    return (remaining / months).ceil();
  }

  int _monthsRemaining(DateTime now) {
    final parts = period!.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return (year * 12 + month) - (now.year * 12 + now.month);
  }

  /// Progress ratio: `current / targetAmount`.
  ///
  /// Returns `0` when [targetAmount] is zero to avoid division by zero.
  double get progress {
    if (targetAmount == 0) return 0;
    return current / targetAmount;
  }

  // ── Immutable helpers ────────────────────────────────────────────────────

  /// Returns a copy of this wallet with the given fields replaced.
  Wallet copyWith({
    String? id,
    String? name,
    String? accountRef,
    WalletCategory? category,
    int? targetAmount,
    int? current,
    int? monthlyContribution,
    int? priorityRank,
    bool? isPrimary,
    Object? period = _sentinel,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      accountRef: accountRef ?? this.accountRef,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      current: current ?? this.current,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      priorityRank: priorityRank ?? this.priorityRank,
      isPrimary: isPrimary ?? this.isPrimary,
      period: period == _sentinel ? this.period : period as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet &&
        other.id == id &&
        other.name == name &&
        other.accountRef == accountRef &&
        other.category == category &&
        other.targetAmount == targetAmount &&
        other.current == current &&
        other.monthlyContribution == monthlyContribution &&
        other.priorityRank == priorityRank &&
        other.isPrimary == isPrimary &&
        other.period == period;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        accountRef,
        category,
        targetAmount,
        current,
        monthlyContribution,
        priorityRank,
        isPrimary,
        period,
      );
}

// Sentinel value for nullable copyWith parameters.
const Object _sentinel = Object();
