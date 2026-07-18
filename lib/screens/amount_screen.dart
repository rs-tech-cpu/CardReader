import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import 'transaction_screen.dart';

/// Screen where the merchant enters the amount to charge before tapping.
class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  // Amount stored in cents to avoid float rounding while typing.
  int _cents = 0;

  String get _display {
    final dollars = _cents ~/ 100;
    final remainder = _cents % 100;
    return '$dollars.${remainder.toString().padLeft(2, '0')}';
  }

  bool get _valid => _cents > 0;

  void _tapDigit(int d) {
    // Cap to a sane maximum so the display never overflows.
    if (_cents >= 1000000) return; // $10,000.00
    HapticFeedback.selectionClick();
    setState(() => _cents = _cents * 10 + d);
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    setState(() => _cents = _cents ~/ 10);
  }

  void _continue() {
    if (!_valid) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionScreen(amount: _cents / 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Charge amount',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            Text(
              'Enter amount',
              style: TextStyle(color: AppTheme.silverDim, fontSize: 15),
            ),
            const SizedBox(height: 16),
            // Big animated amount readout.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 4),
                  child: Text(
                    '\$',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.silver,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    _display,
                    key: ValueKey(_cents),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap-to-pay · Contactless',
              style: TextStyle(color: AppTheme.silverDim, fontSize: 12),
            ),
            const Spacer(),
            _Keypad(onDigit: _tapDigit, onBackspace: _backspace),
            const SizedBox(height: 24),
            GlassButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              enabled: _valid,
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final void Function(int) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AspectRatio(
            aspectRatio: 1.7,
            child: GlassContainer(
              padding: EdgeInsets.zero,
              borderRadius: 18,
              blur: 8,
              onTap: onTap,
              child: Center(
                child: child ??
                    Text(
                      label,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(List<Widget> children) =>
        Row(children: children);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([
          key('1', onTap: () => onDigit(1)),
          key('2', onTap: () => onDigit(2)),
          key('3', onTap: () => onDigit(3)),
        ]),
        row([
          key('4', onTap: () => onDigit(4)),
          key('5', onTap: () => onDigit(5)),
          key('6', onTap: () => onDigit(6)),
        ]),
        row([
          key('7', onTap: () => onDigit(7)),
          key('8', onTap: () => onDigit(8)),
          key('9', onTap: () => onDigit(9)),
        ]),
        row([
          key('', child: const SizedBox()),
          key('0', onTap: () => onDigit(0)),
          key('',
              onTap: onBackspace,
              child: const Icon(Icons.backspace_outlined,
                  color: Colors.white, size: 24)),
        ]),
      ],
    );
  }
}
