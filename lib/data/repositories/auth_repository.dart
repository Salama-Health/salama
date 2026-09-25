import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/offline_cache.dart';
import '../../core/storage/token_storage.dart';
import '../models/worker_model.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage, this._cache);

  final ApiClient _api;
  final TokenStorage _storage;
  final OfflineCache _cache;

  /// Login with worker ID + PIN. Persists tokens and returns the worker.
  Future<WorkerModel> login(String workerId, String pin) async {
    final resp = await _api.post(
      '/auth/login',
      data: {'workerId': workerId, 'pin': pin},
      options: Options(extra: {'skipAuth': true}),
    );
    final data = resp.data as Map<String, dynamic>;
    await _storage.save(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
    final workerJson = data['worker'] as Map<String, dynamic>;
    await _cache.write(OfflineCache.kWorker, workerJson);
    return WorkerModel.fromJson(workerJson);
  }

  Future<WorkerModel> me() async {
    final resp = await _api.get('/auth/me');
    final json = resp.data as Map<String, dynamic>;
    await _cache.write(OfflineCache.kWorker, json);
    return WorkerModel.fromJson(json);
  }

  /// The last profile seen, for starting up with no connection.
  WorkerModel? cachedWorker() {
    final json = _cache.read(OfflineCache.kWorker);
    if (json is! Map) return null;
    try {
      return WorkerModel.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return null;
    }
  }

  Future<void> changePin({required String currentPin, required String newPin}) {
    return _api.post('/auth/change-pin',
        data: {'currentPin': currentPin, 'newPin': newPin});
  }

  Future<void> logout() async {
    await _storage.clear();
    await _cache.clearAll();
  }
}
