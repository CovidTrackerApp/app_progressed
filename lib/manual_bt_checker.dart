import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Man_BT_Checker extends StatefulWidget
{


  @override
  State<StatefulWidget> createState() {
    return _Man_BT_CheckerState();
  }

}
class _Man_BT_CheckerState extends State<Man_BT_Checker> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String xx=read_response_from_manual_bt_check() as String;
  }

  final _minpad = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // appBar:AppBar(
      //   title:Text('COVID Tracker'),
      // ),
      body: Container(
          margin: EdgeInsets.all(_minpad * 2),
          child: Column(
            children: <Widget>[


              Padding(
                padding: EdgeInsets.only(top: _minpad * 10, bottom: _minpad),
                child: new Text ("Recieved", textAlign: TextAlign.center),
              ),
              //

            ],
          )
      ),
    );
  }
}
Future<String> read_response_from_manual_bt_check() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //Return String
  String stringValue = prefs.getString('stringValue');
  return stringValue;
}