import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/worker_model.dart';
import 'core_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final WorkerModel? worker;

  /// Set when the session was restored from the device rather than confirmed
  /// with the server — the profile on screen may be a day old.
  final bool offline;

  /// Explains an unauthenticated state that was not the user's doing.
  final String? message;

  const AuthState(this.status,
      [this.worker, this.offline = false, this.message]);

  const AuthState.unknown() : this(AuthStatus.unknown);
  const AuthState.unauthenticated({String? message})
      : this(AuthStatus.unauthenticated, null, false, message);
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.unknown());

  final Ref _ref;

  /// Called on startup.
  ///
  /// A token is only discarded when the server actually rejects it. A flat
  /// battery of a network — no signal, a timeout, a server that is down — must
  /// never sign a health worker out: they may be days from the next connection,
  /// and they cannot log back in without one.
  Future<void> bootstrap() async {
    final storage = _ref.read(tokenStorageProvider);
    if (!await storage.hasToken) {
      state = const AuthState.unauthenticated();
      return;
    }

    final repo = _ref.read(authRepositoryProvider);
    try {
      final worker = await repo.me();
      state = AuthState(AuthStatus.authenticated, worker);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        // The server rejected the token — this is a real sign-out.
        await storage.clear();
        state = const AuthState.unauthenticated(
            message: 'Your session expired. Please sign in again.');
        return;
      }
      // Unreachable or erroring server: keep the session and fall back to the
      // profile saved on the device.
      final cached = repo.cachedWorker();
      if (cached != null) {
        state = AuthState(AuthStatus.authenticated, cached, true);
      } else {
        state = AuthState.unauthenticated(message: e.message);
      }
    } catch (e) {
      final cached = repo.cachedWorker();
      state = cached != null
          ? AuthState(AuthStatus.authenticated, cached, true)
          : AuthState.unauthenticated(message: '$e');
    }
  }

  /// Re-confirm the profile with the server once a connection returns.
  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      final worker = await _ref.read(authRepositoryProvider).me();
      state = AuthState(AuthStatus.authenticated, worker);
    } catch (_) {
      // Still offline — keep what we have.
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

  /// Triggered by the API client when a token refresh is rejected.
  Future<void> forceLogout() async {
    await _ref.read(tokenStorageProvider).clear();
    state = const AuthState.unauthenticated(
        message: 'Your session expired. Please sign in again.');
  }
}

/// Convenience: the currently signed-in worker (or null).
final currentWorkerProvider =
    Provider<WorkerModel?>((ref) => ref.watch(authProvider).worker);

/// True when the session was restored from the device without reaching the
/// server.
final sessionIsOfflineProvider =
    Provider<bool>((ref) => ref.watch(authProvider).offline);
