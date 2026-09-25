import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/child_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_text_field.dart';

/// Full-screen live QR scanner. Pops with the resolved [ChildModel] (or null).
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;
  bool _torch = false;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      _handled = true;
      _controller.stop();
      _resolveAndPop(raw);
      return;
    }
  }

  /// Resolve the scanned code against the backend and pop with the child.
  Future<void> _resolveAndPop(String raw) async {
    setState(() => _loading = true);
    final qr = raw.trim().replaceFirst(RegExp(r'^SALAMA[:\-A-Z]*:'), '');
    try {
      final child = await ref.read(childrenRepositoryProvider).lookupByQr(qr);
      if (mounted) Navigator.pop(context, child);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _handled = false;
      });
      _controller.start();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No record found for that code')),
      );
    }
  }

  Future<void> _manualEntry() async {
    // Prefer whatever is loaded; fall back to the cached caseload so the
    // manual route still works with no signal — which is exactly when a
    // scanner failure is most likely to strand a worker.
    var children =
        ref.read(childrenProvider).valueOrNull ?? const <ChildModel>[];
    if (children.isEmpty) {
      children = ref.read(childrenRepositoryProvider).cachedList();
    }
    final child = await showModalBottomSheet<ChildModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => _ManualEntrySheet(children: children),
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
          // Resolving overlay
          if (_loading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
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
/// The fallback when a code will not scan — a smudged card, a cracked lens, a
/// caregiver who left the card at home. Searches by name, code, village or
/// caregiver, so a child can always be found by something the caregiver knows.
class _ManualEntrySheet extends StatefulWidget {
  final List<ChildModel> children;
  const _ManualEntrySheet({required this.children});

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final results = searchChildren(widget.children, _query);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.8),
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
                    AppDimensions.spaceMD, 2, AppDimensions.spaceMD, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find a child', style: AppTextStyles.h3),
                    Text(
                      widget.children.isEmpty
                          ? 'No children saved on this phone yet'
                          : 'Search ${widget.children.length} children in your caseload',
                      style: AppTextStyles.captionMuted,
                    ),
                    const SizedBox(height: 9),
                    AppSearchField(
                      controller: _search,
                      hint: 'Name, code, village or caregiver',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ),
              const Divider(
                  height: 1, thickness: 1, color: AppColors.borderLight),
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              widget.children.isEmpty
                                  ? Icons.cloud_off_rounded
                                  : Icons.search_off_rounded,
                              size: 28,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.children.isEmpty
                                  ? 'Sync once to load your caseload'
                                  : 'Nobody matches that search',
                              style: AppTextStyles.h4,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.spaceMD),
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final c = results[i];
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, c),
                            behavior: HitTestBehavior.opaque,
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
                                    child: const Icon(
                                        Icons.child_care_rounded,
                                        color: AppColors.primary,
                                        size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.h4),
                                        Text(
                                            '${c.code} • ${c.ageLabel} • ${c.currentLocation}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                AppTextStyles.captionMuted),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 18,
                                      color: AppColors.textTertiary),
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
      ),
    );
  }
}
