import 'package:data_collection/bluetooth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  String gender = 'Male';
  String grade = 'Nursery';
  final List<String> genders = ['Male', 'Female'];
  final List<String> grades = [
    'Nursery',
    'Kindergarten',
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th'
  ];
  String exercise = 'single_hand';
  final Map<String, List> exercises = {
    "single_hand": [1],
    "both_hands": [3, 4],
    "hands_and_ball": [1, 2, 3],
    "all_sensors": [1, 2, 3, 4, 5],
    "Dribbling in Fig - 8": [1, 2, 3, 4, 5],
    "Dribbling in Fig - O": [1, 2, 3, 4, 5],
    "Jumping Jack with Clap": [1, 2, 3, 4],
    "Jumping Jack without Clap": [3, 4],
    "Criss Cross with Clap": [1, 2, 3, 4],
    "Criss Cross without Clap": [3, 4],
    "Criss Cross with leg forward": [3, 4],
    "Skipping": [1, 2, 3, 4],
    "Large Ball Bounce and Catch": [1, 2, 5],
    "Hit Balloon Up": [1, 2],
    "Forward Backward Spread Legs and Back": [3, 4],
    "Alternate feet forward backward": [3, 4],
    "Jump symmetrically": [3, 4],
    "Jump asymmetrically": [3, 4],
    "Hop between lines": [3, 4],
    "Hope forward on one leg": [3, 4],
    "Step Down from Height": [3, 4],
    "Step over an obstacle": [3, 4],
    "Stand on one leg (dominant)": [3, 4],
    "Stand on one leg (non-dominant)": [3, 4],
  };

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
              SizedBox(height: screenHeight * 0.07),
              TextField(
                controller: _studentNameController,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontsize,
                ),
                decoration: const InputDecoration(label: Text('Student Name')),
              ),
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
                items: grades.map((grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    grade = newValue!;
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
                items: exercises.keys.map((exercise) {
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BluetoothScreen(
                          sensors: exercises[exercise] ?? [],
                          schoolName: _schoolNameController.text,
                          studentName: _studentNameController.text,
                          grade: grade,
                          exerciseName: exercise,
                          allowedDeviceNames: ['Sense Right Hand', 'Sense Left Hand', 'Sense Right Leg', 'Sense Left Leg', 'Sense Ball'], // Add your allowed device names here
                        ),
                      ),
                    );
                  },
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
