import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../profile/settings_sheets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F3),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background scene ─────────────────────────────────────
          Image.asset(
            AppConstants.landingBg,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFFEAF0F4),
            ),
          ),
          // ── Legibility wash (top + bottom) ───────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.32, 0.78, 1.0],
                colors: [
                  Colors.white.withValues(alpha: 0.92),
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          // ── Content ──────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      // Logo
                      Image.asset(
                        AppConstants.logo,
                        width: 92,
                        height: 92,
                        errorBuilder: (_, _, _) => Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: Colors.white,
                              size: 34),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appName,
                        style: GoogleFonts.inter(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppConstants.appTagline,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 34),
                      // Headline
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.8,
                          ),
                          children: [
                            TextSpan(
                              text: 'We help you\n',
                              style: const TextStyle(
                                  color: AppColors.textPrimary),
                            ),
                            const TextSpan(
                              text: 'act first.',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Predict risks, protect children,\n'
                        'and build healthier communities.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(flex: 3),
                      // Get started
                      _GetStartedButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppConstants.routeLogin),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => showAboutAppSheet(context),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Learn more',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Get started button ───────────────────────────────────────────────────
class _GetStartedButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _GetStartedButton({required this.onPressed});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDeep.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Get started',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              Positioned(
                right: 18,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
