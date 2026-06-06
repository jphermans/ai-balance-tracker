import 'package:flutter/material.dart';
import '../services/pin_service.dart';

/// Bottom sheet dialog for setting up a new PIN.
/// Step 1: enter PIN → Step 2: confirm PIN.
class PinSetupDialog extends StatefulWidget {
  final VoidCallback onPinSet;

  const PinSetupDialog({super.key, required this.onPinSet});

  static Future<void> show(BuildContext context, {required VoidCallback onPinSet}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PinSetupDialog(onPinSet: onPinSet),
    );
  }

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error;
  bool _saving = false;

  static const _pinLength = 4;

  void _onDigit(String digit) {
    setState(() {
      _error = null;
      if (!_isConfirming) {
        if (_pin.length < _pinLength) _pin += digit;
        if (_pin.length == _pinLength) {
          // Short delay then switch to confirm
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isConfirming = true);
          });
        }
      } else {
        if (_confirmPin.length < _pinLength) _confirmPin += digit;
        if (_confirmPin.length == _pinLength) {
          _verify();
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _verify() async {
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      return;
    }

    setState(() => _saving = true);
    await PinService.setPin(_pin);
    widget.onPinSet();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pin = _isConfirming ? _confirmPin : _pin;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                _isConfirming ? 'Confirm PIN' : 'Set PIN',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isConfirming
                    ? 'Enter your PIN again to confirm'
                    : 'Enter a 4-digit PIN to secure the app',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < pin.length;
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: filled
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),

              // Error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Pin pad
              _PinPad(
                onDigit: _saving ? null : _onDigit,
                onDelete: _saving ? null : _onDelete,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final void Function(String)? onDigit;
  final VoidCallback? onDelete;

  const _PinPad({this.onDigit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final disabled = onDigit == null;
    final disabledColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.3);
    return Column(
      children: [
        for (var row = 0; row < 4; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var col = 0; col < 3; col++)
                _pinButton(row * 3 + col + 1, disabled, disabledColor),
            ],
          ),
      ],
    );
  }

  Widget _pinButton(int num, bool disabled, Color disabledColor) {
    if (num == 10) {
      return const SizedBox(width: 72, height: 56);
    }
    if (num == 11) {
      return _KeyButton(
        child: Text('0',
            style: TextStyle(
                fontSize: 26,
                color: disabled ? disabledColor : null)),
        onTap: disabled ? null : () => onDigit?.call('0'),
      );
    }
    if (num == 12) {
      return _KeyButton(
        child: Icon(Icons.backspace_outlined,
            size: 24, color: disabled ? disabledColor : null),
        onTap: disabled ? null : onDelete,
      );
    }
    return _KeyButton(
      child: Text('$num',
          style: TextStyle(
              fontSize: 26,
              color: disabled ? disabledColor : null)),
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
      width: 72,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: child),
        ),
      ),
    );
  }
}
