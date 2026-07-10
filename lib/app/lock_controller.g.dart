// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lockControllerHash() => r'6f8b60b07a4f53cbbe21ea9052760d8e1be85d94';

/// Holds and persists the app-lock setting + PIN.
///
/// The PIN is stored in [FlutterSecureStorage] (Keychain / Keystore-backed).
/// When lock is enabled the app starts locked; a re-lock is triggered by the
/// lifecycle gate after the app has been backgrounded past the threshold.
///
/// Copied from [LockController].
@ProviderFor(LockController)
final lockControllerProvider =
    NotifierProvider<LockController, LockState>.internal(
      LockController.new,
      name: r'lockControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$lockControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LockController = Notifier<LockState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
