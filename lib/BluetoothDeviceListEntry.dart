import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothDeviceListEntry extends ListTile {
  BluetoothDeviceListEntry({@required BluetoothDevice device,double rssi,GestureTapCallback onTap,GestureLongPressCallback onLongPress,bool enabled = true,}) : super( 
          onTap: onTap,
          onLongPress: onLongPress,
          enabled: enabled,
          leading:
              Icon(Icons.bluetooth), // @TODO . !BluetoothClass! class aware icon
          title: Text(device.name ?? "Unknown device"),
          subtitle: Text(device.address.toString()),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              rssi != null ? Container(
                      margin: new EdgeInsets.all(8.0),
                      child: DefaultTextStyle(
                        style: _computeTextStyle(rssi),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                          
                            Text(rssi.toStringAsFixed(2) + "m"),
                           // Text('m'),
                          ],
                        ),
                      ),
                    )
                  : Container(width: 0, height: 0),
              device.isConnected
                  ? Icon(Icons.import_export)
                  : Container(width: 0, height: 0),
              device.isBonded
                  ? Icon(Icons.link)
                  : Container(width: 0, height: 0),
            ],
          ),
        );

  static TextStyle _computeTextStyle(double rssi) {
    /**/ if (rssi <= 2.0)
      return TextStyle(color: Colors.red);
    else if (rssi <= 4.0)
      return TextStyle(color: Colors.brown);
    else if (rssi <= 6.0)
      return TextStyle(color: Colors.blue);
    else if (rssi <= 8.0)
      return TextStyle(color: Colors.yellow);
    else if (rssi <= 10.0)
      return TextStyle(color: Colors.greenAccent);
    else if (rssi <= 12.0)
      return TextStyle(color: Colors.green);
    else
      return TextStyle(color: Colors.black);
  }
}
