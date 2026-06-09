import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pin_service.dart';
import '../widgets/pin_pad.dart';

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

    final body = SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Spacer(flex: 1),

              // Lock icon — matching setup screen size/style
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'AI Balance Tracker',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Enter your PIN to continue',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // PIN dots
              _PinDots(pin: _pin, error: _error != null),
              const SizedBox(height: 8),

              // Error text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          key: ValueKey(_error),
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Pin pad — shared widget, same as setup screen
              PinPad(
                onDigit: _verifying ? null : _onDigit,
                onDelete: _verifying ? null : _onDelete,
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      );

    return Scaffold(
      body: Platform.isIOS || Platform.isAndroid
          ? body
          : Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (_verifying) return KeyEventResult.ignored;
                  final key = event.logicalKey;
                  if (key >= LogicalKeyboardKey.digit0 &&
                      key <= LogicalKeyboardKey.digit9) {
                    final digit = String.fromCharCode(
                      0x30 + (key.keyId - LogicalKeyboardKey.digit0.keyId));
                    _onDigit(digit);
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.backspace ||
                      key == LogicalKeyboardKey.delete) {
                    _onDelete();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: body,
            ),
    );
  }
}

/// PIN entry dots with shake-on-error animation.
class _PinDots extends StatelessWidget {
  final String pin;
  final bool error;
  static const _pinLength = 4;

  const _PinDots({required this.pin, required this.error});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: error ? 1 : 0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset(value), 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinLength, (i) {
          final filled = i < pin.length;
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
                        : colorScheme.outline.withValues(alpha: 0.4),
                width: 2.5,
              ),
              boxShadow: filled && !error
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  double _shakeOffset(double t) {
    if (t <= 0 || t >= 1) return 0;
    return 12 * (1 - t) * (1 - t) * (1 - t) * (1 - t);
  }
}
