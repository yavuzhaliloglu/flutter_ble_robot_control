import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

// TODO: error handling for sending and receiving data will be showed in toast
// ble handler
final _ble = FlutterReactiveBle();

// characteristiclist
List<Characteristic> characteristicList = [];

// sliderbar and joystick values
double _x = 127;
double _y = 127;
double _currentSliderValue = 0;

// default characteristic
QualifiedCharacteristic initCharacteristic = QualifiedCharacteristic(
    characteristicId: Uuid.parse('charid'),
    serviceId: Uuid.parse('serviceid'),
    deviceId: 'deviceid');

// characteristics
QualifiedCharacteristic motorCharacteristic = initCharacteristic;
QualifiedCharacteristic valveCharacteristic = initCharacteristic;
QualifiedCharacteristic startStopCharacteristic = initCharacteristic;
QualifiedCharacteristic sensorCharacteristic = initCharacteristic;
QualifiedCharacteristic waterflowCharacteristic = initCharacteristic;
QualifiedCharacteristic batteryCharacteristic = initCharacteristic;

// main widget
class Controller extends StatefulWidget {
  // passed parameter from main page
  final List<Service> servicelist;
  final StreamSubscription<ConnectionStateUpdate> connection;

  const Controller({
    Key? key,
    required this.servicelist,
    required this.connection,
  }) : super(key: key);

  @override
  _ControllerState createState() => _ControllerState();
}

// controller state handler
class _ControllerState extends State<Controller> {
  @override

  @override
  // set characteristic values and create a qualified characteristic
  QualifiedCharacteristic setCharacteristic(
      characteristicid, serviceid, deviceid) {
    final motorcharacteristic = QualifiedCharacteristic(
        characteristicId: characteristicid,
        serviceId: serviceid,
        deviceId: deviceid);

    // return characteristic
    return motorcharacteristic;
  }

  @override
  void initState() {
    super.initState();

    // horizontal lock for the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // controller widget starting debug
    print("Controller widget is initialized");

    // init characteristic and service list
    for (Service s in widget.servicelist) {
      for (Characteristic c in s.characteristics) {
        characteristicList.add(c);
      }
    }

    // print characteristics
    for (Characteristic c in characteristicList) {
      print("CHARACTERISTIC: $c");
    }

    // find characteristics and set the values
    for (Characteristic c in characteristicList) {
      // motor characteristic
      if (c.id.toString().contains('ff01')) {
        motorCharacteristic =
            setCharacteristic(c.id, c.service.id, c.service.deviceId);
      }
      // valve characteristic
      if (c.id.toString().contains('ff02')) {
        valveCharacteristic =
            setCharacteristic(c.id, c.service.id, c.service.deviceId);
      }
      // start-stop haracteristic
      if (c.id.toString().contains('ff03')) {
        startStopCharacteristic =
            setCharacteristic(c.id, c.service.id, c.service.deviceId);
      }
      // sensor values characteristic
      if (c.id.toString().contains('ffa0')) {
        sensorCharacteristic =
            setCharacteristic(c.id, c.service.id, c.service.deviceId);
      }
      // water flow characteristic
      if (c.id.toString().contains('ffa1')) {
        waterflowCharacteristic =
            setCharacteristic(c.id, c.service.id, c.service.deviceId);
      }
      // battery characteristic
      if (c.id.toString().contains('ffa2')) {
        batteryCharacteristic =
            setCharacteristic(c.id, c.service.id, c.service.deviceId);
      }
    }

    /*
    if(motorCharacteristic.characteristicId == Uuid.parse('charid') ||
        valveCharacteristic.characteristicId == Uuid.parse('charid') ||
        startStopCharacteristic.characteristicId == Uuid.parse('charid') ||
        sensorCharacteristic.characteristicId == Uuid.parse('charid') ||
        waterflowCharacteristic.characteristicId == Uuid.parse('charid') ||
        batteryCharacteristic.characteristicId == Uuid.parse('charid')
    ){
      Navigator.pop(context);
    }
     */
  }

