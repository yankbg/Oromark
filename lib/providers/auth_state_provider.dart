// lib/providers/auth_state_provider.dart [FIXED]
//
// Riverpod provider that stores the currently logged-in user's authentication data.
// This is useful for displaying the lecturer's name, email, and other profile info
// across the app without passing it through navigation arguments.
//
// Usage:
//   final authState = ref.watch(authStateNotifierProvider);
//   authState.when(
//     data: (authResult) => Text('Welcome, ${authResult?.fullname}'),
//     loading: () => CircularProgressIndicator(),
//     error: (e, st) => Text('Error'),
//   )

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/data/models/auth_result.dart';

/// Stores the current logged-in user's authentication data
///
/// Set this after successful login:
///   ref.read(authStateNotifierProvider.notifier).setUser(authResult);
///
/// Read this anywhere in the app:
///   final authResult = ref.watch(authStateNotifierProvider);
class AuthStateNotifier extends StateNotifier<AsyncValue<AuthResult?>> {
  AuthStateNotifier() : super(const AsyncValue.data(null));

  /// Set the current user after successful login
  void setUser(AuthResult authResult) {
    state = AsyncValue.data(authResult);
  }

  /// Clear the user (logout)
  void clearUser() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for auth state management
final authStateNotifierProvider = StateNotifierProvider<
    AuthStateNotifier,
    AsyncValue<AuthResult?>
>((ref) => AuthStateNotifier());