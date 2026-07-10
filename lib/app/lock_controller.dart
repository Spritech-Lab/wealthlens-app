/// App-lock state: enable/disable, PIN, and locked/unlocked.
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lock_controller.g.dart';

/// Immutable app-lock state.
class LockState {
  /// Creates a [LockState].
  const LockState({required this.enabled, required this.locked});

  /// Whether app lock is turned on.
  final bool enabled;

  /// Whether the app is currently locked (awaiting auth).
  final bool locked;

  /// Returns a copy with the given fields replaced.
  LockState copyWith({bool? enabled, bool? locked}) => LockState(
        enabled: enabled ?? this.enabled,
        locked: locked ?? this.locked,
      );
}

/// Holds and persists the app-lock setting + PIN.
///
/// The PIN is stored in [FlutterSecureStorage] (Keychain / Keystore-backed).
/// When lock is enabled the app starts locked; a re-lock is triggered by the
/// lifecycle gate after the app has been backgrounded past the threshold.
@Riverpod(keepAlive: true)
class LockController extends _$LockController {
  static const _enabledKey = 'lock_enabled';
  static const _pinKey = 'lock_pin';
  static const _storage = FlutterSecureStorage();

  @override
  LockState build() {
    unawaited(_hydrate());
    return const LockState(enabled: false, locked: false);
  }

  Future<void> _hydrate() async {
    final enabled = (await _storage.read(key: _enabledKey)) == 'true';
    state = LockState(enabled: enabled, locked: enabled);
  }

  /// Enables app lock and stores [pin].
  Future<void> enable(String pin) async {
    await _storage.write(key: _enabledKey, value: 'true');
    await _storage.write(key: _pinKey, value: pin);
    state = const LockState(enabled: true, locked: false);
  }

  /// Disables app lock and clears the PIN. Callers must verify first.
  Future<void> disable() async {
    await _storage.write(key: _enabledKey, value: 'false');
    await _storage.delete(key: _pinKey);
    state = const LockState(enabled: false, locked: false);
  }

  /// True when [pin] matches the stored PIN.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == pin;
  }

  /// Locks the app (no-op when disabled).
  void lock() {
    if (state.enabled) state = state.copyWith(locked: true);
  }

  /// Unlocks the app.
  void unlock() => state = state.copyWith(locked: false);
}
