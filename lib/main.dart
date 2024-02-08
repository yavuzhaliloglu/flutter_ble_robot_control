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

void main() {
  runApp(MyApp());
}

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
  // device connection states
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;
  // connection update control stream
  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();
  //service lists
  List<Service> serviceIds = [];
  // ble connection
  late StreamSubscription<ConnectionStateUpdate> _connection;
  // selected message
  String connectingMessage = "";

  @override
  void initState() {
    print("myappstate initstate entered");

    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // get device permission from user
    _getPermission();
  }

  // get permissions if required
  void _getPermission() async {
    // TODO: ios controller will be added
    var blePermission = await Permission.bluetoothScan.status;
    var locationPermission = await Permission.location.status;
    if (blePermission.isDenied) {
      if (await Permission.bluetoothScan.request().isGranted) {
        if (await Permission.bluetoothConnect.request().isGranted) {
          print("permission OK");
        }
      }
    }
    if (locationPermission.isDenied) {
      if (await Permission.location.request().isGranted) {
        if (await Permission.accessMediaLocation.request().isGranted) {
          print("permission OK");
        }
      }
    }
  }

  // scan BLE devices
  void _scanForDevices() {
    print("scanfordevices entered");

    setState(() {
      _devicesList = [];
      isScanning = !isScanning;
    });

    // scan devices
    final StreamSubscription<DiscoveredDevice> scanSubscription =
        _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      setState(() {
        // if device is not in list and it has name, add the list
        if (!_devicesList.any((element) => element.id == device.id) &&
            device.name != "") {
          _devicesList.add(device);
        }
      });
    }, onError: (error) {
      print("Error occurred while scanning: $error");
    });

    // stop scanning after 10 seconds
    Future.delayed(const Duration(seconds: 10)).then((_) {
      // invert the scanning control value
      setState(() {
        isScanning = !isScanning;
      });
      // stop scanning
      scanSubscription.cancel();

      // debug
      print("Scan completed");
    });
  }

  // discover connected device's services
  Future<void> _discoverServices(String deviceId) async {
    setState(() {
      serviceIds = [];
    });
    try {
      // discover services
      await _ble.discoverAllServices(deviceId);

      // Get discovered services
      List<Service> discoveredServices =
          await _ble.getDiscoveredServices(deviceId);

      // Add discovered services to the list
      for (Service discoveredService in discoveredServices) {
        serviceIds.add(discoveredService);
      }
    } catch (e) {
      print("Error Discovering Services: $e");
    }
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
    _connection = _ble.connectToDevice(id: device.id).listen(
      (update) async {
        // connection update handler (async)
        print('ConnectionState for device : ${update.connectionState}');

        setState(() {
          if (update.connectionState == DeviceConnectionState.connecting)
            connectingMessage = "Connecting...";
          if (update.connectionState == DeviceConnectionState.connected)
            connectingMessage =
                "Connected, wait for a while to load controller and ensure that you paired your device.";
        });

        _deviceConnectionController.add(update);

        // if connection state is connected, discover services and navigate page
        if (update.connectionState == DeviceConnectionState.connected) {
          print(
              "CONNECTED DEVICE STREAM: ${_ble.connectedDeviceStream.length}");

          // wait for a while
          await Future.delayed(Duration(seconds: 5));

          // discover services for connected device ID
          await _discoverServices(device.id);

          await _ble.requestConnectionPriority(
              deviceId: device.id,
              priority: ConnectionPriority.highPerformance);

          // wait for a while
          await Future.delayed(Duration(seconds: 3)); // Delay for 5 seconds

          //navigate the page with parameter
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Controller(
                      servicelist: serviceIds,
                      connection: _connection,
                    )),
          ).then((_) {
            setState(() {
              _devicesList = [];
              connectingMessage = "";
            });
          });
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
                  flex: 16,
                  child: Container(
                    child: ListView.builder(
                      itemCount: _devicesList.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            _connectDevice(context, _devicesList[index]);
                          },
                          child: ListTile(
                            title: Text(_devicesList[index].name),
                            subtitle: Text(_devicesList[index].id),
                          ),
                        );
                      },
                    ),
                  )),
              Expanded(flex: 2, child: Text(connectingMessage)),
              Expanded(
                  flex: 4,
                  child: Container(
                    margin: EdgeInsets.all(15.0),
                    // TODO: style will be changed isscanning state
                    child: ElevatedButton(
                      onPressed: () {
                        if (!isScanning) {
                          _scanForDevices();
                        } else {
                          isScanning = !isScanning;
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(isScanning ? 'Scanning  ' : 'Scan Devices  ',
                              style: bleTextStyle),
                          Container(
                            child: isScanning
                                ? SizedBox(
                                    width: 20.0,
                                    height: 20.0,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    ))
                                : Text(""),
                          )
                        ],
                      ),
                      style: bleBtnStyle,
                    ),
                  ))
            ],
          )),
    );
  }

  void dispose() {
    // TODO: StreamController and StreamSubscription will be cleaned for memory management
    print("dispose main");
    super.dispose();
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
