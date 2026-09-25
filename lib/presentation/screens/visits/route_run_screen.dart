import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/id_gen.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/route_models.dart';
import '../../../data/repositories/outbox_repository.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/brand_header.dart';
import '../scan/child_detail_sheet.dart';
import '../scan/record_vaccination_sheet.dart';
import 'visits_screen.dart' show priorityHue;

/// Walks the worker through an optimized route one stop at a time.
///
/// Each outcome — visited or skipped — posts straight away when there is signal
/// and goes to the outbox when there is not, so a full day's round trip survives
/// having no connection from the moment the worker leaves the facility.
class RouteRunScreen extends ConsumerStatefulWidget {
  final OptimizedRoute route;
  const RouteRunScreen({super.key, required this.route});

  @override
  ConsumerState<RouteRunScreen> createState() => _RouteRunScreenState();
}

class _RouteRunScreenState extends ConsumerState<RouteRunScreen> {
  int _index = 0;
  final Set<String> _visited = {};
  final Set<String> _skipped = {};

  List<RouteStop> get _stops => widget.route.stops;

  RouteStop? get _current => _index < _stops.length ? _stops[_index] : null;

  bool get _finished => _index >= _stops.length;

  double get _remainingKm => _stops
      .skip(_index)
      .fold<double>(0, (sum, s) => sum + s.distanceKm);

  ChildModel? _childFor(RouteStop stop) {
    final children =
        ref.read(childrenProvider).valueOrNull ?? const <ChildModel>[];
    for (final c in children) {
      if (c.id == stop.childId) return c;
    }
    return null;
  }

  Future<void> _record(RouteStop stop, {required bool visited}) async {
    final payload = <String, dynamic>{
      'clientUuid': IdGen.uuid(),
      'childId': stop.childId,
      'status': visited ? 'visited' : 'skipped',
      'visitedAt': DateTime.now().toUtc().toIso8601String(),
      'routeOrder': stop.order,
    };

    // Posts live when there is signal, queues when there is not. Either way the
    // worker moves to the next stop — a route must never stall on the network.
    try {
      await ref.read(outboxRepositoryProvider).submit<void>(
            kind: OutboxKind.visit,
            payload: payload,
            request: () => ref.read(visitsRepositoryProvider).record(payload),
          );
    } on ApiException catch (e) {
      // A rejection is worth showing, but the stop is still done.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visit not saved on the server: ${e.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    ref.invalidate(syncStatusProvider);
    ref.invalidate(childrenProvider);
    ref.invalidate(alertsProvider);

    if (!mounted) return;
    setState(() {
      (visited ? _visited : _skipped).add(stop.childId);
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _visited.length + _skipped.length;
    final total = _stops.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _RunHeader(
              done: done,
              total: total,
              remainingKm: _remainingKm,
              onExit: () => _confirmExit(done, total),
            ),
          ),
          Expanded(
            child: _finished
                ? _RouteComplete(
                    visited: _visited.length,
                    skipped: _skipped.length,
                    totalKm: widget.route.totalKm,
                    onDone: () => Navigator.pop(context),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.spaceMD,
                      AppDimensions.screenPadding,
                      AppDimensions.spaceXXL,
                    ),
                    children: [
                      _CurrentStopCard(
                        stop: _current!,
                        position: _index + 1,
                        total: total,
                        child: _childFor(_current!),
                        onOpenRecord: () {
                          final c = _childFor(_current!);
                          if (c != null) showChildDetailSheet(context, c);
                        },
                        onVaccinate: () {
                          final c = _childFor(_current!);
                          if (c != null) {
                            showRecordVaccinationSheet(context, c);
                          }
                        },
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Skip',
                              variant: AppButtonVariant.outline,
                              icon: Icons.redo_rounded,
                              height: 44,
                              onPressed: () =>
                                  _record(_current!, visited: false),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceSM),
                          Expanded(
                            flex: 2,
                            child: AppButton(
                              label: 'Mark visited',
                              icon: Icons.check_circle_outline_rounded,
                              height: 44,
                              onPressed: () =>
                                  _record(_current!, visited: true),
                            ),
                          ),
                        ],
                      ),
                      if (_index + 1 < total) ...[
                        const SizedBox(height: AppDimensions.spaceLG),
                        Text('NEXT STOPS',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              letterSpacing: 0.7,
                            )),
                        const SizedBox(height: 7),
                        ..._stops.skip(_index + 1).map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _UpcomingStop(stop: s),
                              ),
                            ),
                      ],
                      if (done > 0) ...[
                        const SizedBox(height: AppDimensions.spaceLG),
                        Text('DONE',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              letterSpacing: 0.7,
                            )),
                        const SizedBox(height: 7),
                        ..._stops.take(_index).map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _CompletedStop(
                                  stop: s,
                                  visited: _visited.contains(s.childId),
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit(int done, int total) async {
    if (done == 0 || _finished) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG)),
        title: Text('Leave the route?', style: AppTextStyles.h2),
        content: Text(
          'You have done $done of $total stops. What you recorded is already '
          'saved — you can start the route again later.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }
}

// ── Header with progress ─────────────────────────────────────────────────────
class _RunHeader extends StatelessWidget {
  final int done;
  final int total;
  final double remainingKm;
  final VoidCallback onExit;

