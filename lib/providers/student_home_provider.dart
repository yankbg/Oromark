import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/data/database/app_database.dart';
import 'package:oromark/data/services/udp_service.dart';
import 'package:oromark/presentation/student/home/student_home_controller.dart';
import 'package:oromark/providers/udp_service_provider.dart';

import 'app_database_provider.dart';

final studentHomeControllerProvider =
ChangeNotifierProvider<StudentHomeController>((ref) {
  final udpService = ref.read(udpServiceProvider);
  final db = ref.read(appDatabaseProvider);

  throw UnimplementedError(
    'StudentHomeController needs TickerProvider from the screen, '
        'so create it inside StudentHomeScreen instead.',
  );
});