import 'dart:math';
import 'dart:convert';

class FeatureExtractor {
  final int windowSize;

  FeatureExtractor(this.windowSize);

  List<Map<String, double>> calculateFeatures(List<double> segment) {
    List<Map<String, double>> features = [];

    for (int start = 0; start <= segment.length - windowSize; start += 4) {
      List<double> window = segment.sublist(start, start + windowSize);

      Map<String, double> featureVector = {
        'mean': _mean(window),
        'std_dev': _stdDev(window),
        'rms': _rms(window),
        'min': window.reduce(min),
        'max': window.reduce(max),
        'skewness': _skewness(window),
        'kurtosis': _kurtosis(window)
      };

      features.add(featureVector);
    }

    return features;
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

  void processSegment(List<List<double>> segment) {
    Map<String, List<Map<String, double>>> allFeatures = {};

    List<String> axes = ['right_leg_accel_x', 'right_leg_accel_y', 'right_leg_accel_z', 'left_leg_accel_x', 'left_leg_accel_y', 'left_leg_accel_z'];

    for (int i = 0; i < axes.length; i++) {
      List<double> axisSegment = segment.map((row) => row[i]).toList();

      List<Map<String, double>> features = calculateFeatures(axisSegment);
      allFeatures[axes[i]] = features;
    }

    _logFeatures(allFeatures);
  }

  void _logFeatures(Map<String, List<Map<String, double>>> allFeatures) {
    allFeatures.forEach((axis, features) {
      for (var feature in features) {
        print('Axis: $axis, Features: ${jsonEncode(feature)}');
      }
    });
  }
}