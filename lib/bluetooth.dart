import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:data_collection/data_collection.dart';
import 'package:data_collection/data_models/zephyr_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({
    super.key,
    required this.sensors,
    required this.schoolName,
    required this.grade,
    required this.studentName,
    required this.allowedDeviceNames,
  });

  final List sensors;
  final String schoolName;
  final String studentName;
  //final String exerciseName;
  final String grade;
  final List<String> allowedDeviceNames;

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> devices = [];
  Set<String> deviceIds = {};
  bool isScanning = false;

  Future<void> requestPermissions() async {
    await Permission.location.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  void showConnectDialog() async {
    String sensorContent = 'Sense Right Hand\nSense Left Hand\nSense Right Leg\nSense Left Leg\n';

    sensorContent += 'If doing a ball exercise, please connect to the Sense Ball device.';

    // if (widget.sensors.contains(1)) {
    //   sensorContent += 'Sense Right Hand\n';
    // }
    // if (widget.sensors.contains(2)) {
    //   sensorContent += 'Sense Left Hand\n';
    // }
    // if (widget.sensors.contains(3)) {
    //   sensorContent += 'Sense Right Leg\n';
    // }
    // if (widget.sensors.contains(4)) {
    //   sensorContent += 'Sense Left Leg\n';
    // }
    // if (widget.sensors.contains(5)) {
    //   sensorContent += 'Sense Ball';
    // }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Connect to Sensors',
              style: TextStyle(color: Colors.black),
            ),
            content: Text(
              sensorContent,
              style: const TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Save data
                },
                child: const Text('Yes'),
              ),
            ],
          );
        });
  }

  Future<void> scanDevices() async {
    setState(() {
      isScanning = true;
      devices.clear();
      deviceIds.clear();
    });

    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.off) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Bluetooth off')));
      }
    });

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));

    var data = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          for (ScanResult r in results) {
            String deviceName = r.device.platformName;
            if (widget.allowedDeviceNames.contains(deviceName) &&
                !deviceIds.contains(r.device.remoteId.toString())) {
              setState(() {
                deviceIds.add(r.device.remoteId.toString());
                devices.add(r.device);
              });
            }
          }
        }
      },
      onError: (e) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString()))),
    );

    await Future.delayed(const Duration(seconds: 3));
    await FlutterBluePlus.stopScan();

    FlutterBluePlus.cancelWhenScanComplete(data);
    subscription.cancel();
    setState(() {
      isScanning = false;
    });
  }

  Future<int> readBatteryLevel(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            List<int> value = await characteristic.read();
            if (value.isNotEmpty) {
              var byteData = ByteData.sublistView(Uint8List.fromList(value));
              var zephyrData = ZephyrData.fromBytes(byteData);
              await characteristic.setNotifyValue(false);
              if (zephyrData.field9 > 100) {
                return 100;
              }
              return zephyrData.field9; // Assuming field9 is the battery level
            }
          }
        }
      }
    } catch (e) {
      log('Error reading battery level: $e');
    }
    return -1; // Return -1 if battery level couldn't be read
  }

  void showBatteryAlert(int batteryLevel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sensor Connected'),
          content: Text('Battery Level: $batteryLevel%'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      log('Connected to ${device.platformName}');

      if (device.platformName != 'Sense Cone 1') {
        int batteryLevel = await readBatteryLevel(device);
        if (batteryLevel != -1) {
          showBatteryAlert(batteryLevel);
        }
      }
      setState(() {});
    }
      catch (e) {
      log(e.toString());
    }
  }

  void disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      setState(() {});
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      scanDevices().then((_) {
        showConnectDialog();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: Center(
        child: isScanning
            ? const CircularProgressIndicator(color: Colors.black)
            : Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: ListView.separated(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return Card(
                          child: ListTile(
                            onTap: () {
                              if (device.isDisconnected) {
                                connectToDevice(device);
                              } else {
                                disconnectDevice(device);
                              }
                            },
                            title: Text(
                              device.platformName.isNotEmpty
                                  ? device.platformName
                                  : 'Unknown Device',
                              style: const TextStyle(color: Colors.black),
                            ),
                            subtitle: Text(
                              device.remoteId.toString(),
                              style: const TextStyle(color: Colors.black),
                            ),
                            trailing: Text(
                              device.isConnected ? 'C' : 'NC',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider();
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DataCollection(
                              schoolName: widget.schoolName,
                              grade: widget.grade,
                              studentName: widget.studentName,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'DATA',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
