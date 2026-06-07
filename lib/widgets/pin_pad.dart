import 'package:flutter/material.dart';

/// Shared numeric PIN pad widget used by both unlock and setup screens.
/// iOS-style keypad with 0-9 digits and backspace.
class PinPad extends StatelessWidget {
  final void Function(String)? onDigit;
  final VoidCallback? onDelete;

  const PinPad({super.key, this.onDigit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final disabled = onDigit == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 0; col < 3; col++)
                  _pinButton(context, row * 3 + col + 1, disabled),
              ],
            ),
        ],
      ),
    );
  }

  Widget _pinButton(BuildContext context, int num, bool disabled) {
    final colorScheme = Theme.of(context).colorScheme;

    if (num == 10) {
      return const SizedBox(width: 80, height: 64);
    }
    if (num == 11) {
      return _KeyButton(
        child: Text(
          '0',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: disabled
                ? colorScheme.onSurface.withValues(alpha: 0.2)
                : colorScheme.onSurface,
          ),
        ),
        onTap: disabled ? null : () => onDigit?.call('0'),
      );
    }
    if (num == 12) {
      return _KeyButton(
        child: Icon(
          Icons.backspace_outlined,
          size: 26,
          color: disabled
              ? colorScheme.onSurface.withValues(alpha: 0.2)
              : colorScheme.onSurface,
        ),
        onTap: disabled ? null : onDelete,
      );
    }
    return _KeyButton(
      child: Text(
        '$num',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: disabled
              ? colorScheme.onSurface.withValues(alpha: 0.2)
              : colorScheme.onSurface,
        ),
      ),
      onTap: disabled ? null : () => onDigit?.call('$num'),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _KeyButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 64,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.1),
          highlightColor: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.05),
          child: Center(child: child),
        ),
      ),
    );
  }
}
