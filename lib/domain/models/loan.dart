/// Loan domain model — pure Dart, no Flutter imports.
library;

import 'package:meta/meta.dart';
import 'package:wealthlens/domain/models/enums.dart';

/// A loan represents a labelled fixed monthly outflow.
///
/// Loans are NOT modelled as negative assets or liabilities. They are
/// treated identically to fixed living expenses (§8: "有標籤的固定月支出").
/// No interest rate, no remaining balance, no net-worth calculation.
@immutable
class Loan {
  /// Creates an immutable [Loan].
  const Loan({
    required this.id,
    required this.type,
    required this.monthlyPayment,
    this.name,
    this.terms,
  });

  /// Unique identifier.
  final String id;

  /// Category of loan (legacy seed rows; new items use [name] instead).
  final LoanType type;

  /// User-defined name for the fixed payment (e.g. 房租、保險). Null on legacy
  /// seed rows, which fall back to the type label for display.
  final String? name;

  /// Monthly payment amount in integer cents (分).
  final int monthlyPayment;

  /// Total number of payment terms (months). Nullable.
  final int? terms;

  // ── Immutable helpers ────────────────────────────────────────────────────

  /// Returns a copy of this loan with the given fields replaced.
  Loan copyWith({
    String? id,
    LoanType? type,
    int? monthlyPayment,
    Object? name = _sentinel,
    Object? terms = _sentinel,
  }) {
    return Loan(
      id: id ?? this.id,
      type: type ?? this.type,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      name: name == _sentinel ? this.name : name as String?,
      terms: terms == _sentinel ? this.terms : terms as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Loan &&
        other.id == id &&
        other.type == type &&
        other.name == name &&
        other.monthlyPayment == monthlyPayment &&
        other.terms == terms;
  }

  @override
  int get hashCode => Object.hash(id, type, name, monthlyPayment, terms);
}

// Sentinel value for nullable copyWith parameters.
const Object _sentinel = Object();
