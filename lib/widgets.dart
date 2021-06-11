import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:where/main.dart';
import 'Pages/Sixth/SixthHomePage.dart';

import 'Pages/Fifth/FifthHomeScreen.dart';
import 'Pages/Fourth/FourthHomeScreen.dart';
import 'Pages/Sixth/SixthHomePage.dart';
/*
import 'Pages/Third/ThirdHomeScreen.dart';

import 'Pages/First/FirstHome.dart';
import 'Pages/Second/SecondHome.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Woo Home Pages',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //home: FirstHome(),
      home: SecondHome(),
      //home: ThirdHomeScreen(),
      //home: FourthHomeScreen(),
      //home: FifthHomeScreen(),
      //home: SixthHomePage(),
    );
  }
}
*/

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'login.dart';
import 'main_page.dart';
import 'dart:convert' as convert;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

//**********************************************************************************************************
// void callbackDispatcher() {
//   Workmanager.executeTask((task, inputData) {
//     print("Native called background task: $backgroundTask"); //simpleTask will be emitted here.
//     return Future.value(true);
//   });
// }
//*********************************************************************************************************
// Future<void> startService()
// async {
//   if(Platform.isAndroid)
//   {
//     var methodChannel=MethodChannel("com.example.messages");
//     String data=await methodChannel.invokeMethod("startService");
//     debugPrint(data);
//
//   }
// }


// Future<void> init() async {
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
// // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
//   const AndroidInitializationSettings initializationSettingsAndroid =
//   AndroidInitializationSettings('my_splash');
//   final IOSInitializationSettings initializationSettingsIOS =
//   IOSInitializationSettings(
//       onDidReceiveLocalNotification: onDidReceiveLocalNotification);
//   final MacOSInitializationSettings initializationSettingsMacOS =
//   MacOSInitializationSettings();
//   final InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//       macOS: initializationSettingsMacOS);
//   await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//       onSelectNotification: selectNotification);
// }
// Future selectNotification(String payload) async {
//   if (payload != null) {
//     debugPrint('notification payload: $payload');
//   }
//   await Navigator.push(
//     context,
//     MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
//   );
// }


void main() {
  AwesomeNotifications().initialize(
    // set the icon to null if you want to use the default app icon
      'resource://drawable/my_splash',
      [
        NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Colors.blue,
            ledColor: Colors.lightBlueAccent
        ),NotificationChannel(
          channelKey: 'basic_channel2',
          channelName: 'Basic notifications2',
          channelDescription: 'Notification channel2 for basic tests',
          defaultColor: Colors.red,
          ledColor: Colors.redAccent
      )
      ]

  );

  //******************************************************************************************************************************
  // Workmanager.initialize(
  //     callbackDispatcher, // The top level function, aka callbackDispatcher
  //     isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  // );
  //******************************************************************************************************************************
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Login',
    home: PictureForm(),
    theme: ThemeData(
        primaryColor: Colors.indigoAccent, accentColor: Colors.indigoAccent),
  ));
}

class PictureForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PictureFormState();
  }
}

class _PictureFormState extends State<PictureForm> {
  final _minpad = 5.0;
  final cryptor = new PlatformStringCryptor();
  void getPermission() async {
    print("getPermission");
    Map<PermissionGroup, PermissionStatus> permissions =
        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }

  /// Initialise the state
  @override
  void initState() {
    getPermission();
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Insert here your friendly dialog box before call the request method
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });


    super.initState();

    /// We require the initializers to run after the loading screen is rendered
    Timer(Duration(seconds: 3), () {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        runInitTasks();
      });
    });
  }

  @protected
  Future runInitTasks() async {
    String x = await getStringValuesSF();
    if (0==1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return MyApp();
      }));
    } else {
      final String k1 = await cryptor.generateRandomKey();
      final String k2 = await cryptor.generateRandomKey();

      print("key1 :" + k1.toString());
      print("key2 :" + k2.toString());
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return LoginForm();
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    //TextStyle textStyle=Theme.of(context).textTheme.title;

    return Scaffold(
      backgroundColor: Colors.black,
      body: new InkWell(
        child: new Stack(
          fit: StackFit.expand,
          children: <Widget>[
            /// Paint the area where the inner widgets are loaded with the
            /// background to keep consistency with the screen background
            new Container(
              decoration: BoxDecoration(color: Colors.black),
            ),

            /// Render the background image
            new Container(
              child: Image.asset('images/picture_fig.jpg', fit: BoxFit.cover),
            ),

            /// Render the Title widget, loader and messages below each other
            new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                new Expanded(
                  flex: 3,
                  child: new Container(
                      child: new Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                      ),
                    ],
                  )),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      /// Loader Animation Widget
                      CircularProgressIndicator(
                        valueColor:
                            new AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                      ),
                      Text('Please Wait'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

getStringValuesSF() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //Return String
  String stringValue = prefs.getString('stringValue');
  return stringValue;
}
