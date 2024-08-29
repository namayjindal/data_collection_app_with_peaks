import 'dart:math';
import 'dart:convert';

import 'package:data_collection/ml_pipelines/criss_cross_without_claps/tflite_anomaly_detector.dart';

class FeatureExtractor {
  final int windowSize;

  FeatureExtractor(this.windowSize);

  List<List<double>> calculateFeaturesForWindows(List<List<double>> segment) {
    List<String> axes = ['right_leg_accel_x', 'right_leg_accel_y', 'right_leg_accel_z', 'left_leg_accel_x', 'left_leg_accel_y', 'left_leg_accel_z'];
    List<List<double>> allWindowFeatures = [];

    for (int start = 0; start <= segment.length - windowSize; start+=2) {
      List<double> windowFeatures = [];

      for (int i = 0; i < axes.length; i++) {
        List<double> axisSegment = segment.sublist(start, start + windowSize).map((row) => row[i]).toList();
        
        windowFeatures.addAll([
          _mean(axisSegment),
          _stdDev(axisSegment),
          _rms(axisSegment),
          axisSegment.reduce(min),
          axisSegment.reduce(max),
          _skewness(axisSegment),
          _kurtosis(axisSegment)
        ]);
      }

      allWindowFeatures.add(windowFeatures);
    }

    return allWindowFeatures;
  }

  double _mean(List<double> data) {
    return data.reduce((a, b) => a + b) / data.length;
  }

  double _stdDev(List<double> data) {
    double mean = _mean(data);
    double variance = data
        .map((value) => pow(value - mean, 2))
        .reduce((a, b) => a + b) /
        data.length;
    return sqrt(variance);
  }

  double _rms(List<double> data) {
    double meanSquare = data.map((value) => pow(value, 2)).reduce((a, b) => a + b) / data.length;
    return sqrt(meanSquare);
  }

  double _skewness(List<double> data) {
    double mean = _mean(data);
    double stdDev = _stdDev(data);
    double n = data.length.toDouble();

    double skewness = (n / ((n - 1) * (n - 2))) *
        data
            .map((value) => pow((value - mean) / stdDev, 3))
            .reduce((a, b) => a + b);

    return skewness.isNaN ? 0.0 : skewness;
  }

  double _kurtosis(List<double> data) {
    double mean = _mean(data);
    double stdDev = _stdDev(data);
    double n = data.length.toDouble();

    double kurt = (n * (n + 1) * data
        .map((value) => pow((value - mean) / stdDev, 4))
        .reduce((a, b) => a + b) /
        ((n - 1) * (n - 2) * (n - 3))) - (3 * pow(n - 1, 2) / ((n - 2) * (n - 3)));

    return kurt.isNaN ? 0.0 : kurt;
  }

  Future<bool> processSegment(List<List<double>> segment) async {
    List<List<double>> featuresForWindows = calculateFeaturesForWindows(segment);
    int noOfAnomaliesInSegment = 0;
    bool isSegmentAnomaly = false;

    for (var windowFeatures in featuresForWindows) {
      bool? isAnomaly = await runTFLiteModel(windowFeatures);

      if (isAnomaly) {
        noOfAnomaliesInSegment++;
      }
    }

    if (noOfAnomaliesInSegment > segment.length / windowSize / 2) {
      isSegmentAnomaly = true;
    }

    _logFeaturesAndScores(featuresForWindows, isSegmentAnomaly);

    return isSegmentAnomaly;

  }

  void _logFeaturesAndScores(List<List<double>> featuresForWindows, bool isSegmentAnomaly) {
    for (int i = 0; i < featuresForWindows.length; i++) {
      print('Window $i:');
      print('Features: ${jsonEncode(featuresForWindows[i])}');
      print('Features length: ${featuresForWindows[i].length}');
      print('Is segment anomaly: $isSegmentAnomaly');
      print('---');
    }
    print('Total windows processed: ${featuresForWindows.length}');
  }
}