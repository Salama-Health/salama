import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../scan/qr_scanner_screen.dart';
import '../scan/scanned_child_sheet.dart';
import 'home_body.dart';
import '../visits/visits_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  /// Bottom-nav index 2 is Scan QR — it opens the live camera scanner.
  Future<void> _goTo(int i) async {
    if (i == 2) {
      final child = await Navigator.of(context).push<ChildModel?>(
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );
      if (child != null && mounted) {
        showScannedChildSheet(context, child);
      }
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          HomeBody(onNavigate: _goTo),
          VisitsScreen(onNavigate: _goTo),
          const SizedBox.shrink(), // slot 2 — Scan QR opens the camera
          const ReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _index,
        onTap: _goTo,
      ),
    );
  }
}
