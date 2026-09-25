import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/route_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import 'route_run_screen.dart';
import 'visits_screen.dart' show priorityHue;

void showRoutePlanSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => const _RoutePlanSheet(),
  );
}

RiskBand _band(String s) => switch (s) {
      'High' => RiskBand.high,
      'Medium' => RiskBand.medium,
      'Watch' => RiskBand.watch,
      _ => RiskBand.low,
    };

String _priorityLabel(RiskBand b) => switch (b) {
      RiskBand.high => 'High priority',
      RiskBand.medium => 'Elevated',
      RiskBand.watch => 'Watch',
      RiskBand.low => 'Routine',
    };

class _RoutePlanSheet extends ConsumerWidget {
  const _RoutePlanSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    final routeAsync = ref.watch(routeProvider);
    final facility = ref.watch(currentWorkerProvider)?.facility ?? 'your facility';

    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
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
            const _Grabber(),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD, 6, AppDimensions.spaceSM, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: const Icon(Icons.route_rounded,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Optimized route', style: AppTextStyles.h3),
                        Text('Priority-first, shortest distance',
                            style: AppTextStyles.captionMuted),
                      ],
                    ),
                  ),
                  _CloseButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.borderLight),
            Flexible(
              child: routeAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 30, color: AppColors.textTertiary),
                      const SizedBox(height: 8),
                      Text('Couldn’t load the route',
                          style: AppTextStyles.h4),
                      const SizedBox(height: 2),
                      Text('$e',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.captionMuted),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(routeProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (route) => route.stops.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppDimensions.spaceLG),
                        child: Center(
                          child: Text('No pending visits to route',
                              style: AppTextStyles.captionMuted),
                        ),
                      )
                    : _RouteContent(route: route, facility: facility),
              ),
            ),
            // Action bar
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD, 9, AppDimensions.spaceMD, 9),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                    top: BorderSide(
                        color: AppColors.borderMedium, width: 1)),
              ),
              child: GestureDetector(
                onTap: () {
                  final stops = routeAsync.valueOrNull;
                  if (stops == null || stops.stops.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No stops to run yet.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RouteRunScreen(route: stops),
                    ),
                  );
                },
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 7),
                      Text('Start route',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteContent extends StatelessWidget {
  final OptimizedRoute route;
  final String facility;
  const _RouteContent({required this.route, required this.facility});

  @override
  Widget build(BuildContext context) {
    final stops = route.stops;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      shrinkWrap: true,
      children: [
        _RouteMap(stops: stops),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _SummaryTile(
                    icon: Icons.place_outlined,
                    value: '${stops.length}',
                    label: 'Stops')),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryTile(
                    icon: Icons.straighten_rounded,
                    value: '${route.totalKm.toStringAsFixed(1)} km',
                    label: 'Distance')),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryTile(
                    icon: Icons.schedule_rounded,
                    value: '~${route.estMinutes} min',
                    label: 'Est. time')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const _Tag('ROUTE ORDER'),
            const SizedBox(width: 6),
            Text('Highest priority first',
                style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        _StartRow(facility: facility),
        ...List.generate(stops.length, (i) {
          return _StopRow(
            index: i + 1,
            stop: stops[i],
            isLast: i == stops.length - 1,
          );
        }),
      ],
    );
  }
}

// ── Map preview ──────────────────────────────────────────────────────────────
class _RouteMap extends StatelessWidget {
  final List<RouteStop> stops;
  const _RouteMap({required this.stops});

  static const _pins = [
    Offset(0.16, 0.74),
    Offset(0.34, 0.40),
    Offset(0.52, 0.66),
    Offset(0.68, 0.32),
    Offset(0.83, 0.58),
    Offset(0.90, 0.26),
  ];
  static const _start = Offset(0.07, 0.88);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEF2),
          border: Border.all(color: AppColors.borderMedium, width: 1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MapPainter(
                  count: stops.length.clamp(0, _pins.length),
                ),
              ),
            ),
            _PinAt(
              pos: _start,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.home_rounded,
                    size: 8, color: Colors.white),
              ),
            ),
            ...List.generate(stops.length.clamp(0, _pins.length), (i) {
              final hue = priorityHue(_band(stops[i].riskBand));
              return _PinAt(
                pos: _pins[i],
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: hue.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              );
            }),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                      color: AppColors.borderMedium, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text('Open full map',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinAt extends StatelessWidget {
  final Offset pos;
  final Widget child;
  const _PinAt({required this.pos, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(pos.dx * 2 - 1, pos.dy * 2 - 1),
      child: child,
    );
  }
}

class _MapPainter extends CustomPainter {
  final int count;
  _MapPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(Offset f) => Offset(f.dx * size.width, f.dy * size.height);

    final street = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 7;
    canvas.drawLine(Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.35), street);
    canvas.drawLine(Offset(size.width * 0.45, 0),
        Offset(size.width * 0.6, size.height), street);
    canvas.drawLine(Offset(0, size.height * 0.2),
        Offset(size.width, size.height * 0.85),
        street..strokeWidth = 5);

    final block = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (var i = 0; i < 6; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              (i % 3) * size.width * 0.34 + 8,
              (i ~/ 3) * size.height * 0.5 + 10,
              size.width * 0.24,
              size.height * 0.30),
          const Radius.circular(4),
        ),
        block,
      );
    }

    final pts = <Offset>[
      p(_RouteMap._start),
      for (var i = 0; i < count; i++) p(_RouteMap._pins[i]),
    ];
    final route = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final dist = (b - a).distance;
      final steps = (dist / 9).floor().clamp(1, 999);
      for (var s = 0; s < steps; s += 2) {
        final t1 = s / steps, t2 = ((s + 1) / steps).clamp(0.0, 1.0);
        canvas.drawLine(
            Offset.lerp(a, b, t1)!, Offset.lerp(a, b, t2)!, route);
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.count != count;
}

// ── Summary tile ─────────────────────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              style: AppTextStyles.captionMuted.copyWith(fontSize: 9.5)),
        ],
      ),
    );
  }
}

// ── Start row ────────────────────────────────────────────────────────────────
class _StartRow extends StatelessWidget {
  final String facility;
  const _StartRow({required this.facility});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_rounded,
                    size: 13, color: Colors.white),
              ),
              Expanded(
                child: Container(width: 2, color: AppColors.borderLight),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start — $facility', style: AppTextStyles.h4),
                Text('Your facility', style: AppTextStyles.captionMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stop row ─────────────────────────────────────────────────────────────────
class _StopRow extends StatelessWidget {
  final int index;
  final RouteStop stop;
  final bool isLast;
  const _StopRow({
    required this.index,
    required this.stop,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final band = _band(stop.riskBand);
    final hue = priorityHue(band);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: hue.accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('$index',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.borderLight),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
                decoration: BoxDecoration(
                  color: hue.bg,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: hue.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text(stop.childName, style: AppTextStyles.h4),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: hue.accent,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull),
                          ),
                          child: Text(_priorityLabel(band),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.my_location_rounded,
                            size: 11, color: hue.accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(stop.currentLocation ?? '—',
                              style: AppTextStyles.captionMuted
                                  .copyWith(fontSize: 10.5),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.directions_walk_rounded,
                            size: 11, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text('${stop.distanceKm} km',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            )),
                      ],
                    ),
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

// ── Shared ───────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25), width: 0.75),
      ),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          )),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 2),
      width: 36,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.borderMedium,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderMedium, width: 1),
        ),
        child: const Icon(Icons.close_rounded,
            size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
