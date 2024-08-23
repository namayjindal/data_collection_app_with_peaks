import 'dart:math';
import 'dsp.dart';

List<double> movingAverage(List<double> signal, int windowSize) {
  List<double> result = List<double>.filled(signal.length, 0);
  for (int i = 0; i < signal.length; i++) {
    int start = max(0, i - windowSize ~/ 2);
    int end = min(signal.length, i + windowSize ~/ 2 + 1);
    result[i] = signal.sublist(start, end).reduce((a, b) => a + b) / (end - start);
  }
  return result;
}

List<int> detectPeaks(List<double> data, {int windowSize = 20, double sensitivityFactor = 0.4, int minDistance = 5}) {
  List<int> peakIndices = [];
  List<double> movingAvg = movingAverage(data, windowSize);
  
  double mean = data.reduce((a, b) => a + b) / data.length;
  double stdDev = sqrt(data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length);
  
  double threshold = sensitivityFactor * stdDev;
  for (int i = 1; i < data.length - 1; i++) {
    double current = data[i];
    if (current > movingAvg[i] + threshold &&
        current > data[i-1] &&
        current > data[i+1] &&
        current > 0) {
      if (peakIndices.isEmpty || i - peakIndices.last >= minDistance) {
        peakIndices.add(i);
      }
    }
  }
  
  return peakIndices;
}

void processPeakData(List<List<dynamic>> csvData) {
  // Remove empty lists from CSV data
  csvData.removeWhere((row) => row.isEmpty);

  List<double> xAccelData = csvData.map((row) => double.parse(row[2].toString())).toList();
  
  List<int> peaks = detectPeaks(xAccelData);
  
  print('Number of peaks detected: ${peaks.length}');
  
  // Extract relevant columns (indices 2, 3, 4, 11, 12, 13)
  for (int i = 0; i < peaks.length - 1; i++) {
    int start = peaks[i];
    int end = peaks[i+1];
    
    List<List<double>> segment = [];

    for (int j = start; j < end; j++) {
      segment.add([
        double.parse(csvData[j][2].toString()),  
        double.parse(csvData[j][3].toString()), 
        double.parse(csvData[j][4].toString()), 
        double.parse(csvData[j][11].toString()), 
        double.parse(csvData[j][12].toString()), 
        double.parse(csvData[j][13].toString())
      ]);
    }

    // Print the extracted segment
    print(segment);

    // Process the extracted segment
    FeatureExtractor extractor = FeatureExtractor(4); // Example window size
    extractor.processSegment(segment);

    print('---');
  }
}
