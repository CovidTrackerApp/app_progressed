import 'package:flutter/material.dart';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:convert/convert.dart';

//transmitter
Future<void> onPressed() async {
  if (broadcasting) {
    await flutterBeacon.stopBroadcast();
  } else {
    String uu=await getuuid();

    print("***********************************************************");
    print("Hello, this is uuid being broadcasted: ${uu}");
    print("***********************************************************");
    await flutterBeacon.startBroadcast(BeaconBroadcast(
      proximityUUID: uu,
      major: int.tryParse(majorController.text) ?? 0,
      minor: int.tryParse(minorController.text) ?? 0,
    ));
  }
}

//**************************************************************/
final clearFocus = FocusNode();
bool broadcasting = false;

final regexUUID = RegExp(r'[0-90-90-0]{8}');
final uuidController = TextEditingController(text: '00000006');
final majorController = TextEditingController(text: '0');
final minorController = TextEditingController(text: '0');


@override
void initState() {
  initBroadcastBeacon();
}

initBroadcastBeacon() async {
  await flutterBeacon.initializeScanning;
}

@override
void dispose() {
  clearFocus.dispose();
}

Future<String> getuuid() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //Return String
  String stringValue = prefs.getString('stringValue');
  return stringValue;
}