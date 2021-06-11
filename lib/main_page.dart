import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:where/QRcode.dart';
import 'package:where/MainScreen.dart';
// import 'package:where/main.dart';
import 'package:where/registration.dart';
import 'package:where/deffiehellman_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:path/path.dart';
import 'package:where/login.dart';
import 'package:where/Switch.dart';
import 'package:where/QRcode.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:cron/cron.dart';
import 'package:where/verify_phone.dart';

// final imgUrl =
//     "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";

final imgUrl = "http://46.137.221.124:5000/downloadsensorszip/junaid2";

var dio = Dio();

class Username {
  final String uname;

  Username(this.uname);
}

class Username2 {
  final String uname2;

  Username2(this.uname2);
}

class MainForm extends StatefulWidget {
  final String uname;

  MainForm({Key key, this.uname}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _MainFormState();
  }
}

class _MainFormState extends State<MainForm> {
  final _minpad = 5.0;
  String _scanBarcode = 'Unknown';
  String _connection_wifi = 'Unknown';

  void getPermission() async {
    print("getPermission");
    Map<PermissionGroup, PermissionStatus> permissions =
        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }

  @override
  void initState() {
    getPermission();
    super.initState();
  }

  Future download_from_url(Dio dio, String url, String savePath) async {
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
      print(response.headers);
      File file = File(savePath);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);
      await raf.close();
    } catch (e) {
      print(e);
    }
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }

  data_upload(path) async {
    // var bytes=path.readAsBytesSync();
    // var postUri = Uri.http('http://13.229.160.192:5000', '/file-upload');

    var postUri = Uri.parse('http://46.137.221.124:5000/file-upload');

    http.MultipartRequest request = new http.MultipartRequest("POST", postUri);

    http.MultipartFile multipartFile =
        await http.MultipartFile.fromPath('file', path);

    request.files.add(multipartFile);

    http.StreamedResponse response = await request.send();

    print(
        '********************************************************************************************');
    print('Status Code: ');
    print(response.statusCode);
    print(
        '********************************************************************************************');
  }

  data_upload_bt(path) async {
    // var bytes=path.readAsBytesSync();
    // var postUri = Uri.http('http://13.229.160.192:5000', '/file-upload');

    var postUri = Uri.parse('http://46.137.221.124:5000//bt-file-upload');

    http.MultipartRequest request = new http.MultipartRequest("POST", postUri);

    http.MultipartFile multipartFile =
        await http.MultipartFile.fromPath('file', path);

    request.files.add(multipartFile);

    http.StreamedResponse response = await request.send();

    print(
        '********************************************************************************************');
    print('Status Code: ');
    print(response.statusCode);
    print(
        '********************************************************************************************');
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  Future<void> startService() async {
    if (Platform.isAndroid) {
      var methodChannel = MethodChannel("com.example.messages");
      String data = await methodChannel.invokeMethod("startService");
      debugPrint(
          '*******************************************************************************************');
      debugPrint(data);
      debugPrint(
          '*******************************************************************************************');
    }
  }

  @override
  Widget build(BuildContext context) {
    //TextStyle textStyle=Theme.of(context).textTheme.title;

    return new WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('CCR_Lab_Plus'),
            backgroundColor: Colors.red,
            actions: [
              PopupMenuButton(
                icon: Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.person_remove),
                        title: Text('Logout'),
                      ),
                      value: "/logout"),
                  // const PopupMenuItem(
                  //   child: ListTile(
                  //     leading: Icon(Icons.qr_code),
                  //     title: Text('QR Code'),
                  //   ),
                  //     value: "/qrcode"
                  // ),
                  // const PopupMenuItem(
                  //   child: ListTile(
                  //
                  //     leading: Icon(Icons.qr_code_scanner),
                  //     title: Text('QR Scanner'),
                  //   ),
                  //     value: "/qrscanner"
                  // ),
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.upload_file),
                        title: Text('Manual Data Upload'),
                      ),
                      value: "/dataupload"),
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.bluetooth),
                        title: Text('Manual BTD Upload'),
                      ),
                      value: "/datauploadBT"),
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.memory),
                        title: Text('Automatic Data Upload'),
                      ),
                      value: "/backgroundservice"),

                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.bluetooth),
                        title: Text('Automatic BTD Upload'),
                      ),
                      value: "/backgroundserviceBT"),
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.file_download),
                        title: Text('Download Data'),
                      ),
                      value: "/downloaddata"),
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.article),
                        title: Text('Check Internet'),
                      ),
                      value: "/checkinternet"),

                  // const PopupMenuDivider(),
                  // const PopupMenuItem(child: Text('Item A')),
                  // const PopupMenuItem(child: Text('Item B')),
                ],
                onSelected: (value) async {
                  //*************************************************************
                  //startService();
                  //**************************************************************
                  if (value == '/checkinternet') {
                    try {
                      final stopwatch = Stopwatch()..start();
                      final result = await InternetAddress.lookup('google.com');
                      print('doSomething() executed in ${stopwatch.elapsed}');
                      if (result.isNotEmpty &&
                          result[0].rawAddress.isNotEmpty) {
                        _onCheckPushed(
                            'Connected: latency= ${stopwatch.elapsed.inMilliseconds} ms');
                      }
                    } on SocketException catch (_) {
                      _onCheckPushed('Not Connected');
                    }
                  } else if (value == '/qrscanner') {
                    scanQR();
                  } else if (value == '/downloaddata') {
                    String path =
                        await ExtStorage.getExternalStoragePublicDirectory(
                            ExtStorage.DIRECTORY_DOWNLOADS);
                    //String fullPath = tempDir.path + "/boo2.pdf'";
                    String fullPath = "$path/data.zip";
                    print('full path ${fullPath}');
                    String tempurl =
                        "http://46.137.221.124:5000/downloadsensorszip/";
                    var now = new DateTime.now();
                    var formatter = new DateFormat('dd-MM-yyyy');
                    String formattedDate = formatter.format(now);
                    String urler = tempurl + widget.uname;
                    debugPrint(urler);
                    download_from_url(dio, urler, fullPath);
                  } else if (value == '/backgroundservice') {
                    startService();
                    var cron = new Cron();
                    cron.schedule(new Schedule.parse('*/1 * * * *'), () async {
                      print(
                          '******************************Start of Schedule operation*******************************');
                      print('Occurs every three minutes');
                      //********************************************************************
                      try {
                        final stopwatch = Stopwatch()..start();
                        final result =
                            await InternetAddress.lookup('google.com');
                        print('doSomething() executed in ${stopwatch.elapsed}');
                        if (result.isNotEmpty &&
                            result[0].rawAddress.isNotEmpty) {
                          _onCheckPushed(
                              'Connected: latency= ${stopwatch.elapsed.inMilliseconds} ms');
                        }
                      } on SocketException catch (_) {
                        _onCheckPushed('Not Connected');
                      }
                      //**********************************************************************
                      String path =
                          await ExtStorage.getExternalStoragePublicDirectory(
                              ExtStorage.DIRECTORY_DOWNLOADS);
                      //String fullPath = tempDir.path + "/boo2.pdf'";
                      var now = new DateTime.now();
                      var formatter = new DateFormat('dd-MM-yyyy');
                      String formattedDate = formatter.format(now);

                      String fullPath = path +
                          "/" +
                          widget.uname +
                          "_" +
                          formattedDate +
                          ".csv";
                      print('full path ${fullPath}');
                      //***************************Download a file from URL**********************
                      // download_from_url(dio, imgUrl, fullPath);
                      //************************************************************************
                      File file = File(fullPath);
                      print("Path of file to be uploaded:   " + fullPath);
                      data_upload(fullPath);
                      print(
                          '******************************End of Schedule operation*******************************');
                    });
                  } else if (value == '/backgroundserviceBT') {
                    startService();
                    var cron = new Cron();
                    cron.schedule(new Schedule.parse('*/1 * * * *'), () async {
                      print(
                          '******************************Start of Schedule operation*******************************');
                      print('Occurs every three minutes');
                      //********************************************************************
                      try {
                        final stopwatch = Stopwatch()..start();
                        final result =
                            await InternetAddress.lookup('google.com');
                        print('doSomething() executed in ${stopwatch.elapsed}');
                        if (result.isNotEmpty &&
                            result[0].rawAddress.isNotEmpty) {
                          _onCheckPushed(
                              'Connected: latency= ${stopwatch.elapsed.inMilliseconds} ms');
                        }
                      } on SocketException catch (_) {
                        _onCheckPushed('Not Connected');
                      }
                      //**********************************************************************
                      String path =
                          await ExtStorage.getExternalStoragePublicDirectory(
                              ExtStorage.DIRECTORY_DOCUMENTS);
                      //String fullPath = tempDir.path + "/boo2.pdf'";
                      var now = new DateTime.now();
                      var formatter = new DateFormat('dd-MM-yyyy');
                      String formattedDate = formatter.format(now);

                      String fullPath = path +
                          "/" +
                          widget.uname +
                          "_" +
                          formattedDate +
                          ".csv";
                      print('full path ${fullPath}');
                      //***************************Download a file from URL**********************
                      // download_from_url(dio, imgUrl, fullPath);
                      //************************************************************************
                      File file = File(fullPath);
                      print("Path of file to be uploaded:   " + fullPath);
                      data_upload_bt(fullPath);
                      print(
                          '******************************End of Schedule operation*******************************');
                    });
                  } else if (value == '/qrcode') {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return QRForm();
                    }));
                  } else if (value == '/logout') {
                    _write("");
                    // _read();
                    // deleteFile();
                    // _read();
                    //_addBoolToSF();
                    //prefs.remove('counter');
                    //debugPrint('Logout is Pressed');
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      removeToken();
                      return LoginForm();
                    }));
                  } else if (value == '/dataupload') {
                    String path =
                        await ExtStorage.getExternalStoragePublicDirectory(
                            ExtStorage.DIRECTORY_DOWNLOADS);
                    //String fullPath = tempDir.path + "/boo2.pdf'";
                    // String fullPath = "$path/junaid2_22-04-21.csv";
                    var now = new DateTime.now();
                    var formatter = new DateFormat('dd-MM-yyyy');
                    String formattedDate = formatter.format(now);

                    String fullPath = path +
                        "/" +
                        widget.uname +
                        "_" +
                        formattedDate +
                        ".csv";
                    print('full path ${fullPath}');

                    //***************************Download a file from URL**********************
                    // download_from_url(dio, imgUrl, fullPath);
                    //************************************************************************
                    File file = File(fullPath);
                    print("Path of file to be uploaded:   " + fullPath);
                    data_upload(fullPath);
                    debugPrint(
                        "***********************************************************************");
                    debugPrint(widget.uname);
                    debugPrint(
                        "***********************************************************************");
                  } else if (value == '/datauploadBT') {
                    String path =
                        await ExtStorage.getExternalStoragePublicDirectory(
                            ExtStorage.DIRECTORY_DOCUMENTS);
                    //String fullPath = tempDir.path + "/boo2.pdf'";
                    // String fullPath = "$path/junaid2_22-04-21.csv";
                    var now = new DateTime.now();
                    var formatter = new DateFormat('dd-MM-yyyy');
                    String formattedDate = formatter.format(now);

                    String fullPath = path +
                        "/" +
                        widget.uname +
                        "_" +
                        formattedDate +
                        ".csv";

                    print('full path ${fullPath}');

                    //***************************Download a file from URL**********************
                    // download_from_url(dio, imgUrl, fullPath);
                    //************************************************************************
                    File file = File(fullPath);
                    print("Path of file to be uploaded:   " + fullPath);
                    data_upload_bt(fullPath);
                    debugPrint(
                        "***********************************************************************");
                    debugPrint(widget.uname);
                    debugPrint(
                        "***********************************************************************");
                  } else {}
                },
              ),
            ],
          ),
          body: Container(
              margin: EdgeInsets.only(left: _minpad * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  //**********************************Irrelevant Stuff **********************************************************************
                  // Text('Captured Data : $_scanBarcode\n',
                  //     style: TextStyle(fontSize: 20)),
                  //**************************************************************************************************************
                  // Padding(
                  //     padding: EdgeInsets.only(top: _minpad, bottom: _minpad),
                  //     child: RaisedButton(
                  //       child: Text('Diffie-Hellman'),
                  //       onPressed: () {
                  //
                  //         // debugPrint("Switch is pressed");
                  //         Navigator.push(context,
                  //             MaterialPageRoute(builder: (context) {
                  //              return DHForm();
                  //             }));
                  //       },
                  //       elevation: 20.0,
                  //     )),
                  //********************************************************************************************************************
                  // Padding(
                  //     padding: EdgeInsets.only(top: _minpad, bottom: _minpad),
                  //     child: RaisedButton(
                  //       child: Text('Data Upload'),
                  //       onPressed: () async{
                  //         //************************************************************************************************
                  //         // final login_result = await data_upload("junaid",myController1.text);
                  //         // print("Verification Result" + login_result.toString());
                  //
                  //         //***********************************************************************************
                  //
                  //         // // debugPrint("Switch is pressed");
                  //         // Navigator.push(context,
                  //         //     MaterialPageRoute(builder: (context) {
                  //         //       return DHForm();
                  //         //     }));
                  //       },
                  //       elevation: 20.0,
                  //     )),
                  //
                  //***************************************************************************************************************
                  // Padding(
                  //   padding: EdgeInsets.only(top: _minpad*20, bottom: _minpad*6),
                  //   child: Text('Internet Connection Status : $_connection_wifi\n',
                  //       style: TextStyle(fontSize: 20)),
                  // ),
                  Padding(
                      padding:
                          EdgeInsets.only(top: 30.0, bottom: 20.0, left: 80.0),
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        color: Colors.green,
                        //    backgroundcolor: Color.red,
                        child: Text('Generate Sensor Data'),
                        onPressed: () {
                          Navigator.push(context,
                              new MaterialPageRoute(builder: (context) {
                            return new MyApp();
                          }));
                        },
                        elevation: 20.0,
                      )),
                  Padding(
                      padding:
                          EdgeInsets.only(top: 30.0, bottom: 20.0, left: 80.0),
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        color: Colors.green,
                        //    backgroundcolor: Color.red,
                        child: Text('Key Exchanging'),
                        onPressed: () {
                          Navigator.push(context,
                              new MaterialPageRoute(builder: (context) {
                            return new MyApp();
                          }));
                        },
                        elevation: 20.0,
                      )),
                  //Rectangle(10, 20, 30, 20)
                ],
              )),
        ));
  }

  void _onCheckPushed(String newSelected) {
    setState(() {
      this._connection_wifi = newSelected;
    });
  }
}

void _addBoolToSF() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('boolValue', true);
}

_write(String text) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final File file = File('${directory.path}/my_file_detector.txt');
  await file.writeAsString(text);
}

Future<String> _read() async {
  String text;
  try {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/my_file.txt');
    text = await file.readAsString();
    debugPrint("A file has been read at ${directory.path}");
  } catch (e) {
    debugPrint("Couldn't read file");
  }
  return text;
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<int> deleteFile() async {
  String text;
  try {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/my_file.txt');
    text = await file.readAsString();
    await file.delete();
    debugPrint("A file just got deleted");
  } catch (e) {
    return 0;
  }
}

removeToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove("stringValue");
}
