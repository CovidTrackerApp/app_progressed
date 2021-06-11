import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';

import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
import './ChatPage.dart';
import './BackgroundCollectingTask.dart';
import './BackgroundCollectedPage.dart';
import 'package:cron/cron.dart';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';

// Import package
//import 'package:battery/battery_info.dart';
//import 'package:battery_info/model/android_battery_info.dart';
//import 'package:battery_info/enums/charging_status.dart';
//import 'package:battery_info/model/iso_battery_info.dart';

// import './helpers/LineChart.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  // List<int> options = <int>[5,12];
  // int dropdownValue = 5;

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

//    Map<PermissionGroup, PermissionStatus> permissions =
//        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }
/*
  void UploadData() {
    _start = dropdownValue;
    int b=0;
    setState(() {


      if (_timer != null) {
      _timer.cancel();
      _timer = null;
      } else {
      _timer = new Timer.periodic(
        const Duration(seconds: 1),
        (Timer timer) => setState(
          () {
            if (_start < 1) {
              _start = dropdownValue;
             // timer.cancel();
            } else {
              TimeOfDay now = TimeOfDay.now();
              TimeOfDay releaseTime = TimeOfDay(hour: 23, minute: 59);
              String ti = now.toString();
              String mi = releaseTime.toString();

             int a = ti.compareTo(mi);
              if(a==0 && b==0 && dropdownValue==12){

                  print(ti);
                  print(mi);
                  b++;

               // _start = _start - 1;
              }
              print(_start);
              _start = _start - 1;
            }
          },
        ),
      );
    }

});

  }
  */

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
            /*    ListTile(
              title: const Text('Bluetooth Status'),
              subtitle: Text(_bluetoothState.toString()),
              trailing: RaisedButton(
                child: const Text('Settings'),
                onPressed: () {
                  FlutterBluetoothSerial.instance.openSettings();
                },
              ),
            ),
            ListTile(
              title: const Text('Local adapter address'),
              subtitle: Text(_address),
            ),
            ListTile(
              title: const Text('Local adapter name'),
              subtitle: Text(_name),
              onLongPress: null,
            ),
            ListTile(
              title: _discoverableTimeoutSecondsLeft == 0
                  ? const Text("Discoverable")
                  : Text(
                      "Discoverable for ${_discoverableTimeoutSecondsLeft}s"),
              subtitle: const Text("PsychoX-Luna"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _discoverableTimeoutSecondsLeft != 0,
                    onChanged: null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      print('Discoverable requested');
                      final int timeout = await FlutterBluetoothSerial.instance
                          .requestDiscoverable(60);
                      if (timeout < 0) {
                        print('Discoverable mode denied');
                      } else {
                        print(
                            'Discoverable mode acquired for $timeout seconds');
                      }
                      setState(() {
                        _discoverableTimeoutTimer?.cancel();
                        _discoverableTimeoutSecondsLeft = timeout;
                        _discoverableTimeoutTimer =
                            Timer.periodic(Duration(seconds: 1), (Timer timer) {
                          setState(() {
                            if (_discoverableTimeoutSecondsLeft < 0) {
                              FlutterBluetoothSerial.instance.isDiscoverable
                                  .then((isDiscoverable) {
                                if (isDiscoverable) {
                                  print(
                                      "Discoverable after timeout... might be infinity timeout :F");
                                  _discoverableTimeoutSecondsLeft += 1;
                                }
                              });
                              timer.cancel();
                              _discoverableTimeoutSecondsLeft = 0;
                            } else {
                              _discoverableTimeoutSecondsLeft -= 1;
                            }
                          });
                        });
                      });
                    },
                  )
                ],
              ),
            ),*/
            Divider(),
            /*     ListTile(title: const Text('Devices discovery and connection')),
            SwitchListTile(
              title: const Text('Auto-try specific pin when pairing'),
              subtitle: const Text('Pin 1234'),
              value: _autoAcceptPairingRequests,
              onChanged: (bool value) {
                setState(() {
                  _autoAcceptPairingRequests = value;
                });
                if (value) {
                  FlutterBluetoothSerial.instance.setPairingRequestHandler(
                      (BluetoothPairingRequest request) {
                    print("Trying to auto-pair with Pin 1234");
                    if (request.pairingVariant == PairingVariant.Pin) {
                      return Future.value("1234");
                    }
                    return null;
                  });
                } else {
                  FlutterBluetoothSerial.instance
                      .setPairingRequestHandler(null);
                }
              },
            ),*/
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
                  _checkPatients(context);
                },
              ),
            ),

            /*   ListTile(
              title: RaisedButton(
                child: const Text('Connect to paired device to chat'),
                onPressed: () async {
                  final BluetoothDevice selectedDevice =
                      await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectBondedDevicePage(checkAvailability: false);
                      },
                    ),
                  );

                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    _startChat(context, selectedDevice);
                  } else {
                    print('Connect -> no device selected');
                  }
                },
              ),
            ),*/
            Divider(),
            /*    Text("Select Time for Uploading"),
            SizedBox(
              height: 20.0,
            ),
            Container(
              height: 40.0,
              width: 40.0,
              margin: const EdgeInsets.fromLTRB(15, 5, 280, 25),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(8.0),
              color: Colors.blue[600],
              child: DropdownButton<int>(
                value: dropdownValue,
                onChanged: (int newValue) {
                  setState(() {
                    dropdownValue = newValue;
                    UploadData();
                  });
                },
                style: const TextStyle(color: Colors.blue),
                selectedItemBuilder: (BuildContext context) {
                  return options.map((int value) {
                    return Text(
                      dropdownValue.toString(),
                      style: const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
                items: options.map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
              ),
            ),
           // Text(dropdownValue.toString()),
            */

            // Text("$_start"),
