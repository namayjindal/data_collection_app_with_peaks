import 'package:tflite_flutter/tflite_flutter.dart';

Future<bool> runTFLiteModel(List<double> inputFeatures) async {
  Interpreter? _anomaly_interpreter;

  try {
    _anomaly_interpreter = await Interpreter.fromAsset('assets/hopping_anomaly_detector.tflite');
  } catch (e) {
    print('Failed to load model.');
    print(e);
    return false;
  }

  if (_anomaly_interpreter == null) {
    print('Interpreter is null after loading.');
    return false;
  }

  try {
    // Reshape input to match model's expected input shape
    var input = [inputFeatures];
    List<double> output = [0.0];

    _anomaly_interpreter.run(input, output);

    double anomalyScore = output[0];
    print('Anomaly Score: $anomalyScore');

    if (anomalyScore > 500) {
      return true;
    }
    else{
      return false;
    }

  } catch (e) {
    print('Error running the model:');
    print(e);
    return false;
  } finally {
    _anomaly_interpreter.close();
  }
}