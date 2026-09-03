import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/ble_service.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  return BleService();
});
