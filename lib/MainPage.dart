import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './DiscoveryPage.dart';
import './BackgroundCollectingTask.dart';
import 'package:cron/cron.dart';
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask _collectingTask;

  bool _autoAcceptPairingRequests = false;
  Timer _timer;
  int _start = 5;
  void getPermission() async {
    print("getPermission");
    final PermissionHandler _permissionHandler = PermissionHandler();
    var permissions =
        await _permissionHandler.requestPermissions([PermissionGroup.storage]);
  }

  @override
  void initState() {
    super.initState();
    getPermission();
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    _timer.cancel();
    super.dispose();
  }

  var cron = new Cron();
  void UploadDataAtSpecificTime() {
    setState(() {
      TimeOfDay now = TimeOfDay.now();
      print(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    cron.schedule(new Schedule.parse('36 14 * * *'), () async {
      UploadDataAtSpecificTime();
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Social Distancing via Bluetooth App"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Colors.red, Colors.blue])),
        ),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Divider(),
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            Divider(),
            ListTile(
              title: RaisedButton(
                  child: const Text('Explore discovered devices'),
                  onPressed: () async {
                    final BluetoothDevice selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return DiscoveryPage();
                        },
                      ),
                    );

                    if (selectedDevice != null) {
                      print('Discovery -> selected ' + selectedDevice.address);
                    } else {
                      print('Discovery -> no device selected');
                    }
                  }),
            ),
            ListTile(
              title: RaisedButton(
                child: Text(
                  'Check My Status',
                  //style: TextStyle(fontSize: 24.0),
                ),
                onPressed: () {
                  _checkPatients("sadas");
                },
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }

  // void _checkPatients(BuildContext context) {
  //   Navigator.of(context)
  //       .push(MaterialPageRoute(builder: (context) => scaneList()));
  // }
  _checkPatients(userId) async {
    var url = Uri.http('52.74.221.135:5000', '/login/alifurqan');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var itemCount = jsonResponse;
      if (itemCount != null) {
        print('Here is the returned data: $itemCount.');
        return 0;
      } else {
        print('Here is the returned data: $itemCount.');
        // print('Login successful with status: ${response.statusCode}.');
        return 1;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return 2;
    }
  }
}

class scaneList extends StatefulWidget {
  @override
  _NewScaning createState() => new _NewScaning();
}

final imgUrl =
    "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/csv/dummy.csv";

var dio = Dio();

class _NewScaning extends State<scaneList> {
  List<String> _patient_Ids = [];
  List<String> _user_Ids = [];
  List<double> _user_distance = [];
  List<String> li = [];
  final List<String> message = [];
  List<List<dynamic>> rows = List<List<dynamic>>();
  void startServiceInPlatform() async {
    if (Platform.isAndroid) {
      var methodChannel = MethodChannel("com.retroportalstudio.messages");
      String data = await methodChannel.invokeMethod("startService");
      debugPrint(data);
    }
  }

  void _readData() async {
    // sleep(new Duration(seconds: 1));

    String path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);

    File patient = new File("$path/patients.csv");
    File user = new File("$path/user1.csv");

    List<String> _patientIds = patient.readAsLinesSync();
    List<String> _usertIds = user.readAsLinesSync();

    // print("Patients IDs ");
    for (var id in _patientIds) {
      final split = id.split(',');
      final Map<int, String> values = {
        for (int i = 0; i < split.length; i++) i: split[i]
      };
      //  print(values);  // {0: ids, 1:  distance, 2: time}
      _patient_Ids.add(values[0]);
    }

    // print("User IDs List");
    for (var id in _usertIds) {
      final split = id.split(',');
      final Map<int, String> values = {
        for (int i = 0; i < split.length; i++) i: split[i]
      };
      //  print(values);  // {0: ids, 1:  distance, 2: time}
      _user_Ids.add(values[0]);
      //  print(values[0]);
      _user_distance.add(double.parse(values[1]));
    }
  }

  void _scanning() {
    Stopwatch s = new Stopwatch();
    s.start();
    bool a = false;
    for (int i = 0; i < _patient_Ids.length; i++) {
      for (int j = 0; j < _user_Ids.length; j++) {
        int check = _patient_Ids[i].compareTo(_user_Ids[j]);

        if (check == 0) {
          a = true;
        }
      }
    }
    setState(() {
      textWidgetList.clear();
    });
    if (a) {
      setState(() {
        textWidgetList.add(
          Container(
            child: Column(children: <Widget>[
              CircularButton(),
            ]),
          ),
        );
      });
    } else {
      setState(() {
        textWidgetList.add(
          Container(
            child: Column(children: <Widget>[
              successful(),
            ]),
          ),
        );
      });
    }

    s.reset();
  }

//we are initializing state of Acceleroscope and Gyroscope values

  List<Widget> textWidgetList = List<Widget>();

  @override
  Widget build(BuildContext context) {
    _readData();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Social Distancing via Bluetooth App"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Colors.red, Colors.blue])),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: 580,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/mybackground.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
              child: Column(
            children: <Widget>[
              Container(
                height: 500.0,
                child: Column(
                  children: textWidgetList,
                ),
              ),
              Container(
                height: 45.0,
                color: Colors.cyan,
                child: RaisedButton(
                  color: Colors.blue,
                  onPressed: () => _scanning(),
                  child: Text(
                    'Scane My Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class CircularButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Stack(
        children: <Widget>[
          Positioned(
              right: 150,
              top: 10,
              child: ClipOval(
                child: Container(
                  color: Colors.grey,
                  height: 20.0, // height of the button
                  width: 20.0, // width of the button
                ),
              )),
          Center(
              child: ClipOval(
            child: Container(
              color: Colors.grey,
              height: 150.0, // height of the button
              width: 150.0, // width of the button
            ),
          )),
          Center(
              child: GestureDetector(
            onTap: () {},
            child: ClipOval(
              child: Container(
                //color: Colors.green,
                height: 120.0, // height of the button
                width: 120.0, // width of the button
                decoration: BoxDecoration(
                    color: Colors.red,
                    border: Border.all(
                        color: Colors.white,
                        width: 10.0,
                        style: BorderStyle.solid),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey,
                          offset: Offset(21.0, 10.0),
                          blurRadius: 35.0,
                          spreadRadius: 55.0)
                    ],
                    shape: BoxShape.circle),
                child: Center(
                    child: Text('       Go to\n   Quarantine',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.6)))),
              ),
            ),
          )),
          Positioned(
              top: 10,
              left: 10,
              child: ClipOval(
                child: Container(
                  color: Colors.grey,
                  height: 30.0, // height of the button
                  width: 30.0, // width of the button
                ),
              )),
          Positioned(
              top: 50,
              left: 50,
              child: ClipOval(
                child: Container(
                  color: Colors.grey,
                  height: 20.0, // height of the button
                  width: 20.0, // width of the button
                ),
              )),
          Positioned(
              bottom: 50,
              right: 50,
              child: ClipOval(
                child: Container(
                  color: Colors.grey,
                  height: 15.0, // height of the button
                  width: 15.0, // width of the button
                ),
              )),
        ],
      ),
    );
  }
}

