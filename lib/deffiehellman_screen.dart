//import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DHForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DHFormState();
  }
}

class _DHFormState extends State<DHForm> {
  final _minpad = 5.0;
  final String _scanBarcode = "Hi";

  // retrieving_keys() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   if (!prefs.containsKey("userData")) {
  //     return "No user key found";
  //   }
  //   final extractedUserData =
  //       json.decode(prefs.getString("userData")) as Map<String, Object>;
  //   final k_username = extractedUserData["k_username"];
  //   print("Username Key: " + k_username.toString());
  //   return k_username;
  // }

  @override
  Widget build(BuildContext context) {
    //TextStyle textStyle=Theme.of(context).textTheme.title;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('COVID Tracker'),
      ),
      body: Container(
          margin: EdgeInsets.all(_minpad * 2),
          child: Column(
            children: <Widget>[
              Text('Captured Data : ${_scanBarcode}\n',
                  style: TextStyle(fontSize: 20)),
            ],
          )),
      floatingActionButton: new FloatingActionButton(
        onPressed: _sharedkey,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ),
    );
  }

  Widget getImageAsset() {
    AssetImage assetImage = AssetImage('images/login_fig.png');
    Image image = Image(
      image: assetImage,
      width: 125.0,
      height: 125.0,
    );
    return Container(
      child: image,
      margin: EdgeInsets.only(
          left: _minpad * 10, right: _minpad * 10, top: _minpad * 10),
    );
  }
}

Future<void> _sharedkey() async {
  final algorithm = Cryptography.instance.x25519();

  // Let's generate two keypairs.
  final keyPair = await algorithm.newKeyPair();
  final remoteKeyPair = await algorithm.newKeyPair();
  final remotePublicKey = await remoteKeyPair.extractPublicKey();

  // We can now calculate the shared secret key
  final sharedSecretKey = await algorithm.sharedSecretKey(
    keyPair: keyPair,
    remotePublicKey: remotePublicKey,
  );
  final sharedSecretBytes = await sharedSecretKey.extractBytes();
  print(sharedSecretBytes.toString());
}

class Cryptography {
  static var instance;
}
