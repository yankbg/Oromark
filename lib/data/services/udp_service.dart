//most critical file in the project. handles udp broadcast

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:oromark/core/constants/network_constants.dart';
import 'package:network_info_plus/network_info_plus.dart';

class UdpService {
  RawDatagramSocket? _socket;
  bool _isListening = false;
  Timer? _timer;

  // Track current broadcast interval to detect when to switch
  int _currentInterval = NetworkConstants.broadcastIntervalPresent;

  // Store session data for re-broadcast on interval switch
  Map<String, dynamic>? _sessionData;

  Future<void> startListening(Function(Map<String, dynamic>) onSessionReceived) async{
    if(_isListening) return;
    try{
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, NetworkConstants.udpPort);
      _socket!.broadcastEnabled = true;
      _socket!.readEventsEnabled = true;
      _isListening = true;

      _socket!.listen((event) {
        print('[UDP_SERVICE] thi is event in listener ${event}');
        if(event == RawSocketEvent.read) {
          Datagram? dg = _socket!.receive();
          print('[UDP_SERVICE] this is dg ${dg}');
          if(dg != null) {
            try{
              // Decode UDP packet
              String message = utf8.decode(dg.data);
              Map<String, dynamic> sessionData = jsonDecode(message);
              onSessionReceived(sessionData);
              print('[UDP_SERVICE] session detected ${sessionData}');
            }catch(e){
              print('[UDP_SERVICE] Error parsing UDP packet: $e');
            }
          }
        }

      });
      print('[UDP_SERVICE] UDP listener started on port ${NetworkConstants.udpPort}');
    }catch(e){
      print('[UDP_SERVICE] Error starting UDP listener: $e');
      _isListening = false;
      rethrow;
    }



  }
  void switchToLateInterval() {
    // TODO: implement changing interval
    if (_timer == null || _currentInterval == NetworkConstants.broadcastIntervalLate) {
      // Already at late interval, or not broadcasting
      return;
    }

    try {
      // Cancel existing timer
      _timer?.cancel();
      _timer = null;

      // Start new timer with late interval
      _currentInterval = NetworkConstants.broadcastIntervalLate;

      // Re-broadcast with new interval
      if (_sessionData != null) {
        String message = jsonEncode(_sessionData);
        List<int> data = utf8.encode(message);

        _timer = Timer.periodic(
          Duration(seconds: _currentInterval),
              (timer) {
            try {
              _socket!.send(
                data,
                InternetAddress(NetworkConstants.broadcastAddress),
                NetworkConstants.udpPort,
              );
            } catch (e) {
              print('[UDP_SERVICE] Error broadcasting UDP packet (late interval): $e');
            }
          },
        );
      }

      print(
        '[UDP_SERVICE] Switched to late broadcast interval: '
            '${NetworkConstants.broadcastIntervalPresent}s → ${NetworkConstants.broadcastIntervalLate}s '
            '(battery savings: ~80%)',
      );
    } catch (e) {
      print('[UDP_SERVICE] Error switching to late interval: $e');
    }
  }

  Future<void> startBroadcasting(Map<String, dynamic> sessionData) async{
    if (_timer != null) return;
    try{
      // Store session data for re-use in switchToLateInterval
      _sessionData = sessionData;
      // Bind to any local IP (system chooses), OS picks random port
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;

      // Encode session data as JSON
      String message = jsonEncode(sessionData);
      List<int> data = utf8.encode(message);
      final broadcastAddress = await getBroadcastAddress();

      // Start periodic broadcast at PRESENT interval
      // _currentInterval = NetworkConstants.broadcastIntervalPresent;
      // _timer = Timer.periodic(Duration(seconds: NetworkConstants.broadcastIntervalPresent), (timer) {
      //   _socket!.send(data, InternetAddress(NetworkConstants.broadcastAddress), NetworkConstants.udpPort);
      // });
      _timer = Timer.periodic(
        Duration(seconds: _currentInterval),
            (timer) {
          try {
            _socket!.send(
              data,
              InternetAddress(broadcastAddress),
              NetworkConstants.udpPort,
            );
          } catch (e) {
            print('[UDP_SERVICE] Error broadcasting UDP packet: $e');
          }
        },
      );
      print(
        '[UDP_SERVICE] UDP broadcast started: interval ${_currentInterval}s, '
            'address $broadcastAddress:${NetworkConstants.udpPort}',
      );

    }catch(e){
      print('[UDP_SERVICE] Error starting UDP broadcast: $e');
      _timer = null;
      rethrow;
    }

  }
  void stopBroadcasting() {

    try{
      _timer?.cancel();
      _timer = null;
      _socket?.close();
      _socket = null;
      // _isListening = false;
      _currentInterval = NetworkConstants.broadcastIntervalPresent;
      _sessionData = null;
      print('[UDP_SERVICE] UDP broadcast stopped');
    }catch(e){
      print('[UDP_SERVICE] Error stopping UDP broadcast: $e');
    }
  }
  void stopListening() {
    try {
      _socket?.close();
      _socket = null;
      _isListening = false;

      print('[UDP_SERVICE] UDP listener stopped');
    } catch (e) {
      print('[UDP_SERVICE] Error stopping UDP listener: $e');
    }
  }

  /// Returns true if currently listening for broadcasts
  bool get isListening => _isListening;

  /// Returns true if currently broadcasting
  bool get isBroadcasting => _timer != null;

  /// Returns current broadcast interval in seconds
  int get currentInterval => _currentInterval;

  Future<String> getBroadcastAddress() async {
    final info = NetworkInfo();
    final broadcast = await info.getWifiBroadcast();

    if (broadcast == null || broadcast.isEmpty) {
      throw Exception('Could not get Wi-Fi broadcast address');
    }

    return broadcast;
  }
}