import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// The phases the transaction moves through.
enum TxnPhase { scanning, processing, success, unavailable }

/// Screen that runs the (mock) contactless transaction. It starts an NFC
/// session and — per the app's design — accepts ANY tag that is read,
/// then plays a success animation. No card data is read or stored.
class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key, required this.amount});

  final double amount;

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with TickerProviderStateMixin {
  TxnPhase _phase = TxnPhase.scanning;
  String _status = 'Hold a card near the device';

  late final AnimationController _pulse;
  late final AnimationController _success;
  bool _sessionActive = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _success = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _startNfc();
  }

  Future<void> _startNfc() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      if (availability != NfcAvailability.enabled) {
        if (!mounted) return;
        setState(() {
          _phase = TxnPhase.unavailable;
          _status = availability == NfcAvailability.disabled
              ? 'NFC is turned off. Enable it in settings.'
              : 'NFC is not available on this device.';
        });
        return;
      }

      _sessionActive = true;
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        alertMessageIos: 'Hold your card near the top of the phone',
        onDiscovered: (NfcTag tag) async {
          // Accept ANY tag. We do not inspect or store its contents.
          await _stopSession(successMessageIos: 'Payment approved');
          if (!mounted) return;
          _onApproved();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = TxnPhase.unavailable;
        _status = 'Could not start NFC. ($e)';
      });
    }
  }

  Future<void> _stopSession({String? successMessageIos}) async {
    if (!_sessionActive) return;
    _sessionActive = false;
    try {
      await NfcManager.instance.stopSession(alertMessageIos: successMessageIos);
    } catch (_) {
      // Ignore stop errors — the session may already be closed.
    }
  }

  Future<void> _onApproved() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = TxnPhase.processing;
      _status = 'Authorizing…';
    });
    _pulse.stop();
    // Brief mock "processing" delay for a realistic feel.
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _phase = TxnPhase.success;
      _status = 'Payment approved';
    });
    _success.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _success.dispose();
    _stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            final navigator = Navigator.of(context);
            _stopSession().whenComplete(() {
              if (mounted) navigator.pop();
            });
          },
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          children: [
            const Spacer(),
            _amountHeader(),
            const SizedBox(height: 48),
            SizedBox(
              height: 260,
              child: Center(child: _visual()),
            ),
            const SizedBox(height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _status,
                key: ValueKey(_status),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            _bottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _amountHeader() {
    return Column(
      children: [
        Text(
          'Amount due',
          style: TextStyle(color: AppTheme.silverDim, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          '\$${widget.amount.toStringAsFixed(2)}',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _visual() {
    switch (_phase) {
      case TxnPhase.scanning:
        return _RadarPulse(controller: _pulse);
      case TxnPhase.processing:
        return const SizedBox(
          height: 90,
          width: 90,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppTheme.accentGlow),
          ),
        );
      case TxnPhase.success:
        return _SuccessCheck(controller: _success);
      case TxnPhase.unavailable:
        return Icon(
          Icons.nfc_rounded,
          size: 96,
          color: Colors.white.withValues(alpha: 0.4),
        );
    }
  }

  Widget _bottomAction() {
    switch (_phase) {
      case TxnPhase.success:
        return GlassButton(
          label: 'Done',
          icon: Icons.check_rounded,
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        );
      case TxnPhase.unavailable:
        return GlassButton(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onPressed: () {
            setState(() {
              _phase = TxnPhase.scanning;
              _status = 'Hold a card near the device';
            });
            if (!_pulse.isAnimating) _pulse.repeat();
            _startNfc();
          },
        );
      case TxnPhase.scanning:
      case TxnPhase.processing:
        return Text(
          'Waiting for card…',
          style: TextStyle(color: AppTheme.silverDim, fontSize: 13),
        );
    }
  }
}

/// Concentric expanding rings + a contactless glyph — the "waiting" animation.
class _RadarPulse extends StatelessWidget {
  const _RadarPulse({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          height: 240,
          width: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                _ring((controller.value + i / 3) % 1.0),
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.9),
                      AppTheme.accentGlow.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.contactless_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double t) {
    final size = 96 + t * 144;
    return Opacity(
      opacity: (1 - t) * 0.6,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.accentGlow.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// An animated circle + check-mark drawn on success.
class _SuccessCheck extends StatelessWidget {
  const _SuccessCheck({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final circle = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    final check = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.scale(
          scale: 0.7 + 0.3 * circle.value,
          child: Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34D399).withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _CheckPainter(progress: check.value),
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    // Three points of the check mark.
    final p1 = Offset(w * 0.30, h * 0.52);
    final p2 = Offset(w * 0.44, h * 0.66);
    final p3 = Offset(w * 0.72, h * 0.36);

    final path = Path()..moveTo(p1.dx, p1.dy);
    // First segment length vs second, to draw progressively.
    final len1 = (p2 - p1).distance;
    final len2 = (p3 - p2).distance;
    final total = len1 + len2;
    final drawn = progress * total;

    if (drawn <= len1) {
      final t = drawn / len1;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = ((drawn - len1) / len2).clamp(0.0, 1.0);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
