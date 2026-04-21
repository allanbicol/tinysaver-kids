import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_container.dart';
import '../widgets/currency_symbol.dart';

/// Prompts the parent for how many coins to add.
/// Returns the amount entered, or null if cancelled.
Future<int?> showAddCoinAmountDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _AddCoinDialog(),
  );
}

class _AddCoinDialog extends StatefulWidget {
  const _AddCoinDialog();

  @override
  State<_AddCoinDialog> createState() => _AddCoinDialogState();
}

class _AddCoinDialogState extends State<_AddCoinDialog> {
  int _amount = 1;
  final _ctrl = TextEditingController(text: '1');

  static const _presets = [1, 5, 10, 20, 50];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setAmount(int v) {
    final capped = v.clamp(1, 9999);
    setState(() {
      _amount = capped;
      _ctrl.text = '$capped';
      _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ctrl.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_rounded,
                    color: AppColors.primaryDark, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Coins',
                        style: Theme.of(context).textTheme.headlineMedium),
                      Text('How many coins to add?',
                        style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Big amount display with +/- steppers
            ChunkyContainer(
              color: AppColors.primaryContainer,
              shelfColor: AppColors.primaryDark,
              shelfHeight: 5,
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  _stepperButton(Icons.remove_rounded,
                      _amount > 1 ? () => _setAmount(_amount - 1) : null),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CurrencySymbol(
                          size: 30, color: AppColors.primaryDark),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 36),
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: (s) {
                              final v = int.tryParse(s);
                              if (v != null && v > 0) {
                                setState(() => _amount = v.clamp(1, 9999));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _stepperButton(Icons.add_rounded,
                      _amount < 9999 ? () => _setAmount(_amount + 1) : null),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quick presets
            Text('Quick pick',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _presets.map((p) {
                final selected = p == _amount;
                return GestureDetector(
                  onTap: () => _setAmount(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+$p',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: selected ? Colors.white : AppColors.onSurface,
                            fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        CurrencySymbol(
                          size: 13,
                          color: selected ? Colors.white : AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ChunkyButton(
                    onTap: () => Navigator.pop(context, _amount),
                    gradient: AppColors.primaryGradient,
                    shelfColor: AppColors.primaryDark,
                    shelfHeight: 5,
                    radius: 48,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('Continue →',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryDark : AppColors.outline,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
