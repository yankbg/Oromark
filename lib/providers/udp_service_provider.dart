import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/udp_service.dart';

final udpServiceProvider = Provider<UdpService>((ref) {
  return UdpService();
});