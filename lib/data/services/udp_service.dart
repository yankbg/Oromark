//most critical file in the project. handles udp broadcast

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:oromark/core/constants/network_constants.dart';

class UdpService {
  RawDatagramSocket? _socket;
  bool _isListening = false;
  Timer? _timer;

  Future<void> startListening(Function(Map<String, dynamic>) onSessionReceived) async{
    if(_isListening) return;

    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, NetworkConstants.udpPort);
    _isListening = true;

    _socket!.listen((event) {

      if(event == RawSocketEvent.read) {
        Datagram? dg = _socket!.receive();
        if(dg != null) {
          try{
            String message = utf8.decode(dg.data);
            Map<String, dynamic> sessionData = jsonDecode(message);
            onSessionReceived(sessionData);
          }catch(e){
            print('Error parsing UDP packet: $e');
          }
        }
      }

    });
  }

  Future<void> startBroadcasting(Map<String, dynamic> sessionData) async{
    if (_timer != null) return;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    String message = jsonEncode(sessionData);
    List<int> data = utf8.encode(message);

    _timer = Timer.periodic(Duration(seconds: NetworkConstants.broadcastIntervalPresent), (timer) {
      _socket!.send(data, InternetAddress(NetworkConstants.broadcastAddress), NetworkConstants.udpPort);
    });
  }
  void stopBroadcasting() {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
    _isListening = false;
  }


}