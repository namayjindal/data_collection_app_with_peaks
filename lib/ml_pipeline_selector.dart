// ml_pipeline_selector.dart

import 'package:data_collection/utils.dart';
import 'package:data_collection/ml_pipelines/ball_bounce_and_catch/peak_detection.dart' as ballBounceAndCatch;
import 'package:data_collection/ml_pipelines/criss_cross_with_claps/peak_detection.dart' as crissCrossWithClaps;
import 'package:data_collection/ml_pipelines/criss_cross_without_claps/peak_detection.dart' as crissCrossWithoutClaps;
import 'package:data_collection/ml_pipelines/hopping/peak_detection.dart' as hopping;
import 'package:data_collection/ml_pipelines/dribbling/peak_detection.dart' as dribbling;
import 'package:data_collection/ml_pipelines/skipping/peak_detection.dart' as skipping;

Future<List<int>> processExerciseData(String exerciseName, List<List<dynamic>> csvData) async {
  // Retrieve the model name corresponding to the exercise
  String? model = exerciseToModel[exerciseName];

  if (model == null) {
    throw Exception("No model found for the exercise: $exerciseName");
  }

  // Call the corresponding ML pipeline based on the model name
  switch (model) {
    case 'ball_bounce_and_catch':
      return await ballBounceAndCatch.processPeakData(csvData);

    case 'criss_cross_with_claps':
      return await crissCrossWithClaps.processPeakData(csvData);

    case 'criss_cross_without_claps':
      return await crissCrossWithoutClaps.processPeakData(csvData);

    case 'hopping':
      return await hopping.processPeakData(csvData);

    case 'dribbling_in_fig_o':
    case 'dribbling_in_fig_8':
      return await dribbling.processPeakData(csvData);

    case 'skipping':
      return await skipping.processPeakData(csvData);

    default:
      throw Exception("No ML pipeline defined for the model: $model");
  }
}
