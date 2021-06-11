import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:sensors/sensors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'manual_bt_checker.dart';
import 'package:http/http.dart' as http;

import 'main.g.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:kdgaugeview/kdgaugeview.dart';

import 'package:flutter/widgets.dart';

import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import './MainPage.dart';

import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_blue/flutter_blue.dart';
import 'beacon_csv.dart';
import 'package:flutter_blue_beacon/flutter_blue_beacon.dart';
import 'app_broadcasting.dart';
import 'dart:convert';
import 'package:cron/cron.dart';

final imgUrl =
    "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/csv/dummy.csv";

var dio = Dio();
int i = 0;
int y = 0;


class DaterAdapter extends TypeAdapter<Dater> {
  @override
  final typeId = 0;

  @override
  Dater read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dater(
      longg: fields[0] as String,
      latt: fields[1] as String,
      altt: fields[2] as String,
      indexer: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Dater obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.longg)
      ..writeByte(1)
      ..write(obj.latt)
      ..writeByte(2)
      ..write(obj.altt)
      ..writeByte(3)
      ..write(obj.indexer);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterBackgroundService.initialize(onStart);
  runApp(MaterialApp(
    title: 'Navigation Basics',
    home: MyApp(),
  ));
}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();
  service.onDataReceived.listen((event) {
    if (event["action"] == "setAsForeground") {
      service.setForegroundMode(false);
      return;
    }
  });

  // bring to foreground
  service.setForegroundMode(true);
  Timer.periodic(Duration(seconds: 1), (timer) async {
    if (!(await service.isServiceRunning())) timer.cancel();
    service.setNotificationInfo(
      title: "My App Service",
      content: "Updated at ${DateTime.now()}",
    );

    service.sendData(
      {"current_date": DateTime.now().toIso8601String()},
    );
  });
}

class SecondRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage());
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCR_Lab_Plus',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'CCR_Lab_Plus'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //Transmitter

  //********************************************** */
  FlutterBlueBeacon flutterBlueBeacon = FlutterBlueBeacon.instance;
  FlutterBlue _flutterBlue = FlutterBlue.instance;

  /// Scanning
  StreamSubscription _scanSubscription;
  Map<int, Beacon> beacons = new Map();
  bool isScanning = false;

  /// State
  StreamSubscription _stateSubscription;
  BluetoothState state = BluetoothState.unknown;

  String g = "";
  String time1 = "";
  List<List<dynamic>> rows = List<List<dynamic>>();
  void startServiceInPlatform() async {
    if (Platform.isAndroid) {
      var methodChannel = MethodChannel("com.retroportalstudio.messages");
      String data = await methodChannel.invokeMethod("startService");
      //debugPrint(data);
    }
  }

  void getPermission() async {
    //  print("getPermission");
    final PermissionHandler _permissionHandler = PermissionHandler();
    var permissions =
        await _permissionHandler.requestPermissions([PermissionGroup.storage]);

//    Map<PermissionGroup, PermissionStatus> permissions =
//        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }

  /////////////////////////////////////////////////////////

  Future<int> _readIndicator() async {
    String text;
    int indicator;
    try {
      String path = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_DOCUMENTS);
      String fullPath = "$path/Sensor_Data1.csv";
      final File file = File(fullPath);
      text = await file.readAsString();
      // debugPrint("A file has been read at ${directory.path}");
      indicator = 1;
    } catch (e) {
      debugPrint("Couldn't read file");
      indicator = 0;
    }
    return indicator;
  }

  delay() {
    Future.delayed(Duration(seconds: 10));
  }

  void csvgenerator(String uuid, String distance) async {
    String dir = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOCUMENTS);
    print("dir $dir");
    String file = "$dir";

    var f = await File(file + "/Sensor_Data1.csv");
    int dd = await _readIndicator();
    if (dd == 1) {
      if (y == 0) {
        y = 1;
        print("**********************************************************");
        print("There is file!");
        print("**********************************************************");
        final csvFile = new File(file + "/Sensor_Data1.csv").openRead();
        var dat = await csvFile
            .transform(utf8.decoder)
            .transform(
              CsvToListConverter(),
            )
            .toList();

        List<List<dynamic>> rows = [];

        List<dynamic> row = [];
        for (int i = 0; i < dat.length; i++) {
          List<dynamic> row = [];
          row.add(dat[i][0]);
          row.add(dat[i][1]);
          row.add(dat[i][2]);
          row.add(dat[i][3]);
          row.add(dat[i][4]);
          row.add(dat[i][5]);
          row.add(dat[i][6]);
          row.add(dat[i][7]);
          row.add(dat[i][8]);
          row.add(dat[i][9]);
          row.add(dat[i][10]);
          row.add(dat[i][11]);

          print(
              "```````````````````````````````````````````````````````````````````````object```````````````````````````````````````````````````````````````````````");
          print(dat[i][0]);
          print(dat[i][1]);
          rows.add(row);
        }
        // for (int i = 0; i < dat.length; i++) {
        //   List<dynamic> row = [];
        //   row.add(dat[i][0]);
        //   row.add(dat[i][1]);
        //   row.add(dat[i][2]);
        //   row.add(dat[i][3]);
        //   row.add(dat[i][4]);
        //   rows.add(row);
        // }
        // row.add(uuid);
        // row.add(distance);
        String latt = pinLocation.latitude.toString();
        String longg = pinLocation.longitude.toString();
        String altt = pinLocation.altitude.toString();
        final List<String> gyroscope =
            _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
        final List<String> accelerometer = _accelerometerValues
            ?.map((double v) => v.toStringAsFixed(1))
            ?.toList();
        var now = new DateTime.now();
        var formatter = new DateFormat('dd-MM-yyyy');
        String time = DateFormat('Hms').format(now);
        String date = formatter.format(now);
        String speed = pinLocation.speed.toStringAsFixed(7);
        // row.add(accelerometer);
        // row.add(gyroscope);
        // row.add(latt);
        // row.add(longg);
        // rows.add(row);

        //String csver = const ListToCsvConverter().convert(rows);
        if (time != time1) {
          f.writeAsString(
              "$date,$time,$latt,$longg,$altt,$speed ,$accelerometer,$gyroscope" +
                  '\n',
              mode: FileMode.append,
              flush: true);
          time1 = time;
        }
        // for (int i = 0; i < 1000; i++) {}
      } else {
        // final cron = Cron()
        //   ..schedule(Schedule.parse('*/1 * * * * *'), () {
        //     print(DateTime.now());
        //   });
        //await Future.delayed(Duration(seconds: 100));
        // List<List<dynamic>> rows = [];

        // List<dynamic> row = [];
        // row.add(uuid);
        // row.add(distance);

        // rows.add(row);

        // String csv = const ListToCsvConverter().convert(rows);
        String latt = pinLocation.latitude.toString();
        String longg = pinLocation.longitude.toString();
        String altt = pinLocation.altitude.toString();
        final List<String> gyroscope =
            _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
        final List<String> accelerometer = _accelerometerValues
            ?.map((double v) => v.toStringAsFixed(1))
            ?.toList();
        var now = new DateTime.now();
        var formatter = new DateFormat('dd-MM-yyyy');
        String time = DateFormat('Hms').format(now);
        String date = formatter.format(now);
        String speed = pinLocation.speed.toStringAsFixed(7);
        if (time1 != time) {
          f.writeAsString(
              "$date,$time,$latt,$longg,$altt,$speed,$accelerometer,$gyroscope" +
                  '\n',
              mode: FileMode.append,
              flush: true);
          time1 = time;
        }
      }
    } else {
      // List<List<dynamic>> rows = [];

      // List<dynamic> row = [];
      // row.add(uuid);
      // row.add(distance);

      // rows.add(row);

      // String csv = const ListToCsvConverter().convert(rows);
      String latt = pinLocation.latitude.toString();
      String longg = pinLocation.longitude.toString();
      String altt = pinLocation.altitude.toString();
      final List<String> gyroscope =
          _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
      final List<String> accelerometer = _accelerometerValues
          ?.map((double v) => v.toStringAsFixed(1))
          ?.toList();
      var now = new DateTime.now();
      var formatter = new DateFormat('dd-MM-yyyy');
      String time = DateFormat('Hms').format(now);
      String date = formatter.format(now);
      String speed = pinLocation.speed.toStringAsFixed(7);
      if (time1 != time) {
        f.writeAsString(
            "$date,$time,$latt,$longg,$altt,$speed,$accelerometer,$gyroscope" +
                '\n',
            mode: FileMode.append,
            flush: true);
        time1 = time;
      }
      // for (int i = 0; i < 1000; i++) {}
    }
  }

