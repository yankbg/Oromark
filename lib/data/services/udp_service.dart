//most critical file in the project. handles udp broadcast

import 'dart:convert';
import 'dart:io';

import 'package:oromark/core/constants/network_constants.dart';

class UdpService {
  RawDatagramSocket? _socket;
  bool _isListening = false;

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
}