  // widget build
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_){
          print("ONPOPINVOKED EXECUTED");
          setState(() {
            characteristicList = [];
          });
          widget.connection.cancel();
      },
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('BLE CONTROL PANEL'),
            ),
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width / 3,
                    child: const JoystickExample(),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 3,
                    child: ParametersArea(), // Your custom widget
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 3,
                    child: ControlArea(), // Your custom widget
                  ),
                ],
              ),
            ),
          ),
    ));
  }

 @override
  void dispose() {
    print("DISPOSE EXECUTED");
    super.dispose();
  }
}

// PARAMETERS AREA
class ParametersArea extends StatefulWidget {
  const ParametersArea({super.key});

  @override
  State<ParametersArea> createState() => _ParametersAreaState();
}

class _ParametersAreaState extends State<ParametersArea> {
  // incoming ble values
  List<int> sensorValues = [0, 0];
  int waterflow = 0;
  int battery = 0;

  // initialization of state
  @override
  void initState() {
    super.initState();
    _startListeningToBluetooth();
  }

  // start to listen incoming ble data
  void _startListeningToBluetooth() {
    print("subscribed sensor characteristic");
    // listen sensor data
    _ble.subscribeToCharacteristic(sensorCharacteristic).listen((data) {
      if (this.mounted) {
        setState(() {
          sensorValues[0] = data[0];
          sensorValues[1] = data[1];
        });
      }
    });

    print("subscribed wf characteristic");
    // listen water flow data
    _ble.subscribeToCharacteristic(waterflowCharacteristic).listen((data) {
      if (this.mounted) {
        setState(() {
          waterflow = data[0];
        });
      }
    });

    print("subscribed battery characteristic");
    // listen battery data
    _ble.subscribeToCharacteristic(batteryCharacteristic).listen((data) {
      if (this.mounted) {
        setState(() {
          battery = data[0];
        });
      }
    });
  }

  // show the sensor values on the screen (middle part of screen)
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(flex: 5, child: Text("Front Sensor: ${sensorValues[0]} cm")),
        Expanded(flex: 5, child: Text("Back Sensor: ${sensorValues[1]} cm")),
        Expanded(flex: 5, child: Text("Water Flow: $waterflow L")),
        Expanded(flex: 5, child: Text("Battery: %$battery")),
      ],
    );
  }
}

// CONTROL AREA
class ControlArea extends StatefulWidget {
  const ControlArea({super.key});

  @override
  State<ControlArea> createState() => _ControlAreaState();
}

class _ControlAreaState extends State<ControlArea> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          flex: 1,
          child: Container(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SliderBar(),
              ],
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Buttons(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// SLIDERBAR
class SliderBar extends StatefulWidget {
  const SliderBar({super.key});

  @override
  State<SliderBar> createState() => _SliderBarState();
}

class _SliderBarState extends State<SliderBar> {
  @override
  void sendSliderBarValue() {
    _ble.writeCharacteristicWithoutResponse(motorCharacteristic, value: [
      _x.toInt(),
      _y.toInt(),
      _currentSliderValue.toInt(),
      _currentSliderValue.toInt()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Slider(
            activeColor: Colors.black,
            inactiveColor: Colors.grey,
            secondaryActiveColor: Colors.black,
            thumbColor: Colors.black,
            value: _currentSliderValue,
            max: 255,
            divisions: 255,
            label: _currentSliderValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                // change sliderbar value
                _currentSliderValue = value;
                print("sliderbar value: $_currentSliderValue");
                sendSliderBarValue();
              });
            },
          ),
          Text("Brush Motor Speed Control"),
        ]);
  }
}

// BUTTONS
class Buttons extends StatefulWidget {
  const Buttons({super.key});

  @override
  State<Buttons> createState() => _ButtonsState();
}

class _ButtonsState extends State<Buttons> {
  // button toggle control variables
  bool isRobotStarted = false;
  bool isSteamStarted = false;

  void initState() {
    super.initState();
  }

  // send motor values
  void sendMotorValues() {
    _ble.writeCharacteristicWithoutResponse(motorCharacteristic, value: [
      _x.toInt(),
      _y.toInt(),
      _currentSliderValue.toInt(),
      _currentSliderValue.toInt()
    ]);
    print(
        "sent motor values x: $_x, y: $_y, currentslidervalue: $_currentSliderValue");
  }

