import 'dart:collection';
import 'package:data_collection/data_models/zephyr_data.dart';
import 'dart:math';

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