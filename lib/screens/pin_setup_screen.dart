import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pin_service.dart';
import '../state/app_state.dart';
import 'package:go_router/go_router.dart';

/// Full-screen PIN setup page with rich onboarding UI.
/// Appears on first launch (after splash) when no PIN is set,
/// and from Settings → Security → Set PIN.
class PinSetupScreen extends ConsumerStatefulWidget {
  /// If true, shows as first-launch onboarding with a skip option.
  final bool isOnboarding;

  /// Called when the user taps "Skip for now" during onboarding.
  final VoidCallback? onSkip;

  const PinSetupScreen({super.key, this.isOnboarding = false, this.onSkip});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error;
  bool _saving = false;
  bool _success = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_saving || _success) return;
    setState(() {
      _error = null;
      if (!_isConfirming) {
        if (_pin.length < _pinLength) _pin += digit;
        if (_pin.length == _pinLength) {
          Future.delayed(const Duration(milliseconds: 350), () {
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
    if (_saving || _success) return;
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
      // Shake feedback
      setState(() {
        _error = 'PINs do not match. Try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(pinProvider.notifier).setPin(_pin);
      setState(() {
        _saving = false;
        _success = true;
      });

      // Show success state briefly then navigate away
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        if (widget.isOnboarding) {
          // First launch: go to dashboard
          context.go('/');
        } else {
          // From settings: pop back
          context.pop();
        }
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to save PIN. Try again.';
      });
    }
  }

  void _skip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pin = _isConfirming ? _confirmPin : _pin;

    if (_success) {
      return Scaffold(
        body: _buildSuccessView(theme, colorScheme),
      );
    }

    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: const Text('Set PIN'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  if (widget.isOnboarding) const SizedBox(height: 48),
                  const Spacer(flex: 1),

                  // Hero icon
                  _buildIcon(colorScheme),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _isConfirming ? 'Confirm Your PIN' : 'Secure Your App',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    _isConfirming
                        ? 'Enter your PIN again to confirm'
                        : 'Set a 4-digit PIN to keep your API keys safe',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // PIN dots
                  _buildPinDots(pin, colorScheme),
                  const SizedBox(height: 8),

                  // Error
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

                  const SizedBox(height: 8),

                  // Progress indicator
                  Text(
                    _isConfirming
                        ? 'Step 2 of 2'
                        : (_pin.isEmpty
                            ? 'Step 1 of 2'
                            : 'Step 1 of 2 · ${_pin.length} of $_pinLength'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pin pad
                  _PinPad(
                    onDigit: (_saving || _success) ? null : _onDigit,
                    onDelete: (_saving || _success) ? null : _onDelete,
                  ),

                  const Spacer(flex: 2),

                  // Skip button (onboarding mode only)
                  if (widget.isOnboarding)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: TextButton(
                        onPressed: _saving ? null : _skip,
                        child: const Text('Skip for now'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    return Container(
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
        Icons.shield_rounded,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPinDots(String pin, ColorScheme colorScheme) {
    return Row(
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
            color: filled ? colorScheme.primary : Colors.transparent,
            border: Border.all(
              color: filled
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.4),
              width: 2.5,
            ),
            boxShadow: filled
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
    );
  }

  Widget _buildSuccessView(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'PIN Set Successfully',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your API keys are now protected.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom numeric keypad (iOS style)
// ---------------------------------------------------------------------------

class _PinPad extends StatelessWidget {
  final void Function(String)? onDigit;
  final VoidCallback? onDelete;

  const _PinPad({this.onDigit, this.onDelete});

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
