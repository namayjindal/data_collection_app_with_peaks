import 'dart:math';
import 'dart:developer' as dev;
import 'dsp.dart';

class PeakSensorData {
  final double timestamp;
  final int index;
  final double accelX, accelY, accelZ;
  final double gyroX, gyroY, gyroZ;
  final double battery;

  PeakSensorData({
    required this.timestamp,
    required this.index,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.battery,
  });
}

List<double> movingAverage(List<double> signal, int windowSize) {
  List<double> result = List<double>.filled(signal.length, 0);
  for (int i = 0; i < signal.length; i++) {
    int start = max(0, i - windowSize ~/ 2);
    int end = min(signal.length, i + windowSize ~/ 2 + 1);
    result[i] = signal.sublist(start, end).reduce((a, b) => a + b) / (end - start);
  }
  return result;
}

List<int> detectPeaks(List<PeakSensorData> data, int windowSize, double sensitivityFactor, int minDistance) {
  List<int> peakIndices = [];
  List<double> zAccelerations = data.map((d) => d.accelZ).toList();
  List<int> indices = data.map((d) => d.index).toList();
  
  List<double> movingAvg = movingAverage(zAccelerations, windowSize);
  
  double mean = zAccelerations.reduce((a, b) => a + b) / zAccelerations.length;
  double sqSum = zAccelerations.map((z) => z * z).reduce((a, b) => a + b);
  double stdDev = sqrt(sqSum / zAccelerations.length - mean * mean);
  
  double threshold = sensitivityFactor * stdDev;
  for (int i = 1; i < data.length - 1; i++) {
    double current = zAccelerations[i];
    if (current > movingAvg[i] + threshold &&
        current > zAccelerations[i-1] &&
        current > zAccelerations[i+1] &&
        current > 0) {
      if (peakIndices.isEmpty || i - peakIndices.last >= minDistance) {
        peakIndices.add(indices[i]);
      }
    }
  }
  
  return peakIndices;
}

void logSegments(List<PeakSensorData> data, List<int> peakIndices) {
  for (int i = 0; i < peakIndices.length - 1; i++) {
    int start = peakIndices[i];
    int end = peakIndices[i + 1];
    List<PeakSensorData> segment = data.where((d) => d.index >= start && d.index <= end).toList();
    
    dev.log('Segment between indices $start and $end:');
    for (var entry in segment) {
      dev.log('Timestamp: ${entry.timestamp}, Index: ${entry.index}, '
              'Right AccelX: ${entry.accelX}, Right AccelY: ${entry.accelY}, Right AccelZ: ${entry.accelZ}, '
              'Left AccelX: ${entry.accelX}, Left AccelY: ${entry.accelY}, Left AccelZ: ${entry.accelZ}');
    }
  }
}

int processPeaksAndLogSegments(List<PeakSensorData> rightLegData, List<PeakSensorData> leftLegData) {
  int windowSize = 20;
  double sensitivityFactor = 0.4;
  int minDistance = 5;

  List<int> rightLegPeaks = detectPeaks(rightLegData, windowSize, sensitivityFactor, minDistance);
  List<int> leftLegPeaks = detectPeaks(leftLegData, windowSize, sensitivityFactor, minDistance);

  dev.log('Right leg peaks: ${rightLegPeaks.length}');
  dev.log('Left leg peaks: ${leftLegPeaks.length}');

  if (rightLegPeaks.isNotEmpty) {
    dev.log('Right leg peaks: ${rightLegPeaks}');
    logSegments(rightLegData, rightLegPeaks);
  }

  if (leftLegPeaks.isNotEmpty) {
    dev.log('Left leg peaks: ${leftLegPeaks}');
    logSegments(leftLegData, leftLegPeaks);
  }

  return rightLegPeaks.length;
}

// List<int> countPeaks(List<PeakSensorData> rightHandData, List<PeakSensorData> leftHandData) {
//   int windowSize = 20;
//   double sensitivityFactor = 0.4;
//   int minDistance = 5;

//   List<int> rightHandPeaks = detectPeaks(rightHandData, windowSize, sensitivityFactor, minDistance);
//   // List<int> leftHandPeaks = detectPeaks(leftHandData, windowSize, sensitivityFactor, minDistance);

//   print('Right leg peaks: ${rightHandPeaks.length}');
//   dev.log('Right leg peaks: ${rightHandPeaks}');
//   // print('Left leg peaks: ${leftHandPeaks.length}');
//   // dev.log('Left leg peaks: ${leftHandPeaks}');

//   if (rightHandPeaks.isEmpty) {
//     return [0, 0];
//   }

//   // return [(rightHandPeaks.length + leftHandPeaks.length) ~/ 2, rightHandPeaks[0]]; // Average of both hands
//   return [rightHandPeaks.length, rightHandPeaks[0]];
// }