  const _RunHeader({
    required this.done,
    required this.total,
    required this.remainingKm,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, AppDimensions.screenPadding, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
              color: AppColors.borderLight, width: AppDimensions.borderThin),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onExit,
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textPrimary, size: 20),
                tooltip: 'Leave route',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Route in progress',
                        style: AppTextStyles.h1.copyWith(fontSize: 17)),
                    Text(
                      '$done of $total stops · '
                      '${remainingKm.toStringAsFixed(1)} km to go',
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
              const ConnectionPill(),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.surfaceElevated,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Current stop ─────────────────────────────────────────────────────────────
class _CurrentStopCard extends StatelessWidget {
  final RouteStop stop;
  final int position;
  final int total;
  final ChildModel? child;
  final VoidCallback onOpenRecord;
  final VoidCallback onVaccinate;

  const _CurrentStopCard({
    required this.stop,
    required this.position,
    required this.total,
    required this.child,
    required this.onOpenRecord,
    required this.onVaccinate,
  });

  RiskBand get _band => switch (stop.riskBand) {
        'High' => RiskBand.high,
        'Medium' => RiskBand.medium,
        'Watch' => RiskBand.watch,
        _ => RiskBand.low,
      };

  @override
  Widget build(BuildContext context) {
    final hue = priorityHue(_band);
    final due = child?.dueVaccines ?? const <String>[];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: hue.bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: hue.border, width: AppDimensions.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hue.accent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                ),
                child: Text('STOP $position OF $total',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                      letterSpacing: 0.6,
                    )),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.straighten_rounded,
                      size: 13, color: hue.accent),
                  const SizedBox(width: 4),
                  Text('${stop.distanceKm.toStringAsFixed(1)} km',
                      style: AppTextStyles.caption
                          .copyWith(color: hue.accent)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(stop.childName, style: AppTextStyles.h1.copyWith(fontSize: 20)),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  stop.currentLocation ??
                      child?.currentLocation ??
                      'Location unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
          if (due.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceMD),
            Text('DUE NOW',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                )),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: due
                  .map((v) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull),
                          border: Border.all(
                              color: AppColors.borderLight, width: 0.75),
                        ),
                        child: Text(v,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceMD),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Open record',
                  variant: AppButtonVariant.outline,
                  icon: Icons.folder_open_outlined,
                  height: 40,
                  small: true,
                  onPressed: child == null ? null : onOpenRecord,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: AppButton(
                  label: 'Give dose',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.vaccines_outlined,
                  height: 40,
                  small: true,
                  onPressed: child == null ? null : onVaccinate,
                ),
              ),
            ],
          ),
          if (child == null) ...[
            const SizedBox(height: 7),
            Text(
              'This child’s full record is not on the phone yet — sync to load it.',
              style: AppTextStyles.captionMuted,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Upcoming / completed rows ────────────────────────────────────────────────
class _UpcomingStop extends StatelessWidget {
  final RouteStop stop;
  const _UpcomingStop({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
            color: AppColors.borderLight, width: AppDimensions.borderNormal),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Text('${stop.order}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stop.childName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h4),
                if (stop.currentLocation != null)
                  Text(stop.currentLocation!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionMuted),
              ],
            ),
          ),
          Text('${stop.distanceKm.toStringAsFixed(1)} km',
              style: AppTextStyles.captionMuted),
        ],
      ),
    );
  }
}

class _CompletedStop extends StatelessWidget {
  final RouteStop stop;
  final bool visited;

  const _CompletedStop({required this.stop, required this.visited});

  @override
  Widget build(BuildContext context) {
    final color = visited ? AppColors.success : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
            color: AppColors.borderLight, width: AppDimensions.borderNormal),
      ),
      child: Row(
        children: [
          Icon(
            visited ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              stop.childName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: visited ? null : TextDecoration.lineThrough,
                decorationColor: AppColors.textTertiary,
              ),
            ),
          ),
          Text(visited ? 'Visited' : 'Skipped',
              style: AppTextStyles.captionMuted.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Completion ───────────────────────────────────────────────────────────────
class _RouteComplete extends StatelessWidget {
  final int visited;
  final int skipped;
  final double totalKm;
  final VoidCallback onDone;

  const _RouteComplete({
    required this.visited,
    required this.skipped,
    required this.totalKm,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_rounded,
                  size: 32, color: AppColors.success),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            Text('Route complete', style: AppTextStyles.h1.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              '$visited visited · $skipped skipped · '
              '${totalKm.toStringAsFixed(1)} km covered',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            Container(
              padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      size: 15, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Every stop is saved on this phone. Sync when you are '
                      'back in range to upload them.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            AppButton(
              label: 'Back to visits',
              icon: Icons.arrow_back_rounded,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}
