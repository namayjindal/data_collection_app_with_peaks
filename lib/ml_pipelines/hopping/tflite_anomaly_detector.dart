import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:developer';

Future<bool> runTFLiteModel(List<double> inputFeatures) async {
  Interpreter? _anomaly_interpreter;

  try {
    _anomaly_interpreter = await Interpreter.fromAsset('assets/hopping_anomaly_detector.tflite');
  } catch (e) {
    log('Failed to load model.');
    log(e.toString());
    return false;
  }

  try {
    // Reshape input to match model's expected input shape
    var input = [inputFeatures];
    List<double> output = [0.0];

    _anomaly_interpreter.run(input, output);

    double anomalyScore = output[0];
    log('Anomaly Score: $anomalyScore');

    if (anomalyScore > 500) {
      return true;
    }
    else{
      return false;
    }

  } catch (e) {
    log('Error running the model:');
    log(e.toString());
    return false;
  } finally {
    _anomaly_interpreter.close();
  }
}