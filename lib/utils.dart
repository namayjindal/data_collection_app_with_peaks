final List<Map<String, String>> sensorPrefixes = [
    {'name': 'Sense Right Hand', 'prefix': 'right_hand_'},
    {'name': 'Sense Left Hand', 'prefix': 'left_hand_'},
    {'name': 'Sense Right Leg', 'prefix': 'right_leg_'},
    {'name': 'Sense Left Leg', 'prefix': 'left_leg_'},
    {'name': 'Sense Ball', 'prefix': 'ball_'},
    {'name': 'Sakshi Right Hand', 'prefix': 'right_hand_'},
    {'name': 'Sakshi Left Hand', 'prefix': 'left_hand_'},
    {'name': 'Sakshi Right Leg', 'prefix': 'right_leg_'},
    {'name': 'Sakshi Left Leg', 'prefix': 'left_leg_'},
    {'name': 'XIAO BLE Sense', 'prefix': 'xiao_'},
  ];

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

final Map<String, String> exerciseToModel = {
    "Step Down from Height (dominant)": 'step_down_from_height',
    "Step Down from Height (non-dominant)": 'step_down_from_height',
    "Step over an obstacle (dominant)": 'step_over_obstacle',
    "Step over an obstacle (non-dominant)": 'step_over_obstacle',
    "Jump symmetrically": 'jump_symmetrically',
    "Hit Balloon Up": 'hit_balloon_up',
    "Stand on one leg (dominant)": 'stand_on_one_leg',
    "Hop forward on one leg (dominant)": 'hopping',
    "Hop forward on one leg (non-dominant)": 'hopping',
    "Jumping Jack without Clap": 'jumping_jack_without_claps',
    "Hop 9 metres (dominant)": 'hopping',
    "Hop 9 metres (non-dominant)": 'hopping',
    "Skipping": 'skipping',
    "Ball Bounce and Catch": 'ball_bounce_and_catch',
    "Criss Cross with leg forward": 'criss_cross_without_claps',
    "Dribbling in Fig - O": 'dribbling_in_fig_o',
    "Criss Cross with Clap": 'criss_cross_with_claps',
    "Dribbling in Fig - 8": 'dribbling_in_fig_8',
    "Forward Backward Spread Legs and Back": 'alternate_forward_backward_legs',
  };