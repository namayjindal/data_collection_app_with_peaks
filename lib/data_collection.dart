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
import 'peak_detection.dart';

class DataCollection extends StatefulWidget {
  const DataCollection({
    super.key,
    required this.schoolName,
    required this.grade,
    required this.studentName,
  });

  final String schoolName;
  final String studentName;
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
  String gender = 'Male';
  int reps = 0;
  int MLreps = 0;
  bool isCollecting = false;
  bool isProcessingData = true;
  bool isFirstReading = true;
  //String studentName = '';
  String exerciseName = 'namay';

  @override
  void initState() {
    super.initState();
    sensorData = SensorData(List.generate(
        FlutterBluePlus.connectedDevices.length, (index) => index));

    loadExercises();
  }

  // Add this list of sensor names and prefixes
  final List<Map<String, String>> sensorPrefixes = [
    {'name': 'Sense Right Hand', 'prefix': 'right_hand_'},
    {'name': 'Sense Left Hand', 'prefix': 'left_hand_'},
    {'name': 'Sense Right Leg', 'prefix': 'right_leg_'},
    {'name': 'Sense Left Leg', 'prefix': 'left_leg_'},
    {'name': 'Sense Ball', 'prefix': 'ball_'},
    {'name': 'Sakshi Right Hand', 'prefix': 'right_hand_'},
    {'name': 'Sakshi Left Hand', 'prefix': 'left_hand_'},
    {'name': 'Sakshi Right Leg', 'prefix': 'right_leg_'},
    {'name': 'Sakshi Left Leg', 'prefix': 'left_leg_'},
  ];

  final Map<String, List> gradeExercises = {
    'Nursery': [
      "Step Down from Height (dominant)",
      "Step Down from Height (non-dominant)",
      "Step over an obstacle (dominant)",
      "Step over an obstacle (non-dominant)",
      "Jump symmetrically",
      "Hit Balloon Up"
    ],
    'LKG': [
      "Stand on one leg (dominant)",
      "Step over an obstacle (non-dominant)",
      "Hop forward on one leg (dominant)",
      "Hop forward on one leg (non-dominant)",
      "Jumping Jack without Clap",
      "Hit Balloon Up"
    ],
    'SKG': [
      "Stand on one leg (dominant)",
      "Stand on one leg (non-dominant)",
      "Hop forward on one leg (dominant)",
      "Hop forward on one leg (non-dominant)",
      "Jumping Jack without Clap",
      "Hit Balloon Up"
    ],
    'Grade 1': [
      "Stand on one leg (dominant)",
      "Stand on one leg (non-dominant)",
      "Hop 9 metres (dominant)",
      "Hop forward on one leg (non-dominant)",
      "Skipping",
      "Ball Bounce and Catch"
    ],
    'Grade 2': [
      "Stand on one leg (dominant)",
      "Stand on one leg (non-dominant)",
      "Hop 9 metres (dominant)",
      "Hop forward on one leg (non-dominant)",
      "Criss Cross with leg forward",
      "Ball Bounce and Catch"
    ],
    'Grade 3': [
      "Stand on one leg (dominant)",
      "Stand on one leg (non-dominant)",
      "Hop 9 metres (dominant)",
      "Hop 9 metres (non-dominant)",
      "Criss Cross with leg forward",
      "Dribbling in Fig - O"
    ],
    'Grade 4': [
      "Stand on one leg (dominant)",
      "Stand on one leg (non-dominant)",
      "Hop 9 metres (dominant)",
      "Hop 9 metres (non-dominant)",
      "Criss Cross with leg forward",
      "Dribbling in Fig - O"
    ],
    'Grade 5': [
      "Stand on one leg (dominant)",
      "Stand on one leg (non-dominant)",
      "Hop 9 metres (dominant)",
      "Hop 9 metres (non-dominant)",
      "Criss Cross with Clap",
      "Dribbling in Fig - 8"
    ],
    'Grade 6': [
      "Stand on one leg (dominant)",
      "Stand on one leg (non-dominant)",
      "Hop 9 metres (dominant)",
      "Hop 9 metres (non-dominant)",
      "Forward Backward Spread Legs and Back",
      "Dribbling in Fig - 8"
    ],
  };

