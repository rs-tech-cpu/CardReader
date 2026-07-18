import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/txn.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import 'amount_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// A small helper: fade + slide each section in, staggered.
  Widget _staggered(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _staggered(0, _header()),
          const SizedBox(height: 24),
          _staggered(1, const PlatinumCard()),
          const SizedBox(height: 28),
          _staggered(2, _recentHeader()),
          const SizedBox(height: 12),
          _staggered(3, _recentList()),
          const SizedBox(height: 24),
          _staggered(4, GlassButton(
            label: 'Tap card',
            icon: Icons.contactless_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AmountScreen()),
              );
            },
          )),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your terminal is ready',
                style: TextStyle(
                  color: AppTheme.silverDim,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.accent.withValues(alpha: 0.9),
                AppTheme.accentGlow.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _recentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent transactions',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'View all',
          style: TextStyle(color: AppTheme.silverDim, fontSize: 13),
        ),
      ],
    );
  }

  Widget _recentList() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Column(
        children: [
          for (int i = 0; i < Txn.samples.length; i++) ...[
            _TxnRow(txn: Txn.samples[i]),
            if (i != Txn.samples.length - 1)
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
                indent: 64,
                endIndent: 12,
              ),
          ],
        ],
      ),
    );
  }
}

/// A single recent-transaction row. Intentionally non-interactive because the
/// data is fake — [IgnorePointer] blocks any taps.
class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});

  final Txn txn;

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.amount > 0;
    final amountText =
        '${isCredit ? '+' : '-'}\$${txn.amount.abs().toStringAsFixed(2)}';
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(txn.icon, color: AppTheme.silver, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.merchant,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${txn.category} · ${txn.when}',
                    style: TextStyle(color: AppTheme.silverDim, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              amountText,
              style: TextStyle(
                color: isCredit
                    ? const Color(0xFF4ADE80)
                    : AppTheme.silver,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The translucent "Platinum" payment card with a fake card number.
class PlatinumCard extends StatelessWidget {
  const PlatinumCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586, // standard card ratio
      child: GlassContainer(
        gradient: AppTheme.cardGradient,
        borderRadius: 24,
        blur: 6,
        borderOpacity: 0.18,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top-left: "Platinum" in silver, elegant font.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platinum',
                        style: GoogleFonts.cormorantGaramond(
                          color: AppTheme.silver,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'PAYMENT',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.silverDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.contactless_rounded,
                  color: AppTheme.silver.withValues(alpha: 0.85),
                  size: 26,
                ),
              ],
            ),
            const Spacer(),
            // EMV-style chip.
            Container(
              height: 30,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE9D9A6), Color(0xFFB79A55)],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Fake card number.
            Text(
              '4921  ••••  ••••  7043',
              style: GoogleFonts.sourceCodePro(
                color: AppTheme.silver,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _cardMeta('CARD HOLDER', 'A. SETIA'),
                const SizedBox(width: 28),
                _cardMeta('EXPIRES', '08/29'),
                const Spacer(),
                Text(
                  'VISA',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.silver,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.silverDim,
            fontSize: 8,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.silver,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