//////////////////////////////////////////////////////////////////
//   File file = File("Sensor.csv");
//   var raf;
//   Future download2(Dio dio, String url, String savePath) async {
//     try {
//       Response response = await dio.get(
//         url,
//         onReceiveProgress: showDownloadProgress,
//         //Received data with List<int>
//         options: Options(
//             responseType: ResponseType.bytes,
//             followRedirects: false,
//             validateStatus: (status) {
//               return status < 500;
//             }),
//       );
//       //  print(response.headers);
//       file = File(savePath);

//       String latt = pinLocation.latitude.toString();
//       String longg = pinLocation.longitude.toString();
//       String altt = pinLocation.altitude.toString();
//       final List<String> gyroscope =
//           _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
//       final List<String> accelerometer = _accelerometerValues
//           ?.map((double v) => v.toStringAsFixed(1))
//           ?.toList();
//       String time = DateFormat.Hms()
//           .format(
//               DateTime.fromMillisecondsSinceEpoch((pinLocation.time).round()))
//           .toString();
//       String date = DateFormat.yMMMd()
//           .format(
//               DateTime.fromMillisecondsSinceEpoch((pinLocation.time).round()))
//           .toString();
//       String speed = pinLocation.speed.toStringAsFixed(7);
//       // print(speed);
//       //var speed1 = double.parse(speed.toStringAsFixed(2));
// //      for (int i = 0; i < 90000; i++) {
// //row refer to each column of a row in csv file and rows refer to each row in a file
//       if (time != time1) {
//         List<dynamic> row = List();
//         //List<dynamic> col = List();

//         if (i == 0) {
//           i = 1;
//           row.add(
//               "Date"); // ',' $time ',' $latt N ',' $longg E ',' $altt m ',' $speed m/s ',' $accelerometer m/s^2 ',' $gyroscope m/s^2 ");
//           row.add("Time");
//           row.add("lat");
//           row.add("long");
//           row.add("alt");
//           row.add("speed");
//           row.add("accelerometer");
//           row.add("gyroscope");
//           rows.add(row);
//           print(
//               "99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999");
//         } else if (i == 1) {
//           row.add(
//               date); // ',' $time ',' $latt N ',' $longg E ',' $altt m ',' $speed m/s ',' $accelerometer m/s^2 ',' $gyroscope m/s^2 ");
//           row.add(time);
//           row.add(latt);
//           row.add(longg);
//           row.add(altt);
//           row.add(speed);
//           row.add(accelerometer);
//           row.add(gyroscope);
//           rows.add(row);
//           print(
//               "99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999");
//         }
// //      }
// //      String csv = const ListToCsvConverter().convert(rows);

//         raf = file.openSync(mode: FileMode.write);
//         // response.data is List<int> type
//         raf.writeFromSync(response.data);
//         String csv = const ListToCsvConverter().convert(rows);
//         //   file.writeAsString(csv, mode: FileMode.append, flush: true);
//         //file.writeAsString(csv);
//         time1 = time;
//         //file.writeAsString(g);
//         //await raf.close();
//       }
//     } catch (e) {
//       //  print(e);
//     }
// /*    processLines(List<String> lines) {
//       for (var line in lines) {
//         print(line);
//       }
//     }*/
//   }

//   void showDownloadProgress(received, total) {
//     if (total != -1) {
//       //  print((received / total * 100).toStringAsFixed(0) + "%");
//     }
//   }

//   void writemydat() {
//     file.writeAsString('asd,bsdk,kaka khel\n',
//         mode: FileMode.append, flush: false);
//   }

//   void downloadcsvfile() async {
//     String path = await ExtStorage.getExternalStoragePublicDirectory(
//         ExtStorage.DIRECTORY_DOWNLOADS);
//     //String fullPath = tempDir.path + "/boo2.pdf'";
//     String fullPath = "$path/Sensor_Data.csv";
//     //print('full path ${fullPath}');
//     download2(dio, imgUrl, fullPath);
//   }

  GoogleMapController mapController;
  Location location = new Location();

  LocationData pinLocation;
  @override
  LatLng _initialLocation = LatLng(37.42796133588664, -122.885740655967);
//  Map<String, double> currentLocation;

  List<double> _accelerometerValues;

  // updpating values after 1 sec on screen.
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  //Geroscope Veriable
  List<double> _gyroscopeValues;

  // ignore: cancel_subscriptions
  //
  StreamSubscription<LocationData> locationSubscription;
  // speedometer updation in real time UI
  GlobalKey<KdGaugeViewState> key = GlobalKey<KdGaugeViewState>();

