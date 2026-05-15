import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy_data/salama_data.dart';
import '../../../data/models/child_model.dart';

/// Full-screen live QR scanner. Pops with the resolved [ChildModel] (or null).
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;
  bool _torch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Resolves the scanned code to a child. If the code carries a known
  /// record id we use it; otherwise the code is mapped deterministically
  /// so any QR scan still opens a record (prototype data).
  ChildModel _resolve(String raw) {
    final code = raw.trim().toUpperCase();
    for (final c in SalamaData.children) {
      if (code.contains(c.id.toUpperCase())) return c;
    }
    final idx = code.hashCode.abs() % SalamaData.children.length;
    return SalamaData.children[idx];
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      _handled = true;
      _controller.stop();
      Navigator.pop(context, _resolve(raw));
      return;
    }
  }

  Future<void> _manualEntry() async {
    final child = await showModalBottomSheet<ChildModel>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const _ManualEntrySheet(),
    );
    if (child != null && mounted) {
      _handled = true;
      Navigator.pop(context, child);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final windowSize = mq.size.width * 0.66;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Dark overlay with cut-out window
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(windowSize: windowSize),
            ),
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan child QR',
                            style: AppTextStyles.h3
                                .copyWith(color: Colors.white)),
                        Text('Point at the immunization card',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                  _CircleButton(
                    icon: _torch
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    active: _torch,
                    onTap: () {
                      _controller.toggleTorch();
                      setState(() => _torch = !_torch);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Window hint
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: windowSize + 40),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Align the QR code within the frame',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          // Bottom — manual entry
          Positioned(
            left: 16,
            right: 16,
            bottom: mq.padding.bottom + 18,
            child: GestureDetector(
              onTap: _manualEntry,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.keyboard_rounded,
                        size: 17, color: AppColors.primary),
                    const SizedBox(width: 7),
                    Text('Enter child ID manually',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double windowSize;
  _ScannerOverlayPainter({required this.windowSize});

  @override
  void paint(Canvas canvas, Size size) {
    final window = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.38),
      width: windowSize,
      height: windowSize,
    );
    final rrect =
        RRect.fromRectAndRadius(window, const Radius.circular(20));

    // Dark surround.
    final overlay = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(
        overlay, Paint()..color = Colors.black.withValues(alpha: 0.62));

    // Corner brackets.
    final p = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const c = 30.0;
    final l = window.left, t = window.top, r = window.right, b = window.bottom;
    canvas.drawLine(Offset(l, t + c), Offset(l, t + 14), p);
    canvas.drawLine(Offset(l + 14, t), Offset(l + c, t), p);
    canvas.drawLine(Offset(r - c, t), Offset(r - 14, t), p);
    canvas.drawLine(Offset(r, t + 14), Offset(r, t + c), p);
    canvas.drawLine(Offset(l, b - c), Offset(l, b - 14), p);
    canvas.drawLine(Offset(l + 14, b), Offset(l + c, b), p);
    canvas.drawLine(Offset(r - c, b), Offset(r - 14, b), p);
    canvas.drawLine(Offset(r, b - 14), Offset(r, b - c), p);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.windowSize != windowSize;
}

// ── Manual entry sheet ───────────────────────────────────────────────────
class _ManualEntrySheet extends StatelessWidget {
  const _ManualEntrySheet();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.7),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD, 2, AppDimensions.spaceMD, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select a child', style: AppTextStyles.h3),
                  Text('Pick the child whose card you are scanning',
                      style: AppTextStyles.captionMuted),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.borderLight),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                shrinkWrap: true,
                itemCount: SalamaData.children.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final c = SalamaData.children[i];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, c),
                    child: Container(
                      padding: const EdgeInsets.all(
                          AppDimensions.cardPaddingSm),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD),
                        border: Border.all(
                            color: AppColors.borderLight, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.child_care_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: AppTextStyles.h4),
                                Text('${c.id} • ${c.ageLabel}',
                                    style: AppTextStyles.captionMuted),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
