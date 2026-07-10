// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anchor_unit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$anchorUnitControllerHash() =>
    r'48838a887cde998316636fab7f2216fcd7c75c71';

/// Holds the user-selected [AnchorUnit] for amount display.
///
/// Defaults to [AnchorUnit.full] (no anchoring). The active value is mirrored
/// into [defaultAnchorUnit] so plain `formatTwd` calls reflect the setting.
///
/// Copied from [AnchorUnitController].
@ProviderFor(AnchorUnitController)
final anchorUnitControllerProvider =
    NotifierProvider<AnchorUnitController, AnchorUnit>.internal(
      AnchorUnitController.new,
      name: r'anchorUnitControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anchorUnitControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnchorUnitController = Notifier<AnchorUnit>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
