/// Transaction domain model — pure Dart, no Flutter imports.
library;

import 'package:meta/meta.dart';

/// A single financial event (buy, sell, dividend, transfer, etc.).
///
/// `CostBasisCalculator` reads buy transactions to maintain
/// `Holding.avgCost` via moving weighted average (INV-8).
@immutable
class Transaction {
  /// Creates an immutable [Transaction].
  const Transaction({
    required this.id,
    required this.date,
    required this.kind,
    required this.ref,
    required this.amount,
    this.quantity,
    this.price,
    this.fee,
    this.reason,
    this.note,
  });

  /// Unique identifier.
  final String id;

  /// Date when the transaction occurred.
  final DateTime date;

  /// Transaction kind string (e.g. `'buy'`, `'sell'`, `'dividend'`).
  final String kind;

  /// Reference to the related entity (holding id, wallet id, etc.).
  final String ref;

  /// Transaction amount in integer cents (分).
  final int amount;

  /// For investment transactions: number of units bought or sold.
  final double? quantity;

  /// For investment transactions: price per unit at time of transaction (TWD).
  final double? price;

  /// Optional transaction fee in integer cents (分).
  final int? fee;

  /// Optional reason code or label.
  final String? reason;

  /// Optional free-text note.
  final String? note;

  // ── Immutable helpers ────────────────────────────────────────────────────

  /// Returns a copy of this transaction with the given fields replaced.
  Transaction copyWith({
    String? id,
    DateTime? date,
    String? kind,
    String? ref,
    int? amount,
    Object? quantity = _sentinel,
    Object? price = _sentinel,
    Object? fee = _sentinel,
    Object? reason = _sentinel,
    Object? note = _sentinel,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      ref: ref ?? this.ref,
      amount: amount ?? this.amount,
      quantity: quantity == _sentinel ? this.quantity : quantity as double?,
      price: price == _sentinel ? this.price : price as double?,
      fee: fee == _sentinel ? this.fee : fee as int?,
      reason: reason == _sentinel ? this.reason : reason as String?,
      note: note == _sentinel ? this.note : note as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.date == date &&
        other.kind == kind &&
        other.ref == ref &&
        other.amount == amount &&
        other.quantity == quantity &&
        other.price == price &&
        other.fee == fee &&
        other.reason == reason &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(
        id,
        date,
        kind,
        ref,
        amount,
        quantity,
        price,
        fee,
        reason,
        note,
      );
}

// Sentinel value for nullable copyWith parameters.
const Object _sentinel = Object();
