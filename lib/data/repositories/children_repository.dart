import '../../core/api/api_client.dart';
import '../../core/storage/offline_cache.dart';
import '../models/child_model.dart';

class ChildrenRepository {
  ChildrenRepository(this._api, this._cache);
  final ApiClient _api;
  final OfflineCache _cache;

  /// The worker's caseload. Cached, so the priority list survives a day with
  /// no signal.
  Future<List<ChildModel>> list({String? status}) {
    return _cache.readThrough<List<ChildModel>>(
      key: OfflineCache.kChildren,
      fetchJson: () async => (await _api.get('/children',
              query: status != null ? {'status': status} : null))
          .data,
      decode: (json) => (json as List)
          .map((e) => ChildModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ChildModel> detail(String id) async {
    final resp = await _api.get('/children/$id');
    return ChildModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// Resolve a scanned QR code. Falls back to the cached caseload when there is
  /// no signal, so scanning a child in the field still pulls up their record.
  Future<ChildModel> lookupByQr(String qr) async {
    try {
      final resp = await _api.get('/children/lookup', query: {'qr': qr});
      return ChildModel.fromJson(resp.data as Map<String, dynamic>);
    } catch (e) {
      final match = findCached(qr);
      if (match != null) return match;
      rethrow;
    }
  }

  /// Look a child up in the cached caseload by QR code or register number.
  ChildModel? findCached(String code) {
    final cached = _cache.read(OfflineCache.kChildren);
    if (cached is! List) return null;
    final needle = code.trim().toUpperCase();
    for (final e in cached) {
      if (e is! Map<String, dynamic>) continue;
      final child = ChildModel.fromJson(e);
      if (child.code.toUpperCase() == needle ||
          child.id.toUpperCase() == needle) {
        return child;
      }
    }
    return null;
  }

  /// Every child currently held on the device — used by search and by the
  /// manual-entry fallback when the scanner cannot read a code.
  List<ChildModel> cachedList() {
    final cached = _cache.read(OfflineCache.kChildren);
    if (cached is! List) return const [];
    return cached
        .whereType<Map<String, dynamic>>()
        .map(ChildModel.fromJson)
        .toList();
  }

  /// Add a child registered on this device to the cached caseload.
  ///
  /// Without this, a child registered with no signal would be invisible to the
  /// app that just created them: absent from the visit list, and unfindable by
  /// scanning the very code the caregiver was handed. The provisional entry is
  /// replaced by the server's own record on the next successful fetch.
  Future<void> addLocal(Map<String, dynamic> registration) async {
    final cached = _cache.read(OfflineCache.kChildren);
    final list = cached is List ? List<dynamic>.from(cached) : <dynamic>[];

    final due = (registration['dueVaccines'] as List?) ?? const [];
    list.insert(0, {
      // The client uuid stands in as the id until the server assigns one.
      'id': registration['clientUuid'],
      'qrCode': registration['qrCode'],
      'name': registration['name'],
      'gender': registration['gender'],
      'bornDate': registration['bornDate'],
      // A provisional score: enough to surface a child with doses outstanding
      // without inventing a model output the server has not produced yet.
      'riskScore': due.isEmpty ? 0.40 : 0.75,
      'distanceKm': registration['distanceKm'],
      'lastSeen': DateTime.now().toUtc().toIso8601String(),
      'currentLocation': registration['currentLocation'],
      'parentName': registration['parentName'],
      'parentPhone': registration['parentPhone'],
      'facilityId': registration['facilityId'],
      'dueVaccines': due,
      'history': const [],
      'status': 'toVisit',
      'pendingSync': true,
    });

    await _cache.write(OfflineCache.kChildren, list);
  }

  Future<ChildModel> create(Map<String, dynamic> body) async {
    final resp = await _api.post('/children', data: body);
    return ChildModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ChildModel> update(String id, Map<String, dynamic> body) async {
    final resp = await _api.patch('/children/$id', data: body);
    return ChildModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