/*
            ListTile(title: const Text('Multiple connections example')),
            ListTile(
              title: RaisedButton(
                child: ((_collectingTask != null && _collectingTask.inProgress)
                    ? const Text('Disconnect and stop background collecting')
                    : const Text('Connect to start background collecting')),
                onPressed: () async {
                  if (_collectingTask != null && _collectingTask.inProgress) {
                    await _collectingTask.cancel();
                    setState(() {
                      /* Update for `_collectingTask.inProgress` */
                    });
                  } else {
                    final BluetoothDevice selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return SelectBondedDevicePage(
                              checkAvailability: false);
                        },
                      ),
                    );

                    if (selectedDevice != null) {
                      await _startBackgroundTask(context, selectedDevice);
                      setState(() {
                        /* Update for `_collectingTask.inProgress` */
                      });
                    }
                  }
                },
              ),
            ),*/
            /*   ListTile(
              title: RaisedButton(
                child: const Text('View background collected data'),
                onPressed: (_collectingTask != null)
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return ScopedModel<BackgroundCollectingTask>(
                                model: _collectingTask,
                                child: BackgroundCollectedPage(),
                              );
                            },
                          ),
                        );
                      }
                    : null,
              ),
            ),*/
          ],
        ),
      ),
    );
  }

/*
  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }

  Future<void> _startBackgroundTask(
    BuildContext context,
    BluetoothDevice server,
  ) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask.start();
    } catch (ex) {
      if (_collectingTask != null) {
        _collectingTask.cancel();
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
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
  }*/
  void _checkPatients(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => scaneList()));
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
  List<int> _patient_Ids = [];
  List<int> _user_Ids = [];
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
    int a = 0;
    // print("Patients IDs ");
    for (var id in _patientIds) {
      //print(li);
      _patient_Ids.add(int.parse(id));
      //print(lines.length);
      //   print(_patient_Ids[a]);
      a++;
    }

    a = 0;
    // print("User IDs List");
    for (var id in _usertIds) {
      final split = id.split(',');
      final Map<int, String> values = {
        for (int i = 0; i < split.length; i++) i: split[i]
      };
      //  print(values);  // {0: ids, 1:  distance, 2: time}
      _user_Ids.add(int.parse(values[0]));
      _user_distance.add(double.parse(values[1]));

      // final value3 = values[2]; // dates
      // print(_user_Ids[a]);
      //print(value3);

      a++;
    }
  }

  void _scanning() {
    Stopwatch s = new Stopwatch();
    s.start();
    bool a = false;
    for (int i = 0; i < _patient_Ids.length; i++) {
      for (int j = 0; j < _user_Ids.length; j++) {
        if ((_patient_Ids[i] == _user_Ids[j]) && (_user_distance[j] <= 2)) {
          a = true;
        }
      }
    }

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
          child: Column(
            children: <Widget>[
              Column(
                children: textWidgetList,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanning(),
        tooltip: 'Search',
        child: Icon(Icons.replay),
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