// speedo meter values
  int start = 0;
  int end = 240;
  double _lowerValue = 20.0;
  double _upperValue = 40.0;
  int counter = 0;

// Jo bhi location update ho rhi hogi google map camera view controller vha set kr rha hoga.
//
  void wasay() {
    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      // mapController.animateCamera(
      //   CameraUpdate.newCameraPosition(CameraPosition(
      //       target: LatLng(currentLocation.latitude, currentLocation.longitude),
      //       zoom: 18)),
      // );
      setState(() {
        pinLocation = currentLocation;
      });
    });
  }

  void _onMapCreated(GoogleMapController _cntrLoc) async {
    // ignore: await_only_futures
    //mapController = await _cntrLoc;

    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      // mapController.animateCamera(
      //   CameraUpdate.newCameraPosition(CameraPosition(
      //       target: LatLng(currentLocation.latitude, currentLocation.longitude),
      //       zoom: 18)),
      // );
      setState(() {
        pinLocation = currentLocation;
      });
    });
  }

  // there is satellite view or normal view in order to save internet
  MapType _currentMapType = MapType.normal;

  @override
  void dispose() {
    super.dispose();
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  _clearAllBeacons() {
    setState(() {
      beacons = Map<int, Beacon>();
    });
  }

  _startScan() {
    print("Scanning now");
    _scanSubscription = flutterBlueBeacon
        .scan(timeout: const Duration(seconds: 20))
        .listen((beacon) {
      //print('localName: ${beacon.scanResult.advertisementData.localName}');
      //print(
      //    'manufacturerData: ${beacon.scanResult.advertisementData.manufacturerData}');
      // print('serviceData: ${beacon.scanResult.advertisementData.serviceData}');
      // print(beacon.id);
      // print("Abdulwasay");
      // print(beacon.scanResult.device);
      setState(() {
        beacons[beacon.hash] = beacon;
      });
    }, onDone: _stopScan);

    setState(() {
      isScanning = true;
    });
  }

  _stopScan() {
    print("Scan stopped");
    _scanSubscription?.cancel();
    _scanSubscription = null;
    setState(() {
      isScanning = false;
    });
  }

  _buildScanResultTiles() {
    return beacons.values.map<Widget>((b) {
      //IBeaconCard({@required this.iBeacon});
      if (b is IBeacon) {
        return IBeaconCard(iBeacon: b);
      }
      if (b is EddystoneUID) {
        return EddystoneUIDCard(eddystoneUID: b);
      }
      if (b is EddystoneEID) {
        return EddystoneEIDCard(eddystoneEID: b);
      }
      return Card();
    }).toList();
  }

  _buildAlertTile() {
    return new Container(
      color: Colors.redAccent,
      child: new ListTile(
        title: new Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          //   style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: new Icon(
          Icons.error,
          // color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }

  _buildProgressBarTile() {
    return new LinearProgressIndicator();
  }

//we are initializing state of Acceleroscope and Gyroscope values

  @override
  void initState() {
    getPermission();
    //   startServiceInPlatform();
    //downloadcsvfile();

    super.initState();
    _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
      });
    }));
    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));
    // Immediately get the state of FlutterBlue
    _flutterBlue.state.then((s) {
      setState(() {
        state = s;
      });
    });
    // Subscribe to state changes
    _stateSubscription = _flutterBlue.onStateChanged().listen((s) {
      setState(() {
        state = s;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    onPressed();
    _startScan();
    wasay();
    var tiles = new List<Widget>();
    if (state != BluetoothState.on) {
      tiles.add(_buildAlertTile());
    }

    tiles.addAll(_buildScanResultTiles());

    FlutterBackgroundService.initialize(onStart);
    FlutterBackgroundService().sendData({"action": "setAsForeground"});
    final TextStyle textLabel = new TextStyle(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );
    final TextStyle textData = new TextStyle(
      fontSize: 20,
      color: Colors.red[700],
      fontWeight: FontWeight.bold,
    );
    // writemydat();
    //delay();
    //Future.delayed(Duration(seconds: 10));
    csvgenerator('abdul', 'wasay');
    // downloadcsvfile();
    i = 1;
    final ThemeData somTheme = new ThemeData(
        primaryColor: Colors.red,
        accentColor: Colors.red,
        backgroundColor: Colors.grey);
    // csvgenerator('wasay', 'ccr_lab');
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          backgroundColor: Colors.red[700],
          actions: [
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                const PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.person_remove),
                      title: Text('Logout'),
                    ),
                    value: "/logout"
                ),

                const PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.upload_file),
                      title: Text('Manual Data Upload'),
                    ),
                    value: "/dataupload"
                ),


                // const PopupMenuDivider(),
                // const PopupMenuItem(child: Text('Item A')),
                // const PopupMenuItem(child: Text('Item B')),
              ],
              onSelected: (value) async{
                //*************************************************************
                //startService();
                //**************************************************************
                if (value=='/dataupload') {
                  String path =
                  await ExtStorage.getExternalStoragePublicDirectory(
                      ExtStorage.DIRECTORY_DOWNLOADS);
                  //String fullPath = tempDir.path + "/boo2.pdf'";

                  String fullPath = "$path/Beacons.csv";

                  print('full path ${fullPath}');



                  //***************************Download a file from URL**********************
                  // download_from_url(dio, imgUrl, fullPath);
                  //************************************************************************
                  File file = File(fullPath);
                  print("Path of file to be uploaded:   "+fullPath);
                  bt_data_upload(fullPath);
                }
                else if(value=='/logout')
                {

                }
              },

            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Flexible(
                fit: FlexFit.tight,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    (isScanning) ? _buildProgressBarTile() : new Container(),
                    new ListView(
                      children: tiles,
                    )
                  ],
                ),
              ),
              Container(
                  child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: 1,
                        ),
                        Container(
                          child: new Image.asset(
                            'images/check-circle.gif',
                            width: 120,
                            height: 120,
//fit: BoxFit.fill,
                            alignment: Alignment.topCenter,
                          ), //BoxDecoration
                        ), //Conatiner
