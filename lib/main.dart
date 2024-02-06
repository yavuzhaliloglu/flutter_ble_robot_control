import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_reactive_new/controller.dart';
import 'package:flutter/services.dart';

/*
  * -- data yollanacak
  * ff01: motor
  * ff02: vana
  * ff03: start-stop
  *
  * -- subscribe olunacak
  * ffa0: ön sensör / arka sensör
  * ffa1: su akışı
  * ffa2: batarya
  * */

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ble handler
  final _ble = FlutterReactiveBle();
  // discovered device's list
  List<DiscoveredDevice> _devicesList = [];
  // scanning control variable
  bool isScanning = false;

  // initialization of widget
  @override
  void initState() {
    super.initState();

    // get device permission from user
    _getPermission();

    // vertical lock for screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;

  // connection update control stream
  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();
  /*late StreamSubscription<ConnectionStateUpdate> _connection;*/
  //service lists
  List<Service> serviceIds = [];

  // scan devices
  void _scanForDevices() {
    // invert the scanning control value
    isScanning = !isScanning;
    // scan devices
    final StreamSubscription<DiscoveredDevice> scanSubscription =
        _ble.scanForDevices(
      withServices: [],
    ).listen((device) {
      setState(() {
        // if device is not in list and it has name, add the list
        if (!_devicesList.any((element) => element.id == device.id) &&
            device.name  != "") {
          _devicesList.add(device);
        }
      });
    }, onError: (error) {
      print("Error occurred while scanning: $error");
    });

    // stop scanning after 10 seconds
    Future.delayed(const Duration(seconds: 10)).then((_) {
      // invert the scanning control value
      isScanning = !isScanning;

      // stop scanning
      scanSubscription.cancel();

      // debug
      print("Scan completed");
    });
  }

  // get permissions if required
  void _getPermission() async {
    var blePermission = await Permission.bluetoothScan.status;
    if (blePermission.isDenied) {
      if (await Permission.bluetoothScan.request().isGranted) {
        if (await Permission.bluetoothConnect.request().isGranted) {
          print("permission OK");
        }
      }
    }
  }

  // discover connected device's services
  void _discoverServices(String deviceId) async {
    // discover services
    await _ble.discoverAllServices(deviceId);
    // get discovered services
    await _ble.getDiscoveredServices(deviceId).then((discoveredService) {
      for (Service discoveredServiceElement in discoveredService) {
        serviceIds.add(discoveredServiceElement);
      }
    });
  }

  // connect device
  Future<void> _connectDevice(
      BuildContext context, DiscoveredDevice device) async {
    // the device which will be connected parameters
    print("connectDevice function started");
    print("device content:");
    print(device.id);
    print(device.name);
    print(device.rssi);
    print(device.connectable);
    print(device.manufacturerData);
    print(device.serviceData);
    print(device.serviceUuids);

    // connection function
    _ble.connectToDevice(id: device.id).listen(
      (update) async {
        // connection update handler (async)
        print('ConnectionState for device : ${update.connectionState}');
        _deviceConnectionController.add(update);

        // if connection state is connected, discover services and navigate page
        if (update.connectionState == DeviceConnectionState.connected) {

          // wait for a while
          await Future.delayed(Duration(seconds: 3));

          // discover services for connected device ID
          _discoverServices(device.id);

          // wait for a while
          await Future.delayed(Duration(seconds: 3)); // Delay for 5 seconds

          //navigate the page with parameter
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Controller(
                      servicelist: serviceIds,
                    )),
          );
        }
      },
      onError: (Object e) => print('Connecting to device resulted in error $e'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text('BLE Device Scanner'),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                  flex: 18,
                  child: Container(
                    child: ListView.builder(
                      itemCount: _devicesList.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            _connectDevice(context, _devicesList[index]);
                          },
                          child: ListTile(
                            title: Text(
                                _devicesList[index].name),
                            subtitle: Text(_devicesList[index].id),
                          ),
                        );
                      },
                    ),
                  )),
              Expanded(
                  flex: 2,
                  child: Container(
                    margin: EdgeInsets.all(15.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _scanForDevices();
                      },
                      child: Text(isScanning ? 'Scanning' : 'Scan Devices', style: bleTextStyle),
                      style: bleBtnStyle,
                    ),
                  ))
            ],
          )),
    );
  }
}

// style for scan button
final ButtonStyle bleBtnStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.blueAccent,
);

// style for scan button text
final TextStyle bleTextStyle = TextStyle(
  color: Colors.white,
);
