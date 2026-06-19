import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../splash/splash_screen.dart';

/// Root widget: decides Splash (loading) / intro+login / Home from auth state.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider).status;
    return switch (status) {
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.unauthenticated => const SplashScreen(),
      AuthStatus.unknown => const _BrandedLoader(),
    };
  }
}

class _BrandedLoader extends StatelessWidget {
  const _BrandedLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppConstants.logo, width: 72, height: 72,
                errorBuilder: (_, _, _) => const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.primary, size: 48)),
            const SizedBox(height: 20),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
