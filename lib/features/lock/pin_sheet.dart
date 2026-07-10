/// PIN entry sheets — set a new PIN, or verify the existing one.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/lock_controller.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

const _minLen = 4;
const _maxLen = 6;

InputDecoration _pinDecoration(String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      counterText: '',
    );

/// Prompts the user to set a new PIN (enter + confirm). Returns the PIN, or
/// null if cancelled.
Future<String?> showSetPinSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SetPinSheet(),
    );

/// Verifies the stored PIN. Returns true on success, null/false otherwise.
Future<bool?> showVerifyPinSheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _VerifyPinSheet(),
    );

class _SetPinSheet extends StatefulWidget {
  const _SetPinSheet();

  @override
  State<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<_SetPinSheet> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pin.text;
    if (pin.length < _minLen) {
      setState(() => _error = 'PIN 至少 $_minLen 位數');
      return;
    }
    if (pin != _confirm.text) {
      setState(() => _error = '兩次輸入不一致');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: '設定解鎖 PIN',
      children: [
        TextField(
          controller: _pin,
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          maxLength: _maxLen,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _pinDecoration('輸入 $_minLen–$_maxLen 位數'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _confirm,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: _maxLen,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _pinDecoration('再次輸入'),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _submit, child: const Text('設定')),
        ),
      ],
    );
  }
}

class _VerifyPinSheet extends ConsumerStatefulWidget {
  const _VerifyPinSheet();

  @override
  ConsumerState<_VerifyPinSheet> createState() => _VerifyPinSheetState();
}

class _VerifyPinSheetState extends ConsumerState<_VerifyPinSheet> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(lockControllerProvider.notifier).verifyPin(
          _pin.text,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'PIN 不正確');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: '輸入 PIN 確認',
      children: [
        TextField(
          controller: _pin,
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          maxLength: _maxLen,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _pinDecoration('PIN'),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _submit, child: const Text('確認')),
        ),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}
