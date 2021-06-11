import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:sensors/sensors.dart';
import 'package:kdgaugeview/kdgaugeview.dart';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'MainPage.dart';

final imgUrl =
    "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/csv/dummy.csv";

var dio = Dio();

void main() {
  runApp(MaterialApp(
    title: 'Navigation Basics',
    home: MainScreen(),
  ));
}

class SecondRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage());
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("COVID-19 Contact Tracing"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
          child: Text('Sensor Data'),
        ),
      ),
    );
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
      if (time != time1) {
        List<dynamic> row = List();

        row.add("$date");
        row.add("$time");
        row.add("$latt N");
        row.add("$longg E");
        row.add("$altt m");
        row.add("$speed m/s");
        row.add("$accelerometer m/s^2");
        row.add("$gyroscope m/s^2");
        rows.add(row);

        var raf = file.openSync(mode: FileMode.write);
        // response.data is List<int> type
        raf.writeFromSync(response.data);
        String csv = const ListToCsvConverter().convert(rows);
        file.writeAsString(csv);
        time1 = time;
        await raf.close();
      }
    } catch (e) {}
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {}
  }

  void downloadcsvfile() async {
    String path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);
    String fullPath = "$path/Sensor_Data.csv";
    download2(dio, imgUrl, fullPath);
  }

  GoogleMapController mapController;
  Location location = new Location();

  LocationData pinLocation;
  @override
  LatLng _initialLocation = LatLng(37.42796133588664, -122.885740655967);
  List<double> _accelerometerValues;

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
              ),
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
  }
}