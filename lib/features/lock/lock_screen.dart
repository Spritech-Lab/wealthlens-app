/// The lock overlay + lifecycle gate that enforces app lock.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wealthlens/app/lock_controller.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

/// Re-lock after the app has been backgrounded at least this long.
const lockGraceDuration = Duration(minutes: 2);

/// Wraps the app: shows [LockScreen] when locked, and re-locks on resume after
/// the app has been backgrounded past [lockGraceDuration].
class LockGate extends ConsumerStatefulWidget {
  /// Creates a [LockGate].
  const LockGate({required this.child, super.key});

  /// The app content shown when unlocked.
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      if (since != null &&
          DateTime.now().difference(since) >= lockGraceDuration) {
        ref.read(lockControllerProvider.notifier).lock();
      }
      _backgroundedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(lockControllerProvider).locked;
    return Stack(
      children: [
        widget.child,
        if (locked) const LockScreen(),
      ],
    );
  }
}

/// Full-screen lock prompt: tries biometric on show, with a PIN fallback.
class LockScreen extends ConsumerStatefulWidget {
  /// Creates a [LockScreen].
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pin = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final auth = LocalAuthentication();
      if (await auth.isDeviceSupported()) {
        final ok = await auth.authenticate(
          localizedReason: '解鎖 WealthLens',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        if (ok && mounted) {
          ref.read(lockControllerProvider.notifier).unlock();
          return;
        }
      }
    } on Object {
      // No biometric / cancelled — fall back to PIN entry.
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _submitPin() async {
    final ok =
        await ref.read(lockControllerProvider.notifier).verifyPin(_pin.text);
    if (!mounted) return;
    if (ok) {
      ref.read(lockControllerProvider.notifier).unlock();
    } else {
      setState(() => _error = 'PIN 不正確');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_outline, size: 56, color: context.semantic.info),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '已鎖定',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '用生物辨識或 PIN 解鎖',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) => _submitPin(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _submitPin,
                child: const Text('解鎖'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: _checking ? null : _tryBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('用生物辨識'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