// SizedBox(
// width: 20,
// ), //SizedBox
                        Container(
                          child: Text(
                              "Your app is active and \n         scanning",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ) //Container
                      ], //<Widget>[]
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          child: new Image.asset(
                            'images/status.gif',
                            width: 50,
                            height: 50,
//fit: BoxFit.fill,
                            alignment: Alignment.topLeft,
                          ), //BoxDecoration
                        ), //Conatiner
//SizedBox
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          child: ElevatedButton(
                            child: Text(
                                '                  Check My Status                  ',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(1))),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            onPressed: () async {
                              int response_from_server=await manual_check_bt_status();
                              print("Response response: ${response_from_server}");
                              if (response_from_server==1)
                                {
                                  AwesomeNotifications().createNotification(
                                      content: NotificationContent(
                                          id: 10,
                                          channelKey: 'basic_channel2',
                                          title: 'Alert!',
                                          body: 'You are at risk of COVID-19'
                                      )
                                  );
                                }
                              else
                              {
                                AwesomeNotifications().createNotification(
                                    content: NotificationContent(
                                        id: 10,
                                        channelKey: 'basic_channel',
                                        title: 'Relax!',
                                        body: 'You are safe'
                                    )
                                );
                              }
                            },
                          ), //BoxedDecoration
                        ) //Container
                      ], //<Widget>[]
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          child: new Image.asset(
                            'images/contact.gif',
                            width: 50,
                            height: 50,
//fit: BoxFit.fill,
                            alignment: Alignment.center,
                          ),
                        ), //Conatiner
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          child: ElevatedButton(
                            child: Text(
                                '            Manage contact tracing           ',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(1))),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            onPressed: () {
                              var cron = new Cron();
                              cron.schedule(new Schedule.parse('* * * * *'), () async {
                                print('every minute');
                                int response_from_server=await manual_check_bt_status();
                                if (response_from_server==1)
                                {
                                  AwesomeNotifications().createNotification(
                                      content: NotificationContent(
                                          id: 10,
                                          channelKey: 'basic_channel',
                                          title: 'Simple Notification',
                                          body: 'Simple body'
                                      )
                                  );
                                }


                              });
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //       builder: (context) => SecondRoute()),

                            },
                          ),
                        ) //Container
                      ], //<Widget>[]
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          child: new Image.asset(
                            'images/self.gif',
                            width: 50,
                            height: 50,
//fit: BoxFit.fill,
                            alignment: Alignment.center,
                          ), //BoxDecoration
                        ), //Conatiner
                        SizedBox(
                          width: 10,
                        ), //SizedBox
                        Container(
                          child: ElevatedButton(
                            child: Text(
                                '                     Self diagnosis                   ',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(1))),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SecondRoute()),
                              );

                            },
                          ), //BoxedDecoration
                        ) //Container
                      ], //<Widget>[]
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          child: new Image.asset(
                            'images/aboutapp.gif',
                            width: 50,
                            height: 50,
//fit: BoxFit.fill,
                            alignment: Alignment.center,
                          ),
                        ), //Conatiner
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          child: ElevatedButton(
                            child: Text(
                                '                   About this app                   ',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(1))),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SecondRoute()),
                              );
                            },
                          ),
                        ) //Container
                      ], //<Widget>[]
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          child: new Image.asset(
                            'images/setting.gif',
                            width: 50,
                            height: 50,
//fit: BoxFit.fill,
                            alignment: Alignment.center,
                          ),
                        ), //Conatiner
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          child: ElevatedButton(
                            child: Text(
                                '                        Setting                            ',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(1))),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SecondRoute()),
                              );
                            },
                          ),
                        ) //Container
                      ], //<Widget>[]
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                  ], //<widget>[]
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ), //Column
              ) //Padding
                  ),
            ],
          ),

          // body: new Stack(
          //   children: <Widget>[
          //     (isScanning) ? _buildProgressBarTile() : new Container(),
          //     new ListView(
          //       children: tiles,
          //     )
          //   ],
          // ),
