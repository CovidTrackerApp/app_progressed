import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './BluetoothDeviceListEntry.dart';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';

final imgUrl =
    "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/csv/dummy.csv";

var dio = Dio();

class DiscoveryPage extends StatefulWidget {
  /// If true, discovery starts on page start, otherwise user must press action button.
  final bool start;

  const DiscoveryPage({this.start = true});

  @override
  _DiscoveryPage createState() => new _DiscoveryPage();
}

class _DiscoveryPage extends State<DiscoveryPage> {
  double distanceUp;
  String deviceID = "";
  double previous = 0.0;
  List<List<dynamic>> rows = List<List<dynamic>>();
  void startServiceInPlatform() async {
    if (Platform.isAndroid) {
      var methodChannel = MethodChannel("com.retroportalstudio.messages");
      String data = await methodChannel.invokeMethod("startService");
      //  debugPrint(data);
    }
  }

  void getPermission() async {
    //   print("getPermission");
    final PermissionHandler _permissionHandler = PermissionHandler();
    var permissions =
        await _permissionHandler.requestPermissions([PermissionGroup.storage]);

//    Map<PermissionGroup, PermissionStatus> permissions =
//        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }

  Future download2(Dio dio, String url, String savePath) async {
    try {
      Response response = await dio.get(
        url,
        onReceiveProgress: showDownloadProgress,
        //Received data with List<int>
        options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status < 500;
            }),
      );
      //  print(response.headers);
      File file = File(savePath);

      List<dynamic> row = List();

      if (distanceUp != previous && distanceUp != null) {
        var now = new DateTime.now();
        previous = distanceUp;
        row.add(deviceID);
        row.add(distanceUp);
        row.add(now);

        rows.add(row);
        //  print("hello");
      }

//      }
//      String csv = const ListToCsvConverter().convert(rows);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);
      String csv = const ListToCsvConverter().convert(rows);
      file.writeAsString(csv);

      //file.writeAsString(g);
      await raf.close();
    } catch (e) {
      //  print(e);
    }
    processLines(List<String> lines) {
      for (var line in lines) {
        //    print(line);
      }
    }
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      //   print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }

  void downloadcsvfile() async {
    String path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);
    //String fullPath = tempDir.path + "/boo2.pdf'";
    String fullPath = "$path/user1.csv";
    // print('full path ${fullPath}');
    download2(dio, imgUrl, fullPath);
  }

  StreamSubscription<BluetoothDiscoveryResult> _streamSubscription;
  List<BluetoothDiscoveryResult> results = List<BluetoothDiscoveryResult>();
  bool isDiscovering;

  _DiscoveryPage();

  @override
  void initState() {
    getPermission();
    super.initState();

    isDiscovering = widget.start;
    if (isDiscovering) {
      _startDiscovery();
    }
  }

  void _restartDiscovery() {
    setState(() {
      results.clear();
      isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        results.add(r);
      });
    });

    _streamSubscription.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  // @TODO . One day there should be `_pairDevice` on long tap on something... ;)

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    downloadcsvfile();
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Colors.red, Colors.blue])),
        ),
        title: isDiscovering
            ? Text('Discovering devices')
            : Text('Discovered devices'),
        actions: <Widget>[
          isDiscovering
              ? FittedBox(
                  child: Container(
                    margin: new EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.replay),
                  onPressed: _restartDiscovery,
                )
        ],
      ),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (BuildContext context, index) {
          BluetoothDiscoveryResult result = results[index];

          double temp = 0.0;
          double distance = 0.0;
          temp = ((-69 - (result.rssi.toDouble())) / (10 * 2));
          distance = pow(10, temp);
          distanceUp = distance;
          deviceID = result.device.address;

          return BluetoothDeviceListEntry(
            device: result.device,
            rssi: distance,
            onTap: () {
              Navigator.of(context).pop(result.device);
            },
            onLongPress: () async {
              try {
                bool bonded = false;
                if (result.device.isBonded) {
                  //   print('Unbonding from ${result.device.address}...');
                  await FlutterBluetoothSerial.instance
                      .removeDeviceBondWithAddress(result.device.address);
                  //    print('Unbonding from ${result.device.address} has succed');
                } else {
                  //   print('Bonding with ${result.device.address}...');
                  bonded = await FlutterBluetoothSerial.instance
                      .bondDeviceAtAddress(result.device.address);
                  //    print('Bonding with ${result.device.address} has ${bonded ? 'succed' : 'failed'}.');
                }
                setState(() {
                  // Distance = 10 ^ ((Measured Power — RSSI)/(10 * N))

                  results[results.indexOf(result)] = BluetoothDiscoveryResult(
                      device: BluetoothDevice(
                        name: result.device.name ?? '',
                        address: result.device.address,
                        type: result.device.type,
                        bondState: bonded
                            ? BluetoothBondState.bonded
                            : BluetoothBondState.none,
                      ),
                      rssi: result.rssi);
                });
              } catch (ex) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Error occured while bonding'),
                      content: Text("${ex.toString()}"),
                      actions: <Widget>[
                        new FlatButton(
                          child: new Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}
