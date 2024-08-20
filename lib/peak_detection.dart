import 'dart:math';

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

// double calculateMagnitude(double accelX, double accelY, double accelZ) {
//   return sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
// }

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
        peakIndices.add(i);
      }
    }
  }
  
  return peakIndices;
}

int countPeaks(List<PeakSensorData> rightHandData, List<PeakSensorData> leftHandData) {
  int windowSize = 20;
  double sensitivityFactor = 0.6;
  int minDistance = 15;

  List<int> rightHandPeaks = detectPeaks(rightHandData, windowSize, sensitivityFactor, minDistance);
  List<int> leftHandPeaks = detectPeaks(leftHandData, windowSize, sensitivityFactor, minDistance);

  print('Right hand peaks: ${rightHandPeaks.length}');
  print('Left hand peaks: ${leftHandPeaks.length}');

  return (rightHandPeaks.length + leftHandPeaks.length) ~/ 2; // Average of both hands
}