  List<dynamic> exercises = [
    "Stand on one leg (dominant)",
    "Stand on one leg (non-dominant)",
    "Hop 9 metres (dominant)",
    "Hop 9 metres (non-dominant)",
    "Criss Cross with leg forward",
    "Dribbling in Fig - O"
  ];

  void loadExercises() {
    exercises = gradeExercises[widget.grade] ?? [];
    if (exercises.isNotEmpty) {
      // Set exerciseName to the first exercise in the list for this grade
      exerciseName = exercises[0];
    } else {
      // If there are no exercises for this grade, set exerciseName to an empty string or null
      exerciseName = '';
    }
  }
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
        (sensor) => device.platformName.contains(sensor['name']!),
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

  Future<String> generateCsvFile(List<List<dynamic>> data, String fileName) async {
    List<String> headers = generateHeaderRow();
    data.insert(0, headers);

    String csvString = const ListToCsvConverter().convert(data);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName.csv';
    final file = File(path);
    await file.writeAsString(csvString);
    return path;
  }

  Future<bool> uploadFileToFirebase(String filePath, String additionalInfo) async {
  File file = File(filePath);
  bool uploadComplete = false;
  late Timer timeoutTimer;

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

    final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
    String fileName = '$exerciseName-${widget.grade}-${widget.studentName}-$reps-$label-$timestamp.csv';
    Reference storageRef = FirebaseStorage.instance
        .ref('${widget.schoolName}/$exerciseName/$fileName');

    SettableMetadata metadata = SettableMetadata(
      customMetadata: {
        'additionalInfo': additionalInfo,
        'label': label,
        'reps': reps.toString(),
        'studentName': widget.studentName,
        'gender': gender,
        'grade': widget.grade,
        'exerciseName': exerciseName,
      },
    );

    // Create a Completer to handle the timeout
    Completer<bool> uploadCompleter = Completer<bool>();

    // Set up the timeout
    timeoutTimer = Timer(const Duration(seconds: 2), () {
      if (!uploadComplete) {
        uploadCompleter.complete(false);
      }
    });

    // Start the upload
    storageRef.putFile(file, metadata).then((_) {
      uploadComplete = true;
      uploadCompleter.complete(true);
    }).catchError((error) {
      dev.log('Error during upload: $error');
      uploadCompleter.complete(false);
    });

    // Wait for either the upload to complete or the timeout
    bool success = await uploadCompleter.future;

    // Cancel the timer if it hasn't fired yet
    if (timeoutTimer.isActive) {
      timeoutTimer.cancel();
    }

    // Close the upload dialog
    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      dev.log('File uploaded successfully with metadata');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Upload Status'),
            content: const Text('Data saved successfully with additional information!'),
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
      return true;
    } else {
      dev.log('Upload failed or timed out');
      return false;
    }
  } catch (e) {
    dev.log('Error in uploadFileToFirebase: $e');
    // Ensure the dialog is closed in case of any error
    Navigator.of(context, rootNavigator: true).pop();
    return false;
  }
}

