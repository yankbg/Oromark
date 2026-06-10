import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/http_server_service.dart';

final httpServerProvider = Provider<HttpServerService>((ref) {
  return HttpServerService();
});