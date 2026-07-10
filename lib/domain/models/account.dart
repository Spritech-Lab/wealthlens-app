/// Account domain model — pure Dart, no Flutter imports.
library;

import 'package:meta/meta.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/wallet.dart';

/// An account represents *where* money is physically held.
///
/// Examples: DAWHO savings account, Fubon brokerage, Binance exchange.
///
/// An account acts as the aggregate root for its [wallets]. The derived
/// [balance] always equals Σ `wallet.current` (INV-1). All wallets in
/// [wallets] must have `accountRef == id` (INV-2).
@immutable
class Account {
  /// Creates an immutable [Account].
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.isInflowHub,
    required this.wallets,
    this.institution,
  });

  /// Unique identifier.
  final String id;

  /// User-visible account name.
  final String name;

  /// Physical account type.
  final AccountType type;

  /// Whether this is the primary income-receiving account (at most one).
  final bool isInflowHub;

  /// Optional financial institution name (e.g. "永豐", "富邦").
  final String? institution;

  /// Wallets belonging to this account (aggregate).
  ///
  /// All wallets MUST satisfy `wallet.accountRef == this.id` (INV-2).
  final List<Wallet> wallets;

  // ── Derived values (getters, never stored) ──────────────────────────────

  /// Account balance = Σ `wallet.current` for all wallets (INV-1).
  int get balance => wallets.fold(0, (sum, w) => sum + w.current);

  // ── Immutable helpers ────────────────────────────────────────────────────

  /// Returns a copy of this account with the given fields replaced.
  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    bool? isInflowHub,
    List<Wallet>? wallets,
    Object? institution = _sentinel,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isInflowHub: isInflowHub ?? this.isInflowHub,
      wallets: wallets ?? this.wallets,
      institution: institution == _sentinel
          ? this.institution
          : institution as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Account) return false;
    if (other.id != id ||
        other.name != name ||
        other.type != type ||
        other.isInflowHub != isInflowHub ||
        other.institution != institution ||
        other.wallets.length != wallets.length) {
      return false;
    }
    for (var i = 0; i < wallets.length; i++) {
      if (wallets[i] != other.wallets[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        isInflowHub,
        institution,
        Object.hashAll(wallets),
      );
}

// Sentinel value for nullable copyWith parameters.
const Object _sentinel = Object();