//         body: SingleChildScrollView(
//           child: Container(
//               child: Padding(
//             padding: const EdgeInsets.all(14.0),
//             child: Column(
//               children: <Widget>[
//                 Column(
//                   children: <Widget>[
//                     SizedBox(
//                       height: 20,
//                     ),
//                     Container(
//                       child: new Image.asset(
//                         'images/check-circle.gif',
//                         width: 150,
//                         height: 150,
// //fit: BoxFit.fill,
//                         alignment: Alignment.topCenter,
//                       ), //BoxDecoration
//                     ), //Conatiner
// // SizedBox(
// // width: 20,
// // ), //SizedBox
//                     Container(
//                       child: Text("Your app is active and \n         scanning",
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold, fontSize: 12)),
//                     ) //Container
//                   ], //<Widget>[]
//                   mainAxisAlignment: MainAxisAlignment.center,
//                 ),
//                 SizedBox(
//                   height: 30,
//                 ),
//                 Row(
//                   children: <Widget>[
//                     Container(
//                       child: new Image.asset(
//                         'images/status.gif',
//                         width: 120,
//                         height: 120,
// //fit: BoxFit.fill,
//                         alignment: Alignment.topLeft,
//                       ), //BoxDecoration
//                     ), //Conatiner
// //SizedBox
//                     SizedBox(
//                       width: 80,
//                     ),
//                     Container(
//                       child: new Image.asset(
//                         'images/location.gif',
//                         width: 120,
//                         height: 120,
// //fit: BoxFit.fill,
//                         alignment: Alignment.topRight,
//                       ), //BoxedDecoration
//                     ) //Container
//                   ], //<Widget>[]
//                   mainAxisAlignment: MainAxisAlignment.center,
//                 ),
//                 SizedBox(
//                   height: 20,
//                 ),
//                 Row(
//                   children: <Widget>[
//                     Container(
//                       child: ElevatedButton(
//                         child: Text('Check My Status',
//                             style:
//                                 TextStyle(color: Colors.black.withOpacity(1))),
//                         style: ButtonStyle(
//                           backgroundColor:
//                               MaterialStateProperty.all<Color>(Colors.white),
//                         ),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => SecondRoute()),
//                           );
//                         },
//                       ),
//                     ), //Conatiner
//                     SizedBox(
//                       width: 70,
//                     ),
//                     Container(
//                       child: ElevatedButton(
//                         child: Text('Geo-Fencing',
//                             style:
//                                 TextStyle(color: Colors.black.withOpacity(1))),
//                         style: ButtonStyle(
//                           backgroundColor:
//                               MaterialStateProperty.all<Color>(Colors.white),
//                         ),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => SecondRoute()),
//                           );
//                         },
//                       ),
//                     ) //Container
//                   ], //<Widget>[]
//                   mainAxisAlignment: MainAxisAlignment.center,
//                 ),
//                 SizedBox(
//                   height: 20,
//                 ),
//                 Row(
//                   children: <Widget>[
//                     Container(
//                       child: new Image.asset(
//                         'images/contact.gif',
//                         width: 120,
//                         height: 120,
// //fit: BoxFit.fill,
//                         alignment: Alignment.center,
//                       ), //BoxDecoration
//                     ), //Conatiner
//                     SizedBox(
//                       width: 70,
//                     ), //SizedBox
//                     Container(
//                       child: new Image.asset(
//                         'images/self.gif',
//                         width: 100,
//                         height: 100,
// //fit: BoxFit.fill,
//                         alignment: Alignment.topRight,
//                       ), //BoxedDecoration
//                     ) //Container
//                   ], //<Widget>[]
//                   mainAxisAlignment: MainAxisAlignment.center,
//                 ),
//                 SizedBox(
//                   height: 10,
//                 ),
//                 Row(
//                   children: <Widget>[
//                     Container(
//                       child: ElevatedButton(
//                         child: Text('Contact Tracing',
//                             style:
//                                 TextStyle(color: Colors.black.withOpacity(1))),
//                         style: ButtonStyle(
//                           backgroundColor:
//                               MaterialStateProperty.all<Color>(Colors.white),
//                         ),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => SecondRoute()),
//                           );
//                         },
//                       ),
//                     ), //Conatiner
//                     SizedBox(
//                       width: 70,
//                     ),
//                     Container(
//                       child: ElevatedButton(
//                         child: Text('Self Diagnosis',
//                             style:
//                                 TextStyle(color: Colors.black.withOpacity(1))),
//                         style: ButtonStyle(
//                           backgroundColor:
//                               MaterialStateProperty.all<Color>(Colors.white),
//                         ),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => SecondRoute()),
//                           );
//                         },
//                       ),
//                     ) //Container
//                   ], //<Widget>[]
//                   mainAxisAlignment: MainAxisAlignment.center,
//                 ), //Row
//               ], //<widget>[]
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.center,
//             ), //Column
//           ) //Padding
//               ), //Container
//         ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );

    /*
                  /* if (pinLocation != null)
                    Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                            pinLocation.heading.round().toString() + "°",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 35))),
                  if (pinLocation != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 220,
                        width: 240,
                        padding: EdgeInsets.all(16.0),
                        child: KdGaugeView(
                          minSpeed: 0,
                          maxSpeed: 240,
                          speed: pinLocation.speed * 3.6,
                          speedTextStyle: TextStyle(
                            color: Colors.red[800],
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                          animate: true,
                          duration: Duration(seconds: 1),
                          subDivisionCircleColors: Colors.red[600],
                          divisionCircleColors: Colors.red[900],
                          fractionDigits: 0,
                          activeGaugeColor: Colors.white38,
                          innerCirclePadding: 20,
                          unitOfMeasurementTextStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                              fontWeight: FontWeight.bold),
                          gaugeWidth: 16.0,
                          baseGaugeColor: Colors.white30,
                          alertColorArray: [
                            Colors.green[500],
                            Colors.green[700],
                            Colors.green[900],
                            Colors.yellow,
                            Colors.deepOrangeAccent,
                            Colors.red,
                            Colors.red[900]
                          ],
                          alertSpeedArray: [15, 40, 60, 100, 120, 140, 160],
                        ),
                        margin: EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                            color: Colors.white60, shape: BoxShape.circle),
                      */
                  // ),
                  // )
                ]),
              ),
              Flexible(
                flex: 2,
                child: Column(
                  children: <Widget>[
                    //Text("Time:   ", style: textLabel),
                    if (pinLocation != null)
                      Text(
                          "Time:       " +
                              DateFormat.Hms()
                                  .format(DateTime.fromMillisecondsSinceEpoch(
                                      (pinLocation.time).round()))
                                  .toString(),
                          style: textData),
                    if (pinLocation != null)
                      Text(
                          "Date:      " +
                              DateFormat.yMMMd()
                                  .format(DateTime.fromMillisecondsSinceEpoch(
                                      (pinLocation.time).round()))
                                  .toString(),
                          style: textData),

                    if (pinLocation != null)
                      Text(
                          "Latitude:   " +
                              pinLocation.latitude.toString() +
                              "  N",
                          style: textData),

                    if (pinLocation != null)
                      Text(
                          "Longitude:   " +
                              pinLocation.longitude.toString() +
                              "  E",
                          style: textData),
                    if (pinLocation != null)
                      Text(
                          "Altitude:   " +
                              pinLocation.altitude.toStringAsFixed(7) +
                              "  m",
                          style: textData),
                    if (pinLocation != null)
                      Text(
                          "Speed:   " +
                              pinLocation.speed.toStringAsFixed(5) +
                              " m/s",
                          style: textData),

                    Text("Accelerometer:   $accelerometer m/s²",
                        style: textData),

                    Text("GyroScope:   $gyroscope m/s²", style: textData)
                  ],
                ),
                /*  child: Table(
                defaultColumnWidth: IntrinsicColumnWidth(),
                children: [
                  TableRow(
                    children: [
                    Text("Time:   ", style: textLabel),
                    if (pinLocation != null)
                      Text(
                          DateFormat.Hms()
                              .format(DateTime.fromMillisecondsSinceEpoch(
                                  (pinLocation.time).round()))
                              .toString(),
                          style: textData)
                  ]),
                  TableRow( 
                    children: [
                    Text("Date:   ", style: textLabel),
                    if (pinLocation != null)
                      Text(
                          DateFormat.yMMMd()
                              .format(DateTime.fromMillisecondsSinceEpoch(
                                  (pinLocation.time).round()))
                              .toString(),
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text("Latitude:   ", style: textLabel),
                    if (pinLocation != null)
                      Text(pinLocation.latitude.toString() + "  N",
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text("Longitude:   ", style: textLabel),
                    if (pinLocation != null)
                      Text(pinLocation.longitude.toString() + "  E",
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text("Altitude:   ", style: textLabel),
                    if (pinLocation != null)
                      Text(pinLocation.altitude.toStringAsFixed(7) + "  m",
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text(
                      "Speed:   ",
                      style: textLabel,
                    ),
                    if (pinLocation != null)
                      Text(pinLocation.speed.toStringAsFixed(5) + " m/s",
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text(
                      "Accelerometer:   ",
                      style: textLabel,
                    ),
                    Text("$accelerometer. m/s²", style: textData)
                  ]),
                  TableRow(children: [
                    Text(
                      "GyroScope:   ",
                      style: textLabel,
                    ),
                    Text("$gyroscope m/s²", style: textData)
                  ]),
                ],
              )*/
              ),
              /*
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.center,
                  child: Text('GyroScope: $gyroscope m/s²',
                      style: TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ),
              ),
              Flexible(
                flex: 1,
                child: Align(
                  alignment: Alignment.center,
                  child: Text('Accelerometer: $accelerometer m/s²',
                      style: TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ),
              ),
              */
              // Container(
              //  height: 40,
              // ),
              Container(
                child: Flexible(
                  child: ElevatedButton(
                    child: Text('Bluetooth'),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SecondRoute()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),


      ),
    );
    */
  }
}