class successful extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Stack(
        children: <Widget>[
          Positioned(
              right: 150,
              top: 10,
              child: ClipOval(
                child: Container(
                  color: Colors.grey,
                  height: 20.0, // height of the button
                  width: 20.0, // width of the button
                ),
              )),
          Center(
              child: ClipOval(
            child: Container(
              color: Colors.grey,
              height: 150.0, // height of the button
              width: 150.0, // width of the button
            ),
          )),
          Center(
              child: GestureDetector(
            onTap: () {},
            child: ClipOval(
              child: Container(
                //color: Colors.green,
                height: 120.0, // height of the button
                width: 120.0, // width of the button
                decoration: BoxDecoration(
                    color: Colors.green,
                    border: Border.all(
                        color: Colors.white,
                        width: 10.0,
                        style: BorderStyle.solid),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey,
                          offset: Offset(21.0, 10.0),
                          blurRadius: 20.0,
                          spreadRadius: 40.0)
                    ],
                    shape: BoxShape.circle),
                child: Center(
                    child: Text('   No Patient \n      Found',
                        style:
                            TextStyle(color: Colors.white.withOpacity(0.6)))),
              ),
            ),
          )),
          Positioned(
              top: 10,
              left: 10,
              child: ClipOval(
                child: Container(
                  color: Colors.grey,
                  height: 30.0, // height of the button
                  width: 30.0, // width of the button
                ),
              )),
          Positioned(
              top: 50,
              left: 50,
              child: ClipOval(
                child: Container(
                  color: Colors.grey,
                  height: 20.0, // height of the button
                  width: 20.0, // width of the button
                ),
              )),
          Positioned(
              bottom: 50,
              right: 50,
              child: ClipOval(
                child: Container(
                  color: Colors.grey,
                  height: 15.0, // height of the button
                  width: 15.0, // width of the button
                ),
              )),
        ],
      ),
    );
  }
}
