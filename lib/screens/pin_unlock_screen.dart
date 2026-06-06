import 'package:flutter/material.dart';
import '../services/pin_service.dart';

/// Full-screen PIN unlock shown when the app launches with a PIN set.
class PinUnlockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinUnlockScreen({super.key, required this.onUnlocked});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  String _pin = '';
  String? _error;
  bool _verifying = false;

  static const _pinLength = 4;

  void _onDigit(String digit) {
    if (_verifying) return;
    setState(() {
      _error = null;
      if (_pin.length < _pinLength) _pin += digit;
      if (_pin.length == _pinLength) _verify();
    });
  }

  void _onDelete() {
    if (_verifying) return;
    setState(() {
      _error = null;
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    // Slight delay so user sees the last dot fill in
    await Future.delayed(const Duration(milliseconds: 200));

    final valid = await PinService.verifyPin(_pin);
    if (!mounted) return;

    if (valid) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _pin = '';
        _verifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 36,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'AI Balance Tracker',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your PIN to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // PIN dots with shake on error
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _error != null ? 1 : 0),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeOffset(value),
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pinLength, (i) {
                      final filled = i < _pin.length;
                      final error = _error != null;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: error
                              ? colorScheme.error
                              : filled
                                  ? colorScheme.primary
                                  : Colors.transparent,
                          border: Border.all(
                            color: error
                                ? colorScheme.error
                                : filled
                                    ? colorScheme.primary
                                    : colorScheme.outline
                                        .withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Error text
                AnimatedOpacity(
                  opacity: _error != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _error ?? '',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Pin pad
                _PinPad(
                  onDigit: _verifying ? null : _onDigit,
                  onDelete: _verifying ? null : _onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _shakeOffset(double t) {
    // Damped sine wave for shake effect
    if (t <= 0 || t >= 1) return 0;
    return 12 * (1 - t) * (1 - t) * (1 - t) * (1 - t);
  }
}

// Reuse the same PIN pad widget
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
    if (num == 10) return const SizedBox(width: 72, height: 56);
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
