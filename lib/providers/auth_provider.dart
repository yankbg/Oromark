//Holds the currently logged-in user from Supabase Auth

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

// Watches Supabase auth state changes
// Returns the current User or null if logged out
@riverpod
Stream<User?> auth(AuthRef ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
        (event) => event.session?.user,
  );
}