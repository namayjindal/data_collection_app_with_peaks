// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:data_collection/home.dart';
import 'package:data_collection/zephyr_data.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';

class DataCollection extends StatefulWidget {
  const DataCollection({
    super.key,
    required this.schoolName,
    required this.grade,
    // required this.studentName,
    required this.exerciseName,
  });

  final String schoolName;
  // final String studentName;
  final String exerciseName;
  final String grade;

  @override
  State<DataCollection> createState() => _DataCollectionState();
}

class SensorData {
  final Map<int, Queue<ZephyrData>> data = {};
  final List<int> sensorIds;
  bool isAligned = false;
  int alignmentCounter = 0;
  int lastSyncCheckTime = 0;

  SensorData(this.sensorIds) {
    for (var id in sensorIds) {
      data[id] = Queue<ZephyrData>();
    }
  }

  void addData(int sensorIndex, ZephyrData zephyrData) {
    data[sensorIndex]?.add(zephyrData);
    if (!isAligned) {
      alignmentCounter++;
      if (alignmentCounter >= 5 * sensorIds.length) {
        alignSensors();
      }
    }
  }

  void alignSensors() {
    int maxTimestamp = 0;
    for (var queue in data.values) {
      if (queue.isNotEmpty && queue.first.field1 > maxTimestamp) {
        maxTimestamp = queue.first.field1;
      }
    }

    for (var queue in data.values) {
      while (queue.isNotEmpty && queue.first.field1 < maxTimestamp) {
        queue.removeFirst();
      }
    }

    isAligned = true;
    lastSyncCheckTime = maxTimestamp;
  }

  bool allSensorsHaveData() {
    return data.values.every((queue) => queue.isNotEmpty);
  }

  List<dynamic> getSyncedData() {
    if (allSensorsHaveData()) {
      var sensorData = [];
      for (var queue in data.values) {
        var v = queue.removeFirst();
        var l = v.splitData();
        sensorData.addAll(l);
      }
      return sensorData;
    }
    return [];
  }

  void syncCheck() {
    if (!isAligned) return;

    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - lastSyncCheckTime >= 1000) {
      int minReadings = data.values.map((queue) => queue.length).reduce(min);
      for (var queue in data.values) {
        while (queue.length > minReadings) {
          queue.removeLast();
        }
      }
      lastSyncCheckTime = currentTime;
    }
  }

  void clear() {
    for (var queue in data.values) {
      queue.clear();
    }
    isAligned = false;
    alignmentCounter = 0;
  }
}

class _DataCollectionState extends State<DataCollection> {
  late SensorData sensorData;
  List<List<dynamic>> csvData = [];
  List<BluetoothCharacteristic?> characteristics = List.filled(5, null);
  Timer? elapsedTimer;
  int elapsedTime = 0;
  int deviceCount = 0;
  String label = 'Good';
  int reps = 0;
  bool isCollecting = false;
  bool isPaused = false;
  bool isProcessingData = true;
  bool isFirstReading = true;
  bool shouldStopCollecting = false;
  String studentName = '';

  @override
  void initState() {
    super.initState();
    sensorData = SensorData(List.generate(
        FlutterBluePlus.connectedDevices.length, (index) => index));
  }

  // Add this list of sensor names and prefixes
  final List<Map<String, String>> sensorPrefixes = [
    {'name': 'Sense Right Hand', 'prefix': 'right_hand_'},
    {'name': 'Sense Left Hand', 'prefix': 'left_hand_'},
    {'name': 'Sense Right Leg', 'prefix': 'right_leg_'},
    {'name': 'Sense Left Leg', 'prefix': 'left_leg_'},
    {'name': 'Sense Ball', 'prefix': 'ball_'},
  ];

  List<String> getConnectedSensorPrefixes() {
    return sensorPrefixes
        .sublist(0, deviceCount)
        .map((sensor) => sensor['prefix']!)
        .toList();
  }