Future<String> saveCSVLocally(String csvContent, String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final folderName = 'SavedCSVFiles';
    final newDirectory = Directory('${directory.path}/$folderName');
    
    final file = File('${newDirectory.path}/$fileName');
    dev.log('CSV file saved locally: ${file.path}');

    return file.path;
  } catch (e) {
    dev.log('Error saving CSV locally: $e');
    return '';
  }
}

  void getData() async {
    setState(() {
      elapsedTime = 0;
      csvData.clear();
      sensorData.clear();
      isCollecting = true;
      isFirstReading = true;
      isProcessingData = true; // Start processing data again
    });

    List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
    setState(() {
      deviceCount = devices.length.clamp(1, 5);
    });

    elapsedTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        elapsedTime++;
      });
    });

    for (int i = 0; i < deviceCount; i++) {
      var device = devices[i];

      // Log the name of the connected device
      dev.log('Connected to: ${device.platformName}');

      var services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            characteristic.write([0]);
            dev.log('Wrote to sensor $i');
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
        dev.log("Setting notify value to true");
        await characteristics[i]!.setNotifyValue(true);
        characteristics[i]!.lastValueStream.listen((value) {
          dev.log("Processing data for sensor $i");
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
    if (!isProcessingData) return;

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
           dev.log(zephyrData.toString());
          // Check if it's the first reading and the index is greater than 10
          if (isFirstReading && zephyrData.field2 > 10) {
            dev.log('Discarding first reading with index > 10');
            continue; // Skip this reading
          }
          isFirstReading = false; // Mark that we've processed the first reading

          // Check if this data point already exists
          bool dataExists = sensorData.data[sensorIndex]?.any((data) =>
                  data.field1 == zephyrData.field1 &&
                  data.field2 == zephyrData.field2) ??
              false;

          if (!dataExists) {
            sensorData.addData(sensorIndex, zephyrData);
            dev.log(zephyrData.toString());
          } else {
            dev.log('Skipping duplicate data point');
          }
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

    List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
    for (var device in devices) {
      await device.disconnect();
    }

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false);
  }

  Future<void> stopCollection() async {
  elapsedTimer?.cancel();
  String additionalInfo = '';
  // String exercise = '';

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
  final _formKey = GlobalKey<FormState>();

  bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter Label and Information',
            style: TextStyle(color: Colors.black)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey, // Attach the form key here
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
                DropdownButtonFormField<String>(
                  value: gender,
                  onChanged: (String? newValue) {
                    setState(() {
                      gender = newValue!;
                    });
                  },
                  items: ['Male', 'Female'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: const InputDecoration(labelText: 'Select Gender'),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    hintText: 'Select Exercise',
                  ),
                  value: exercises.contains(exerciseName) ? exerciseName : null,
                  items: exercises.map((exercise) {
                    return DropdownMenuItem<String>(
                      value: exercise,
                      child: Text(exercise),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      exerciseName = newValue!;
                    });
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  onChanged: (String value) {
                    setState(() {
                      reps = int.tryParse(value) ?? 0;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Number of Reps/Time'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of reps';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  onChanged: (String value) {
                    additionalInfo = value;
                  },
                  decoration: const InputDecoration(labelText: 'Additional Information'),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
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
          for (var queue in sensorData.data.values) {
            if (queue.isNotEmpty) {
              queue.removeFirst();
            }
          }
        }
        
      String csvString = const ListToCsvConverter().convert(csvData);

      processPeakData(csvData);
    
      final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
      String fileName = '$exerciseName-${widget.grade}-${widget.studentName}-$reps-$label-$timestamp.csv';
      String path = await generateCsvFile(csvData, fileName);
      bool uploadSuccess = await uploadFileToFirebase(path, additionalInfo);

      if (!uploadSuccess) {
        String savedFilePath = await saveCSVLocally(csvString, fileName);
        
        if (savedFilePath.isNotEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Upload Status'),
                content: const Text('Upload failed or timed out. Data saved locally.'),
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
      }
    }
  }

  setState(() {
    sensorData.clear();
    csvData.clear();
    elapsedTime = 0;
    isCollecting = false;
  });
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

  void disconnectAndNavigate() async {
    List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
    for (var device in devices) {
      await device.disconnect();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
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
                onPressed: isCollecting ? stopCollection : null,
                child: const Text(
                  'Stop Collection',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: isCollecting ? null : disconnectAndNavigate,
                child: const Text(
                  'Go to Home',
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