Future<void> updatetable(String s,String t,String u,int i)
async {
  var box = await Hive.openBox('gPsdat');
  Dater dater = Dater(longg: s, latt: t,altt: u, indexer: i);
  await box.put('gPsdat${i}', dater);
  print('gPsdat${i}:Done!!!!!!!!!!!!!!!!!!!!!!!!');
}

Future<void> bt_data_upload(path) async {

  // var bytes=path.readAsBytesSync();
  // var postUri = Uri.http('http://13.229.160.192:5000', '/file-upload');

  var postUri = Uri.parse('http://52.74.221.135:5000/beacon_data');

  http.MultipartRequest request = new http.MultipartRequest("POST", postUri);

  http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
      'beaconcsv', path);

  request.files.add(multipartFile);

  http.StreamedResponse response = await request.send();

  print('********************************************************************************************');
  print('Status Code: ');
  print(response.statusCode);
  print('********************************************************************************************');

}




Future<int> manual_check_bt_status() async {

  // var bytes=path.readAsBytesSync();
  // var postUri = Uri.http('http://13.229.160.192:5000', '/file-upload');

  var getUri = Uri.parse('http://52.74.221.135:5000/check_me/furqan');

  http.MultipartRequest request = new http.MultipartRequest("GET", getUri);


  http.StreamedResponse response = await request.send();

  print('********************************************************************************************');
  print('Status Code: ');
  // print(response.statusCode);
  // var dd = response.body;
  // print(response.toString());
  print('********************************************************************************************');

  print('Response: ');
  var responsibility=await response.stream.bytesToString();
  // Map jj = json.decode(response) as Map;

  // print(" HELLO: ${jj}" );
  print(responsibility);
  print(
      '********************************************************************************************');

  if (responsibility == "Yes") {
    return 1;
  }
  else if (responsibility == "No")
  {
    return 0;
  }

}

Future<void> write_response_from_bt_manual_check(String text) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('btManualValue', text);
  debugPrint("*********************************************************************************************");
  debugPrint(
      "A new content,i.e. ${text} has been stored in local storage");
  debugPrint("*********************************************************************************************");
}