  List<String> generateHeaderRow() {
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    List<String> headers = [];

    for (BluetoothDevice device in connectedDevices) {
      // Find the matching sensor prefix for the connected device
      var matchingSensor = sensorPrefixes.firstWhere(
        (sensor) => device.name.contains(sensor['name']!),
        orElse: () => {'name': '', 'prefix': ''},
      );

      String prefix = matchingSensor['prefix']!;

      // If a matching prefix is found, add the headers for this device
      if (prefix.isNotEmpty) {
        headers.addAll([
          '${prefix}timestamp',
          '${prefix}index',
          '${prefix}accel_x',
          '${prefix}accel_y',
          '${prefix}accel_z',
          '${prefix}gyro_x',
          '${prefix}gyro_y',
          '${prefix}gyro_z',
          '${prefix}battery_percentage',
        ]);
      }
    }

    return headers;
  }

  Future<String> generateCsvFile(List<List<dynamic>> data) async {
    List<String> headers = generateHeaderRow();
    data.insert(0, headers);

    String csvString = const ListToCsvConverter().convert(data);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/data.csv';
    final file = File(path);
    await file.writeAsString(csvString);
    return path;
  }

  Future<void> uploadFileToFirebase(
      String filePath, String additionalInfo) async {
    File file = File(filePath);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Uploading..."),
              ],
            ),
          );
        },
      );

      final timestamp = DateTime.now()
          .toString()
          .substring(0, DateTime.now().toString().length - 5);
      String fileName =
          '$studentName-${widget.grade}-$reps-$label-$timestamp';
      Reference storageRef = FirebaseStorage.instance
          .ref('${widget.schoolName}/${widget.exerciseName}/$fileName.csv');

      // Create metadata
      SettableMetadata metadata = SettableMetadata(
        customMetadata: {
          'additionalInfo': additionalInfo,
          'label': label,
          'reps': reps.toString(),
          'studentName': studentName,
          'grade': widget.grade,
          'exerciseName': widget.exerciseName,
        },
      );

      // Upload file with metadata
      await storageRef.putFile(file, metadata);

      Navigator.of(context).pop();

      dev.log('File uploaded successfully with metadata');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Upload Status'),
            content: const Text(
                'Data saved successfully with additional information!'),
            actions: <Widget>[
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
    } on FirebaseException catch (e) {
      Navigator.of(context).pop();
      dev.log('Error uploading file: $e');
    }
  }

  void getData() async {
    setState(() {
      elapsedTime = 0;
      csvData.clear();
      sensorData.clear();
      isCollecting = true;
      isPaused = false;
    });

    elapsedTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        elapsedTime++;
      });
    });

    List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
    setState(() {
      deviceCount = devices.length.clamp(1, 5);
    });

    for (int i = 0; i < deviceCount; i++) {
      var device = devices[i];

      // Log the name of the connected device
      dev.log('Connected to: ${device.name}');

      var services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            // int refTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            // ByteData byteData = ByteData(4);
            // byteData.setUint32(0, refTime, Endian.little);
            // Uint8List referenceData = byteData.buffer.asUint8List();
            characteristic.write([0]);
            dev.log('wrote');
          }
        }
      }

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            setState(() {
              characteristics[i] = characteristic;
            });
            break;
          }
        }
      }

      if (characteristics[i] != null) {
        await characteristics[i]!.setNotifyValue(true);
        characteristics[i]!.lastValueStream.listen((value) {
          processData(value, i);
        });
      }

      device.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('${device.platformName} Disconnected'),
                content: const Text(
                  'Restart data collection',
                  style: TextStyle(color: Colors.black),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Restart'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      restartDataCollection();
                    },
                  ),
                ],
              );
            },
          );
        }
      });
    }
  }

  void processData(List<int> value, int sensorIndex) {
    if (!isProcessingData || shouldStopCollecting)
      return; // Skip processing if paused or stopped

    var v = Uint8List.fromList(value);
    ByteData byteData = ByteData.sublistView(v);

    int bufferSize = byteData.getUint8(0);
    int offset = 1;

    for (int i = 0; i < bufferSize; i++) {
      int start = offset + i * ZephyrData.expectedLength;
      if (start + ZephyrData.expectedLength <= byteData.lengthInBytes) {
        ByteData sensorDataByteData =
            byteData.buffer.asByteData(start, ZephyrData.expectedLength);
        try {
          var zephyrData = ZephyrData.fromBytes(sensorDataByteData);

          // Check if it's the first reading and the index is greater than 10
          if (isFirstReading && zephyrData.field2 > 10) {
            dev.log('Discarding first reading with index > 10');
            continue; // Skip this reading
          }
          isFirstReading = false; // Mark that we've processed the first reading

          sensorData.addData(sensorIndex, zephyrData);
          dev.log(zephyrData.toString());
        } catch (e) {
          dev.log('Error processing data: $e');
        }
      } else {
        dev.log('Insufficient data length');
      }
    }
  }

  List<dynamic> organizeDataRow() {
    List<dynamic> row = [];
    List<String> connectedPrefixes = getConnectedSensorPrefixes();
    bool allDataAvailable = true;

    for (int i = 0; i < connectedPrefixes.length; i++) {
      if (sensorData.data[i]?.isNotEmpty ?? false) {
        var zephyrData = sensorData.data[i]!.first;
        row.addAll(zephyrData.splitData());
      } else {
        // If any sensor data is missing, mark the flag and break
        allDataAvailable = false;
        break;
      }
    }

    // Only return the row if all data was available
    if (allDataAvailable) {
      return row;
    } else {
      return [];
    }
  }

  void restartDataCollection() async {
    elapsedTimer?.cancel();
    // for (var characteristic in characteristics) {
    //   if (characteristic != null) {
    //     await characteristic.setNotifyValue(false);
    //   }
    // }

    sensorData.clear();
    csvData.clear();

    setState(() {
      elapsedTime = 0;
    });

    // await device.connect();

    // getData();

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false);
  }

  Future<void> stopCollection() async {
    elapsedTimer?.cancel();
    shouldStopCollecting = true; // Set flag to stop collecting data
    String additionalInfo = '';

    for (var characteristic in characteristics) {
      if (characteristic != null) {
        await characteristic.setNotifyValue(false);
      }
    }

    bool? saveData = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Data', style: TextStyle(color: Colors.black)),
          content: const Text('Do you want to save the collected data?',
              style: TextStyle(color: Colors.black)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (saveData == true) {
      bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          // String additionalInfo = ''; // New variable to store additional info
          return AlertDialog(
            title: const Text('Enter Label and Information',
                style: TextStyle(color: Colors.black)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: label,
                    onChanged: (String? newValue) {
                      setState(() {
                        label = newValue!;
                      });
                    },
                    items: ['Good', 'Bad', 'Idle'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Select Label'),
                  ),
                  TextFormField(
                    onChanged: (String value) {
                      setState(() {
                        studentName = value;
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Student Info'),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    onChanged: (String value) {
                      setState(() {
                        reps = int.tryParse(value) ?? 0;
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Number of Reps/Time'),
                  ),
                  TextFormField(
                    onChanged: (String value) {
                      additionalInfo = value;
                    },
                    decoration: const InputDecoration(
                        labelText: 'Additional Information'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (ok == true) {
        while (sensorData.data.values.any((queue) => queue.isNotEmpty)) {
          var row = organizeDataRow();
          csvData.add(row);
          // Remove the processed data from sensorData
          for (var queue in sensorData.data.values) {
            if (queue.isNotEmpty) {
              queue.removeFirst();
            }
          }
        }
        String path = await generateCsvFile(csvData);
        await uploadFileToFirebase(path, additionalInfo);

        List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
        for (var device in devices) {
          await device.disconnect();
        }
      }
    }

    // for (var queue in sensorData.data.values) {
    //   for (var v in queue) {
    //     log(v.toString());
    //   }
    // }

    sensorData.clear();
    csvData.clear();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false);
  }

  void bandCallibration() async {
    List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
    for (var device in devices) {
      var services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            char.write([1]);
            dev.log('wrote');
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Calibration Completed'),
          content: const Text(
            'The band calibration process has been completed successfully.',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
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

  Future<void> pauseCollection() async {
    elapsedTimer?.cancel();
    shouldStopCollecting = true; // Set flag to stop collecting data

    String additionalInfo = '';

    setState(() {
      isPaused = true;
      isCollecting = true; // Keep isCollecting true so we can resume later
      isProcessingData = false; // Immediately stop processing new data
    });

    // for (var characteristic in characteristics) {
    //   if (characteristic != null) {
    //     await characteristic.setNotifyValue(false);
    //   }
    // }

    bool? saveData = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Data', style: TextStyle(color: Colors.black)),
          content: const Text('Do you want to save the collected data?',
              style: TextStyle(color: Colors.black)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (saveData == true) {
      bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          // String additionalInfo = ''; // New variable to store additional info
          return AlertDialog(
            title: const Text('Enter Label and Information',
                style: TextStyle(color: Colors.black)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: label,
                    onChanged: (String? newValue) {
                      setState(() {
                        label = newValue!;
                      });
                    },
                    items: ['Good', 'Bad', 'Idle'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Select Label'),
                  ),
                  TextFormField(
                    onChanged: (String value) {
                      setState(() {
                        studentName = value;
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Student Info'),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    onChanged: (String value) {
                      setState(() {
                        reps = int.tryParse(value) ?? 0;
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Number of Reps/Time'),
                  ),
                  TextFormField(
                    onChanged: (String value) {
                      additionalInfo = value;
                    },
                    decoration: const InputDecoration(
                        labelText: 'Additional Information'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (ok == true) {
        while (sensorData.data.values.any((queue) => queue.isNotEmpty)) {
          var row = organizeDataRow();
          csvData.add(row);
          // Remove the processed data from sensorData
          for (var queue in sensorData.data.values) {
            if (queue.isNotEmpty) {
              queue.removeFirst();
            }
          }
        }
        String path = await generateCsvFile(csvData);
        await uploadFileToFirebase(path, additionalInfo);

        // Show a success dialog instead of navigating away
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Upload Success'),
              content:
                  const Text('Data has been successfully saved and uploaded.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }

    // Clear the data after saving
    csvData.clear();
  }

  Future<void> resumeCollection() async {
    setState(() {
      elapsedTime = 0;
      csvData.clear();
      sensorData.clear();
      isPaused = false;
      isFirstReading = true; // Reset the first reading flag
      shouldStopCollecting = false; // Reset the stop collecting flag
    });

    List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;

    // Immediately write to all sensors
    for (int i = 0; i < deviceCount; i++) {
      var device = devices[i];
      var services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write([0]);
            dev.log('Wrote to sensor $i');
          }
        }
      }
    }

    // Set up data collection streams
    for (int i = 0; i < deviceCount; i++) {
      if (characteristics[i] != null) {
        await characteristics[i]!.setNotifyValue(true);
        characteristics[i]!.lastValueStream.listen((value) {
          processData(value, i);
        });
      }
    }

    // Start the timer and enable data processing
    elapsedTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        elapsedTime++;
      });
    });

    setState(() {
      isProcessingData = true; // Start processing data again
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: bandCallibration,
                child: const Text(
                  'Band Calibration',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: isCollecting ? null : getData,
                child: const Text(
                  'Get Data',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text('Elapsed Time: $elapsedTime seconds'),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: isCollecting
                    ? (isPaused ? resumeCollection : pauseCollection)
                    : null,
                child: Text(
                  isPaused ? 'Resume' : 'Next',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: isCollecting ? stopCollection : null,
                child: const Text(
                  'Stop Collection',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
