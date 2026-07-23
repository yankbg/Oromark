// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_discovery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$udpServiceHash() => r'21525bddae70c484dffc4b67fe0c7d4a3b4191ce';

/// Singleton UDP service for listening to broadcasts
///
/// Copied from [udpService].
@ProviderFor(udpService)
final udpServiceProvider = AutoDisposeProvider<UdpService>.internal(
  udpService,
  name: r'udpServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$udpServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UdpServiceRef = AutoDisposeProviderRef<UdpService>;
String _$discoveredSessionsHash() =>
    r'40a73cf967e2313e63deead76734c7ecde38a2b4';

/// Expose the discovered sessions
///
/// Copied from [discoveredSessions].
@ProviderFor(discoveredSessions)
final discoveredSessionsProvider =
    AutoDisposeFutureProvider<List<DetectedSession>>.internal(
      discoveredSessions,
      name: r'discoveredSessionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$discoveredSessionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiscoveredSessionsRef =
    AutoDisposeFutureProviderRef<List<DetectedSession>>;
String _$sessionDiscoveryNotifierHash() =>
    r'c5598e5bb1b3408106e536f5a1debe9ae878b380';

/// Manages discovered sessions state
///
/// Copied from [SessionDiscoveryNotifier].
@ProviderFor(SessionDiscoveryNotifier)
final sessionDiscoveryNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      SessionDiscoveryNotifier,
      List<DetectedSession>
    >.internal(
      SessionDiscoveryNotifier.new,
      name: r'sessionDiscoveryNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionDiscoveryNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SessionDiscoveryNotifier =
    AutoDisposeAsyncNotifier<List<DetectedSession>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
