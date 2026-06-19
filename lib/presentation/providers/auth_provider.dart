import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/worker_model.dart';
import 'core_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final WorkerModel? worker;

  const AuthState(this.status, [this.worker]);

  const AuthState.unknown() : this(AuthStatus.unknown);
  const AuthState.unauthenticated() : this(AuthStatus.unauthenticated);
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.unknown());

  final Ref _ref;

  /// Called on startup: if we have a token, validate it by fetching the profile.
  Future<void> bootstrap() async {
    final storage = _ref.read(tokenStorageProvider);
    if (!await storage.hasToken) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final worker = await _ref.read(authRepositoryProvider).me();
      state = AuthState(AuthStatus.authenticated, worker);
    } catch (_) {
      await storage.clear();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String workerId, String pin) async {
    final worker = await _ref.read(authRepositoryProvider).login(workerId, pin);
    state = AuthState(AuthStatus.authenticated, worker);
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }

  /// Triggered by the API client when a token refresh fails.
  Future<void> forceLogout() async {
    await _ref.read(tokenStorageProvider).clear();
    state = const AuthState.unauthenticated();
  }
}

/// Convenience: the currently signed-in worker (or null).
final currentWorkerProvider =
    Provider<WorkerModel?>((ref) => ref.watch(authProvider).worker);
