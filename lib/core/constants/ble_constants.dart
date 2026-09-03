// lib/core/constants/ble_constants.dart
//
// Constants for the BLE proximity gate (see data/services/ble_service.dart).
class BleConstants {
  // A fixed v4 UUID scoping BLE discovery to this app's own advertisements.
  // Not a registered Bluetooth SIG service — just a private identifier so
  // scans only pick up other Oromark devices, not random nearby BLE gear.
  static const String serviceUuid = '7c9f3a2e-4b1d-4e6a-9c8f-2d5b7e1a9f3c';

  // 0xFFFF is the Bluetooth SIG's reserved "for testing only" manufacturer
  // ID. Fine here since the service UUID above already scopes matches to
  // this app — this is not a publicly distributed BLE product.
  static const int manufacturerId = 0xFFFF;

  // Bytes of the sha256(sessionId) token carried in the advertisement.
  static const int tokenLength = 4;

  static const Duration scanTimeout = Duration(seconds: 5);
}
