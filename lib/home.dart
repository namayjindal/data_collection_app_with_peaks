import 'package:data_collection/bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _schoolNameController = TextEditingController();
  // final TextEditingController _studentNameController = TextEditingController();
  String gender = 'Male';
  String grade = 'Nursery';
  final List<String> genders = ['Male', 'Female'];

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

  String exercise = 'Step Down from Height (dominant)';
  final Map<String, List> exercises = {
    "Step Down from Height (dominant)": [3, 4],
    "Step Down from Height (non-dominant)": [3, 4],
    "Step over an obstacle (dominant)": [3, 4],
    "Step over an obstacle (non-dominant)": [3, 4],
    "Jump symmetrically": [3, 4],
    "Hit Balloon Up": [1, 2],
    "Stand on one leg (dominant)": [3, 4],
    "Stand on one leg (non-dominant)": [3, 4],
    "Hop forward on one leg (dominant)": [3, 4],
    "Hop forward on one leg (non-dominant)": [3, 4],
    "Jumping Jack without Clap": [3, 4],
    "Dribbling in Fig - 8": [1, 2, 3, 4, 5],
    "Dribbling in Fig - O": [1, 2, 3, 4, 5],
    "Jumping Jack with Clap": [1, 2, 3, 4],
    "Criss Cross with Clap": [1, 2, 3, 4],
    "Criss Cross without Clap": [3, 4],
    "Criss Cross with leg forward": [3, 4],
    "Skipping": [1, 2, 3, 4],
    "Large Ball Bounce and Catch": [1, 2, 5],
    "Forward Backward Spread Legs and Back": [3, 4],
    "Alternate feet forward backward": [3, 4],
    "Jump asymmetrically": [3, 4],
    "Hop 9 metres (dominant)": [3, 4],
    "Hop 9 metres (non-dominant)": [3, 4],
  };

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? school = prefs.getString('school');
    String? g = prefs.getString('grade');
    if (school != null && g != null) {
      setState(() {
        _schoolNameController.text = school;
        grade = g;
        exercise = gradeExercises[grade]![0];
      });
    }
  }

  void saveAndNavigate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('school', _schoolNameController.text);
    await prefs.setString('grade', grade);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothScreen(
          sensors: exercises[exercise] ?? [],
          schoolName: _schoolNameController.text,
          // studentName: _studentNameController.text,
          grade: grade,
          exerciseName: exercise,
          allowedDeviceNames: const [
            'Sense Right Hand',
            'Sense Left Hand',
            'Sense Right Leg',
            'Sense Left Leg',
            'Sense Ball'
          ], // Add your allowed device names here
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final paddingHorizontal = screenWidth * 0.05;
    final paddingVertical = screenHeight * 0.03;
    final fontsize = screenWidth * 0.06;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Demo'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
          vertical: paddingVertical,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _schoolNameController,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontsize,
                ),
                decoration: const InputDecoration(label: Text('School Name')),
              ),
              // SizedBox(height: screenHeight * 0.07),
              // TextField(
              //   controller: _studentNameController,
              //   style: TextStyle(
              //     color: Colors.black,
              //     fontSize: fontsize,
              //   ),
              //   decoration: const InputDecoration(label: Text('Student Name')),
              // ),
              SizedBox(height: screenHeight * 0.07),
              Text(
                'Grade',
                style: TextStyle(color: Colors.black, fontSize: fontsize),
              ),
              SizedBox(height: screenHeight * 0.01),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'Select Grade',
                ),
                value: grade,
                items: gradeExercises.keys.map((grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    grade = newValue!;
                    exercise = gradeExercises[grade]![0];
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.07),
              Text(
                'Gender',
                style: TextStyle(color: Colors.black, fontSize: fontsize),
              ),
              SizedBox(height: screenHeight * 0.01),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'Gender',
                ),
                value: gender,
                items: genders.map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.07),
              Text(
                'Exercise',
                style: TextStyle(color: Colors.black, fontSize: fontsize),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'Select Exercise',
                ),
                value: exercise,
                items: gradeExercises[grade]!.map((exercise) {
                  return DropdownMenuItem<String>(
                    value: exercise,
                    child: Text(exercise),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    exercise = newValue!;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.07),
              Center(
                child: ElevatedButton(
                  onPressed: saveAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: paddingHorizontal,
                      vertical: paddingVertical * 0.5,
                    ),
                  ),
                  child: Text(
                    'SCAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontsize,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