  // toggle device state
  void toggleDeviceState(bool isStarted) {
    // if isStarted true, data can send value to the ble device, so as toggle button, it has to stop with sending 0x00
    if (isStarted)
      _ble.writeCharacteristicWithoutResponse(startStopCharacteristic,
          value: [0x00]);
    // if isStarted false, data can not send value to the ble device, so as toggle button, it has to start with sending 0x01
    else
      _ble.writeCharacteristicWithoutResponse(startStopCharacteristic,
          value: [0x01]);
  }

  //
  void toggleValveState(bool isStarted) {
    // same as toggleDeviceState function
    if (isStarted)
      _ble.writeCharacteristicWithoutResponse(valveCharacteristic,
          value: [0x00]);
    else
      _ble.writeCharacteristicWithoutResponse(valveCharacteristic,
          value: [0x01]);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Robot Start / Stop"),
            Container(
              margin: EdgeInsets.all(1.0),
              child: ElevatedButton(
                  style: btnStyle,
                  onPressed: () {
                    setState(() {
                      isRobotStarted = !isRobotStarted;
                    });
                    toggleDeviceState(isRobotStarted);
                  },
                  child: Text(isRobotStarted ? 'Stop' : 'Start')),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Valve Start / Stop"),
            Container(
              margin: EdgeInsets.all(1.0),
              child: ElevatedButton(
                  style: btnStyle,
                  onPressed: () {
                    setState(() {
                      isSteamStarted = !isSteamStarted;
                    });
                    toggleValveState(isSteamStarted);
                  },
                  child: Text(isSteamStarted ? 'Stop' : 'Start')),
            ),
          ],
        ),
      ]),
    ]);
  }
}

// JOYSTICK AREA
class JoystickExample extends StatefulWidget {
  const JoystickExample({Key? key}) : super(key: key);

  @override
  State<JoystickExample> createState() => _JoystickExampleState();
}

class _JoystickExampleState extends State<JoystickExample> {
  // convert joystick x-axis value from -(1,1) to (0,255)
  double convertX(double x) {
    // Ensure x is within the bounds of -1 to 1
    x = x.clamp(-1.0, 1.0);
    // Apply the conversion formula for x
    return ((x + 1) * 255) / 2;
  }

  // convert joystick y-axis value from -(1,1) to (0,255)
  double convertY(double y) {
    // Ensure y is within the bounds of -1 to 1
    y = y.clamp(-1.0, 1.0);

    // Apply the conversion formula for y and invert the range
    return 255 - (((y + 1) * 255) / 2);
  }

  // send joystick axis values to ble device
  void sendJoystickCommand(double x, double y) {
    int motor_left = 127;
    int motor_right = 127;

    int x_toset = x.toInt();
    int y_toset = y.toInt();

    if (y_toset >= 96 && y_toset <= 158) y_toset = 127;
    if (x_toset >= 96 && x_toset <= 158) x_toset = 127;

    if (y_toset == 127 && x_toset != 127) {
      motor_left = x_toset;
      motor_right = 255 - x_toset;
    } else if (y_toset != 127 && x_toset != 127) {
      if (y_toset < 127) {
        if (x_toset < 127) {
          motor_left = 127 - x_toset;
          motor_right = y_toset;
        } else {
          motor_left = y_toset;
          motor_right = x_toset - 127;
        }
      } else {
        if (x_toset < 127) {
          motor_left = 127 + x_toset;
          motor_right = y_toset;
        } else {
          motor_left = y_toset;
          motor_right = 255 - (x_toset - 127);
        }
      }
    } else {
      motor_left = y_toset;
      motor_right = y_toset;
    }

    print("sending values x: $motor_left and y: $motor_right");
    // sol sağ ön arka
    _ble.writeCharacteristicWithoutResponse(motorCharacteristic, value: [
      motor_left,
      motor_right,
      _currentSliderValue.toInt(),
      _currentSliderValue.toInt()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Joystick(
                listener: (details) {
                  _x = convertX(details.x);
                  _y = convertY(details.y);
                  sendJoystickCommand(_x, _y);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// default button style
final ButtonStyle btnStyle = ElevatedButton.styleFrom(
  fixedSize: const Size(60, 20),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);

