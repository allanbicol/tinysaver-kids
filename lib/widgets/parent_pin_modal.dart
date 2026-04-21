import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class ParentPinModal extends ConsumerStatefulWidget {
  final VoidCallback onApproved;
  final String title;
  final String subtitle;

  const ParentPinModal({
    super.key,
    required this.onApproved,
    this.title = 'Parent Approval',
    this.subtitle = 'Enter your 4-digit PIN to approve',
  });

  @override
  ConsumerState<ParentPinModal> createState() => _ParentPinModalState();
}

class _ParentPinModalState extends ConsumerState<ParentPinModal> {
  final _pinController = TextEditingController();
  bool _hasError = false;
  bool _isLoading = false;
  int _attempts = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin(String pin) async {
    if (pin.length != 4) return;
    setState(() { _isLoading = true; _hasError = false; });

    final user = ref.read(userStreamProvider).valueOrNull;
    if (user == null) { setState(() => _isLoading = false); return; }

    await Future.delayed(const Duration(milliseconds: 250));

    if (pin == user.pinCode) {
      setState(() => _isLoading = false);
      widget.onApproved();
    } else {
      _attempts++;
      setState(() { _isLoading = false; _hasError = true; });
      _pinController.clear();
      if (_attempts >= 5 && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Let's take a breather — try again later 💛"),
          backgroundColor: AppColors.onSurfaceVariant,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 70,
      textStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
        fontSize: 28, color: AppColors.onSurface, fontWeight: FontWeight.w800),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(25),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.4 * 255),
          width: 1.5,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.tertiaryContainer,
        border: Border.all(color: AppColors.tertiaryDark, width: 1.5),
      ),
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92 * 255),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15 * 255),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 36,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Lock icon
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasError
                    ? AppColors.tertiaryContainer
                    : AppColors.primaryContainer,
              ),
              child: Icon(
                _hasError ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                color: _hasError ? AppColors.tertiaryDark : AppColors.primaryDark,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            Text(widget.title,
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              _hasError ? 'Hmm, not quite. Try again 💛' : widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _hasError ? AppColors.tertiaryDark : AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              )
            else
              Pinput(
                controller: _pinController,
                length: 4,
                obscureText: true,
                obscuringCharacter: '●',
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                errorPinTheme: errorPinTheme,
                autofocus: true,
                onCompleted: _verifyPin,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
              ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
