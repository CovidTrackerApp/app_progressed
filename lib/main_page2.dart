//******************************************************************************
import 'dart:ffi';
import 'main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:sensors/sensors.dart';
import 'package:rxdart/rxdart.dart';
import 'package:kdgaugeview/kdgaugeview.dart';
import 'dart:math';
import 'package:path/path.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_file_manager/flutter_file_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'main_page3.dart';

final imgUrl = "http://13.229.160.192:5000/downloadsensorszip/junaid2";

var dio = Dio();

//*******************************************************************************
class MainForm2 extends StatefulWidget {
  MainForm2({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() {
    return _MainFormState2();
  }
}

class _MainFormState2 extends State<MainForm2> {
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
      String latt = pinLocation.latitude.toString();
      String longg = pinLocation.longitude.toString();
      String altt = pinLocation.altitude.toString();
      final List<String> gyroscope =
          _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
      final List<String> accelerometer = _accelerometerValues
          ?.map((double v) => v.toStringAsFixed(1))
          ?.toList();
      String time = DateFormat.Hms()
          .format(
              DateTime.fromMillisecondsSinceEpoch((pinLocation.time).round()))
          .toString();
      String date = DateFormat.yMMMd()
          .format(
              DateTime.fromMillisecondsSinceEpoch((pinLocation.time).round()))
          .toString();
      String speed = pinLocation.speed.toStringAsFixed(7);
      // print(speed);
      //var speed1 = double.parse(speed.toStringAsFixed(2));
//      for (int i = 0; i < 90000; i++) {
//row refer to each column of a row in csv file and rows refer to each row in a file
      if (time != time1) {
        List<dynamic> row = List();
        //List<dynamic> col = List();

        row.add(
            "$date"); // ',' $time ',' $latt N ',' $longg E ',' $altt m ',' $speed m/s ',' $accelerometer m/s^2 ',' $gyroscope m/s^2 ");
        row.add("$time");
        row.add("$latt N");
        row.add("$longg E");
        row.add("$altt m");
        row.add("$speed m/s");
        row.add("$accelerometer m/s^2");
        row.add("$gyroscope m/s^2");
        rows.add(row);

//      }
//      String csv = const ListToCsvConverter().convert(rows);
        var raf = file.openSync(mode: FileMode.write);
        // response.data is List<int> type
        raf.writeFromSync(response.data);
        String csv = const ListToCsvConverter().convert(rows);
        file.writeAsString(csv);
        time1 = time;
        //file.writeAsString(g);
        await raf.close();
      }
    } catch (e) {
      //  print(e);
    }
/*    processLines(List<String> lines) {
      for (var line in lines) {
        print(line);
      }
    }*/
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      //  print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }

  void downloadcsvfile() async {
    String path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);
    //String fullPath = tempDir.path + "/boo2.pdf'";
    String fullPath = "$path/Sensor_Data.csv";
    //print('full path ${fullPath}');
    download2(dio, imgUrl, fullPath);
  }

  GoogleMapController mapController;
  Location location = new Location();

  LocationData pinLocation;
  @override
  LatLng _initialLocation = LatLng(37.42796133588664, -122.885740655967);
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
  void _onMapCreated(GoogleMapController _cntrLoc) async {
    // ignore: await_only_futures
    mapController = await _cntrLoc;

    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(currentLocation.latitude, currentLocation.longitude),
            zoom: 18)),
      );
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
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

//we are initializing state of Acceleroscope and Gyroscope values

  @override
  void initState() {
    getPermission();
    startServiceInPlatform();
    downloadcsvfile();
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
  }

  @override
  Widget build(BuildContext context) {
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
    downloadcsvfile();
    final ThemeData somTheme = new ThemeData(
        primaryColor: Colors.red,
        accentColor: Colors.red,
        backgroundColor: Colors.grey);
    final List<String> gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
    final List<String> accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(1))?.toList();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          backgroundColor: Colors.red[700],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Flexible(
                flex: 04,
                fit: FlexFit.tight,
                child: Stack(children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                    mapType: _currentMapType,
                    initialCameraPosition: CameraPosition(
                      target: _initialLocation,
                      zoom: 10.0,
                    ),
                  ),
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
                        MaterialPageRoute(builder: (context) => MainPage()),
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
  }
}
