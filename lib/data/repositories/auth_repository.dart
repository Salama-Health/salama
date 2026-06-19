import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/worker_model.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

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
    return WorkerModel.fromJson(data['worker'] as Map<String, dynamic>);
  }

  Future<WorkerModel> me() async {
    final resp = await _api.get('/auth/me');
    return WorkerModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}
