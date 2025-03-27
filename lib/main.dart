// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===============================
// GLOBAL VARIABLES
// ===============================

// Owner's profile (must be filled before using services)
Map<String, String>? ownerProfile;

// Pet profiles (each is a map with keys: name, age, gender, type, photo, bio, memories)
List<Map<String, dynamic>> petProfiles = []; // Store pet profiles here

// Histories (stored during the session)
List<String> updates = [];
List<Map<String, dynamic>> bookedAppointments = [];
List<Map<String, dynamic>> dietMeals = [];
List<Map<String, dynamic>> vaccinationRecords = [];
List<Map<String, dynamic>> groomingSchedules = [];


// ===============================
// MAIN
// ===============================
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawsitive Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(primary: Colors.cyan, secondary: Colors.redAccent),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

// ===============================
// LOGIN PAGE
// ===============================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Function for Login
  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final authService = AuthService();

    try {
      // Attempt to sign in with email and password
      final user = await authService.signInWithEmailPassword(email, password);

      if (user != null) {
        // Login successful, navigate to home page
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account does not exist')),
          );
        } else if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect password')),
          );
        }
      }
    }
  }

  // Function for Register
  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final authService = AuthService();

    try {
      final user = await authService.registerWithEmailPassword(email, password);

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error during registration')),
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account already registered')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/login_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 0, 0, 0.75),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pawsitive Care',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color.fromARGB(255, 255, 193, 7),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(_emailController, 'Email', Icons.email),
                  const SizedBox(height: 15),
                  _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Login Button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 255, 193, 7),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: Color.fromRGBO(0, 0, 0, 0.3),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Register Button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 0, 123, 255),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: Color.fromRGBO(0, 0, 0, 0.3),
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color.fromARGB(230, 240, 240, 240),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}

// ===============================
// HOME PAGE (Bottom Navigation)
// ===============================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of tabs/screens to navigate between
  final List<Widget> _tabs = [
    ServicesPage(),
    OwnerProfilePage(),
    PetProfilesPage(),
  ];

  // Function to handle tap on bottom navigation items
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Text(
                'Pawsitive Care',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              backgroundColor: Color(0xFF006D6B), // Deep Teal Blue
              elevation: 4.0,
              actions: [
                IconButton(
                  icon: Icon(Icons.history, color: Colors.white),
                  tooltip: 'History',
                  onPressed: () {
                    // Navigate to the HistoryPage and pass the booked salons
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null, // AppBar disappears for OwnerProfilePage and PetProfilesPage
      body: _tabs[_selectedIndex], // Display the selected tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Keeps track of the selected tab index
        selectedItemColor: Colors.cyan, // Color for selected item
        unselectedItemColor: Colors.grey, // Color for unselected items
        onTap: _onItemTapped, // On tap callback
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.miscellaneous_services),
            label: 'Services', // Label for Services tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Profile', // Label for Profile tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Pet Profiles', // Label for Pet Profiles tab
          ),
        ],
      ),
    );
  }
}

// ===============================
// HISTORY PAGE
// ===============================
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // Date format
  String formatDate(Timestamp timestamp) {
    var date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  // Function to delete history from Firestore
  Future<void> _deleteHistory(BuildContext context) async {
    // Delete vet appointments
    var appointments = await FirebaseFirestore.instance.collection('vetAppointments').get();
    for (var doc in appointments.docs) {
      await doc.reference.delete();
    }

    // Delete vaccination history
    var vaccinations = await FirebaseFirestore.instance.collection('vaccinationHistory').get();
    for (var doc in vaccinations.docs) {
      await doc.reference.delete();
    }

    // Delete grooming history
    var groomingBookings = await FirebaseFirestore.instance.collection('grooming_bookings').get();
    for (var doc in groomingBookings.docs) {
      await doc.reference.delete();
    }

    // Delete adoption history
    var adoptions = await FirebaseFirestore.instance.collection('adoptedPets').get();
    for (var doc in adoptions.docs) {
      await doc.reference.delete();
    }

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All history has been deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 33, 33, 33), // Dark charcoal black
      appBar: AppBar(
        title: Text("History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFF008080), // Teal color
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () {
              _deleteHistory(context); // Pass context to the delete function
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vet Appointment History Section
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vetAppointments').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("No Vet Appointments", style: TextStyle(color: Colors.white, fontSize: 18)),
                    );
                  }

                  var appointments = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vet Appointments', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ListView.builder(
                        itemCount: appointments.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          var appointment = appointments[index].data() as Map<String, dynamic>;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            color: Colors.grey[850],
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(appointment['vet'], style: TextStyle(color: Colors.white)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pet: ${appointment['pet']}', style: TextStyle(color: Colors.white70)),
                                  Text('Appointment: ${formatDate(appointment['timestamp'])}', style: TextStyle(color: Colors.white70)),
                                  Text('Email: ${appointment['email']}', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 30),

              // Vaccination History Section
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vaccinationHistory').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("No Vaccination History", style: TextStyle(color: Colors.white, fontSize: 18)),
                    );
                  }

                  var vaccinations = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vaccination History', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ListView.builder(
                        itemCount: vaccinations.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          var vaccination = vaccinations[index].data() as Map<String, dynamic>;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            color: Colors.grey[850],
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(vaccination['vetStore'], style: TextStyle(color: Colors.white)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pet: ${vaccination['petType']}', style: TextStyle(color: Colors.white70)),
                                  Text('Vaccine: ${vaccination['vaccine']}', style: TextStyle(color: Colors.white70)),
                                  Text('Date: ${formatDate(vaccination['timestamp'])}', style: TextStyle(color: Colors.white70)),
                                  Text('Contact: ${vaccination['contact']}', style: TextStyle(color: Colors.white70)),
                                  Text('Email: ${vaccination['email']}', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 30),

              // Grooming History Section
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('grooming_bookings').orderBy('dateTime', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("No Grooming History", style: TextStyle(color: Colors.white, fontSize: 18)),
                    );
                  }

                  var groomingBookings = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Grooming History', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ListView.builder(
                        itemCount: groomingBookings.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          var booking = groomingBookings[index].data() as Map<String, dynamic>;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            color: Colors.grey[850],
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(booking['salonName'], style: TextStyle(color: Colors.white)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pet: ${booking['petType']}', style: TextStyle(color: Colors.white70)),
                                  Text('Services: ${booking['services'].join(', ')}', style: TextStyle(color: Colors.white70)),
                                  Text('Date: ${formatDate(booking['dateTime'])}', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 30),

              // Pet Adoption History Section (Moved to the last)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('adoptedPets').orderBy('adoptedAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("No Pet Adoption History", style: TextStyle(color: Colors.white, fontSize: 18)),
                    );
                  }

                  var adoptions = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pet Adoption History', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ListView.builder(
                        itemCount: adoptions.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          var adoption = adoptions[index].data() as Map<String, dynamic>;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            color: Colors.grey[850],
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(adoption['name'], style: TextStyle(color: Colors.white)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Breed: ${adoption['breed']}', style: TextStyle(color: Colors.white70)),
                                  Text('Age: ${adoption['age']} | Gender: ${adoption['gender']} | Type: ${adoption['type']}', style: TextStyle(color: Colors.white70)),
                                  Text('Adopted on: ${formatDate(adoption['adoptedAt'])}', style: TextStyle(color: Colors.white70)),
                                  Text('Owner: ${adoption['ownerName']}', style: TextStyle(color: Colors.white)),
                                  Text('Contact: ${adoption['contact']}', style: TextStyle(color: Colors.white)),
                                  Text('Email: ${adoption['email']}', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================
// SERVICE PAGE
// ===============================
class ServicesPage extends StatelessWidget {
  final List<_FeatureItem> features = [
    _FeatureItem(title: 'Vet Appointment', icon: Icons.calendar_today, destination: VetAppointmentPage()),
    _FeatureItem(title: 'Diet Tracker', icon: Icons.restaurant_menu, destination: DietTrackerPage()),
    _FeatureItem(title: 'Vaccines', icon: Icons.medical_services, destination: VaccinationTrackerPage()),
    _FeatureItem(title: 'Grooming', icon: Icons.content_cut, destination: GroomingTrackerPage()),
    _FeatureItem(title: 'Expense Tracker', icon: Icons.attach_money, destination: ExpenseTrackerPage()),
    _FeatureItem(title: 'Pet Adoption', icon: Icons.volunteer_activism, destination: PetAdoptionPage()),
  ];

  ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Color?> cardColors = [
      Colors.cyan[100],
      Colors.red[100],
      Colors.green[100],
      Colors.yellow[100],
      Colors.purple[100],
      Colors.orange[100],
    ];

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SingleChildScrollView( // Wrap the entire body with SingleChildScrollView
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              // GridView (Inside Column)
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => feature.destination));
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          color: cardColors[index % cardColors.length],
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Icon(feature.icon, size: 40, color: Colors.black87),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          feature.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 30),

              // Image Carousel
              Card(
                color: Colors.yellow[300],
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          List<String> imagePaths = [
                            'assets/images/f1.jpeg',
                            'assets/images/f2.png',
                            'assets/images/f3.jpeg',
                          ];
                          List<String> captions = [
                            'Track your pet health',
                            'Keep up with their needs',
                            'Ensure their happiness',
                          ];
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: Image.asset(
                                  imagePaths[index],
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: double.infinity,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  captions[index],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    backgroundColor: Colors.yellow[300],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20), // Space before the feedback button

              // Feedback Button at the bottom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the feedback page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FeedbackPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Button color
                    padding: EdgeInsets.symmetric(vertical: 16), // Button height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    minimumSize: Size(double.infinity, 50), // Full width
                  ),
                  child: Text(
                    'Feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10), // Add a little space for the scrollable content
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final IconData icon;
  final Widget destination;
  _FeatureItem({required this.title, required this.icon, required this.destination});
}

// ===============================
// FEEDBACK PAGE
// ===============================
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _feedbackController = TextEditingController();
  String _confirmationMessage = '';

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit feedback and save to Firestore
  void _submitFeedback() async {
    String feedback = _feedbackController.text.trim();
    if (feedback.isNotEmpty) {
      try {
        // Add feedback to Firestore collection
        await _firestore.collection('feedback').add({
          'feedback': feedback,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update confirmation message
        setState(() {
          _confirmationMessage = 'Feedback submitted successfully!';
        });

        // Reset the feedback form
        _feedbackController.clear();
      } catch (e) {
        setState(() {
          _confirmationMessage = 'Error submitting feedback. Please try again later.';
        });
      }
    } else {
      setState(() {
        _confirmationMessage = 'Please write some feedback before submitting.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Provide Your Feedback',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/feedback_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We value your feedback!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Poppins'),
              ),
              SizedBox(height: 20),
              Text(
                'Please share your thoughts with us.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 0, 0, 0.7), fontFamily: 'Poppins'),
              ),
              SizedBox(height: 30),
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Write your feedback here...',
                  hintStyle: TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Color.fromRGBO(0, 0, 0, 0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Submit Feedback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
                ),
              ),
              SizedBox(height: 20),
              if (_confirmationMessage.isNotEmpty)
                Text(
                  _confirmationMessage,
                  style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================
// OWNER PROFILE PAGE (Owner Details)
// ===============================
class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key});

  @override
  _OwnerProfilePageState createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  Uint8List? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isChanged = false;

  // Firebase Firestore and Firebase Auth instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _pickProfilePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageBytes = await image.readAsBytes();
      setState(() {
        _profileImage = imageBytes;
        _isChanged = true;
      });
    }
  }

  bool isValidPhone(String value) {
    final RegExp phoneRegExp = RegExp(r'^\d{10}$');
    return phoneRegExp.hasMatch(value);
  }

  bool isValidEmail(String value) {
    final RegExp emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegExp.hasMatch(value);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user
        User? user = _auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please log in first!')));
          return;
        }

        String? photoUrl = '';
        // If image is not null, store a placeholder URL (no image upload to Firebase Storage)
        if (_profileImage != null) {
          photoUrl = 'https://example.com/default-profile-image.png'; // Replace with your default image URL
        }

        // Save or update data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'profile_image': photoUrl,  // This can be a URL or null
        }, SetOptions(merge: true)); // Merge to update fields instead of overwriting the document

        setState(() {
          _isChanged = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete the profile with valid details!')),
      );
    }
  }

  void _loadProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      }
    }
  }

  void _logout() {
    _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          if (isNumeric && !isValidPhone(value.trim())) {
            return 'Enter a valid 10-digit phone number';
          }
          if (!isNumeric && label == "Email" && !isValidEmail(value.trim())) {
            return 'Enter a valid email address';
          }
          return null; // No error
        },
        onChanged: (value) {
          setState(() {
            _isChanged = true; // Update state
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/user_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: const Color.fromARGB(19, 255, 255, 255).withAlpha(180),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickProfilePhoto,
                          child: Column(
                            children: [
                              _profileImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.memory(
                                        _profileImage!,
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.grey[300],
                                      child: Icon(Icons.person,
                                          size: 40, color: Colors.grey[700]),
                                    ),
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickProfilePhoto,
                                icon: Icon(Icons.photo_library, size: 18),
                                label: Text("Select Profile Photo"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTextField(_nameController, "Name"),
                        _buildTextField(_phoneController, "Phone Number", isNumeric: true),
                        _buildTextField(_emailController, "Email"),
                        _buildTextField(_addressController, "Address"),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_isChanged && _allFieldsFilled())
                              _buildButton("Save Profile", Colors.green, _saveProfile),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: _logout,
              icon: Icon(Icons.logout, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: TextStyle(color: Colors.white)),
    );
  }

  bool _allFieldsFilled() {
    return _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _addressController.text.isNotEmpty;
  }
}

// ===============================
// PET PROFILES PAGE (Manage Pet Profiles)
// ===============================
class PetProfilesPage extends StatefulWidget {
  const PetProfilesPage({super.key});

  @override
  _PetProfilesPageState createState() => _PetProfilesPageState();
}

class _PetProfilesPageState extends State<PetProfilesPage> {
  final TextEditingController petNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String selectedGender = "Male";
  String selectedPetType = "Dog";
  Uint8List? pickedImage; // Stores the selected pet image locally
  Map<String, Uint8List> petImages = {}; // Store images locally by petId

  // Function to pick an image
  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        pickedImage = result.files.first.bytes;
      });
    }
  }

  // Function to save pet profile (without image in Firestore)
  Future<void> savePetProfile() async {
    if (petNameController.text.isEmpty || ageController.text.isEmpty || pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All fields, including the pet photo, are required!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('pet_profiles').add({
        'name': petNameController.text,
        'age': ageController.text,
        'gender': selectedGender,
        'type': selectedPetType,
        'bio': '',
        'activities': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Store image locally
      setState(() {
        petImages[docRef.id] = pickedImage!; // Store image by petId
        petNameController.clear();
        ageController.clear();
        selectedGender = "Male";
        selectedPetType = "Dog";
        pickedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pet Profile Saved Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to delete a profile from Firestore
  void deleteProfile(String petId) async {
    try {
      await FirebaseFirestore.instance.collection('pet_profiles').doc(petId).delete();
      setState(() {
        petImages.remove(petId); // Remove the image from local storage
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile deleted successfully!"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("Error deleting profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/petprofile_bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: Colors.white.withAlpha(200),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        "Manage Pet Profiles",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: petNameController,
                        decoration: InputDecoration(
                          labelText: "Pet Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Age",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        items: ["Male", "Female"]
                            .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Gender",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedPetType,
                        items: ["Dog", "Cat", "Rabbit", "Hamster"]
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPetType = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Pet Category",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 15),

                      // Image Picker Section
                      GestureDetector(
                        onTap: pickImage,
                        child: Column(
                          children: [
                            pickedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.memory(
                                      pickedImage!,
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(Icons.pets, size: 40, color: Colors.grey[700]),
                                  ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: pickImage,
                              icon: Icon(Icons.photo_library, size: 18),
                              label: Text("Select Pet Photo"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: savePetProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("Save Pet Profile", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                      SizedBox(height: 30),
                      Text(
                        "Your Pet Profiles",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      SizedBox(height: 20),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('pet_profiles').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Text("No profiles saved yet!", style: TextStyle(fontSize: 18, color: Colors.grey));
                          }

                          var petProfiles = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: petProfiles.length,
                            itemBuilder: (context, index) {
                              var pet = petProfiles[index].data() as Map<String, dynamic>;
                              String petId = petProfiles[index].id;

                              return ListTile(
                                leading: petImages[petId] != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          petImages[petId]!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(Icons.pets, size: 40, color: Colors.grey),
                                title: Text(pet['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${pet['age']} years old, ${pet['gender']}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PetProfileDetailPage(
                                              petId: petId,  // ✅ Already passed
                                              petImage: petImages[petId],  // ✅ FIXED: Now passing the pet image
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteProfile(petId),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// PET DETAILS PAGE
// ===============================

class PetProfileDetailPage extends StatefulWidget {
  final String petId; // Firestore document ID
  final Uint8List? petImage; // Pet image passed from PetProfilesPage

  const PetProfileDetailPage({super.key, required this.petId, required this.petImage});

  @override
  _PetProfileDetailPageState createState() => _PetProfileDetailPageState();
}

class _PetProfileDetailPageState extends State<PetProfileDetailPage> {
  Map<String, dynamic>? pet;
  late TextEditingController bioController;
  late TextEditingController activityController;
  List<String> activities = [];
  Uint8List? displayedPetImage; // Store the pet image locally to persist it

  @override
  void initState() {
    super.initState();
    fetchPetDetails(); // Fetch pet details from Firestore
    _loadPetImage(); // Load saved pet image from SharedPreferences
  }

  // Fetch pet details from Firebase Firestore
  Future<void> fetchPetDetails() async {
    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('pet_profiles').doc(widget.petId).get();
      if (snapshot.exists) {
        setState(() {
          pet = snapshot.data() as Map<String, dynamic>;
          bioController = TextEditingController(text: pet!['bio'] ?? '');
          activities = List<String>.from(pet!['activities'] ?? []);
          activityController = TextEditingController();
        });
      }
    } catch (e) {
      debugPrint("Error fetching pet details: $e");
    }
  }

  // Save pet image to SharedPreferences as base64

  // Load pet image from SharedPreferences
  Future<void> _loadPetImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('pet_image_base64');
    if (base64Image != null) {
      setState(() {
        displayedPetImage = base64Decode(base64Image);
      });
    } else {
      setState(() {
        displayedPetImage = widget.petImage; // Use the image passed from the constructor
      });
    }
  }

  // Save bio changes to Firebase
  void _saveBio() async {
    if (pet == null) return;

    try {
      await FirebaseFirestore.instance.collection('pet_profiles').doc(widget.petId).update({
        'bio': bioController.text.trim(),
      });

      setState(() {
        pet!['bio'] = bioController.text.trim();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Bio updated successfully!")));
    } catch (e) {
      debugPrint("Error updating bio: $e");
    }
  }

  // Add a new activity to Firebase
  void _addActivity() async {
    String activity = activityController.text.trim();
    if (activity.isEmpty || pet == null) return;

    try {
      activities.add(activity);
      await FirebaseFirestore.instance.collection('pet_profiles').doc(widget.petId).update({
        'activities': activities,
      });

      setState(() {
        pet!['activities'] = activities;
        activityController.clear();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Activity added successfully!")));
    } catch (e) {
      debugPrint("Error adding activity: $e");
    }
  }

  // Edit an existing activity in Firebase

  // Delete an activity from Firebase
  void _deleteActivity(int index) async {
    if (pet == null) return;

    try {
      activities.removeAt(index);
      await FirebaseFirestore.instance.collection('pet_profiles').doc(widget.petId).update({
        'activities': activities,
      });

      setState(() {
        pet!['activities'] = activities;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Activity deleted successfully!")));
    } catch (e) {
      debugPrint("Error deleting activity: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pet == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${pet!['name']}\'s Profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color.fromARGB(123, 57, 57, 57),
        elevation: 5,
      ),
      backgroundColor: const Color.fromARGB(199, 48, 48, 48), // Dark theme background
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Pet Image at the Top in Circle
            Center(
              child: displayedPetImage != null
                  ? CircleAvatar(
                      radius: 60,
                      backgroundImage: MemoryImage(displayedPetImage!),
                    )
                  : CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[700],
                      child: Icon(Icons.pets, size: 50, color: Colors.white),
                    ),
            ),
            SizedBox(height: 20),

            // Pet Profile Info Card
            Card(
              color: Colors.grey[900], // Dark theme card
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 10,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Pet Name
                    Text('${pet!['name']} (${pet!['type']})',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
                    SizedBox(height: 8),
                    Text('Age: ${pet!['age']} | Gender: ${pet!['gender']}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70)),
                    SizedBox(height: 8),
                    Text(pet!['bio'].isNotEmpty ? pet!['bio'] : 'No bio available',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.white54)),
                    SizedBox(height: 15),
                    // Edit Bio Section
                    TextField(
                      controller: bioController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a bio for ${pet!['name']}...',
                        hintStyle: TextStyle(color: Colors.white60),
                        fillColor: Colors.grey[800],
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _saveBio,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: Text("Save Bio"),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            // Favorite Activities Section
            Card(
              color: const Color.fromARGB(255, 31, 31, 31),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("Favorite Activities",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                    SizedBox(height: 10),
                    TextField(
                      controller: activityController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a new activity...',
                        hintStyle: TextStyle(color: Colors.white60),
                        fillColor: Colors.grey[800],
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addActivity,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: Text("Add Activity"),
                    ),
                    SizedBox(height: 15),
                    activities.isEmpty
                        ? Text("No activities added yet!", style: TextStyle(fontSize: 16, color: Colors.white54))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: activities.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(activities[index], style: TextStyle(color: Colors.white, fontSize: 16)),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteActivity(index),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ------------------------------
// VET APPOINTMENT PAGE
// ------------------------------
class VetAppointmentPage extends StatefulWidget {
  const VetAppointmentPage({super.key});

  @override
  _VetAppointmentPageState createState() => _VetAppointmentPageState();
}

class _VetAppointmentPageState extends State<VetAppointmentPage> {
  final List<Map<String, String>> vets = [
    {
      'name': 'Dr. Faris Khan',
      'experience': '10 years',
      'rating': '4.5',
      'fees': '₹500',
      'contact': '9876543210',
      'email': 'faris@example.in'
    },
    {
      'name': 'Dr. Atif Ansari',
      'experience': '8 years',
      'rating': '4.2',
      'fees': '₹450',
      'contact': '9123456780',
      'email': 'atif321@example.in'
    },
    {
      'name': 'Dr. Anjali Sharma',
      'experience': '12 years',
      'rating': '4.8',
      'fees': '₹600',
      'contact': '9988776655',
      'email': 'anjali.sharma@example.in'
    },
    {
      'name': 'Dr. Jack Harris',
      'experience': '9 years',
      'rating': '4.3',
      'fees': '₹480',
      'contact': '9876501234',
      'email': 'jackh@example.in'
    },
    {
      'name': 'Dr. Meera Joshi',
      'experience': '11 years',
      'rating': '4.7',
      'fees': '₹550',
      'contact': '9123987654',
      'email': 'meera.joshi@example.in'
    },
  ];

  DateTime? selectedDateTime;
  String? selectedPet;
  bool isBooked = false; // To track if an appointment is already booked
  final List<Map<String, dynamic>> bookedAppointments = [];

  List<Map<String, dynamic>> petProfiles = []; // List to store pet profiles

  @override
  void initState() {
    super.initState();
    _loadPetProfiles(); // Load pet profiles from Firestore
  }

  // Fetch pet profiles from Firestore
  Future<void> _loadPetProfiles() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pet_profiles').get();
      setState(() {
        petProfiles = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint("Error fetching pet profiles: $e");
    }
  }

  void _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() {
          selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _confirmBooking(Map<String, dynamic> vet) async {
    if (selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select date & time')));
      return;
    }
    if (selectedPet == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('No Pet Selected'),
          content: Text('Please select a pet first.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK'))],
        ),
      );
      return;
    }

    final dateStr = selectedDateTime!.toString().substring(0, 16);

    try {
      await FirebaseFirestore.instance.collection('vetAppointments').add({
        'vet': vet['name'],
        'dateTime': dateStr,
        'email': vet['email'],
        'pet': selectedPet,
        'timestamp': FieldValue.serverTimestamp(), // Sort appointments by time
      });

      setState(() {
        isBooked = true;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Appointment Confirmed'),
          content: Text('Your appointment with ${vet['name']} for $selectedPet is set for $dateStr.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error booking appointment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Vet Appointment Booking',
        style: TextStyle(color: Colors.white), // Set the text color to white
      ),
      backgroundColor: const Color.fromARGB(221, 41, 41, 41),
      iconTheme: IconThemeData(color: Colors.white),
    ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/vet_bg.jpg"),
            fit: BoxFit.cover,  // Ensure the background image fully covers the screen
          ),
        ),
        height: MediaQuery.of(context).size.height, // Ensures the background image takes full height of the screen
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Pet Selection Dropdown
              DropdownButtonFormField<String>(
                value: selectedPet,
                decoration: InputDecoration(
                  labelText: 'Select Pet',
                  labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                  filled: true,
                  fillColor: const Color.fromARGB(111, 159, 158, 158),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: petProfiles.isNotEmpty
                    ? petProfiles
                        .map((pet) => DropdownMenuItem<String>(
                              value: pet['name'] as String,
                              child: Text(
                                pet['name'] as String,
                                style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                              ),
                            ))
                        .toList()
                    : [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('No pets available', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                onChanged: (val) {
                  setState(() {
                    selectedPet = val;
                  });
                },
              ),
              SizedBox(height: 20),
              // Pick Date & Time Button
              ElevatedButton.icon(
                onPressed: _pickDateTime,
                icon: Icon(Icons.date_range, color: Colors.black),
                label: Text(
                  selectedDateTime == null ? 'Pick Date & Time' : 'Change Date & Time',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow, // Match with the Pick Date button style
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              SizedBox(height: 20),
              // Only show vet cards if pet and date/time are selected
              if (selectedPet != null && selectedDateTime != null && !isBooked)
                Column(
                  children: vets.map((vet) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 12,
                      color: Colors.black87,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medical_services, size: 40, color: Colors.cyan),
                                SizedBox(width: 10),
                                Text(
                                  vet['name']!,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Experience: ${vet['experience']}',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              'Rating: ${vet['rating']} ⭐',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              'Fees: ${vet['fees']}',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              'Contact: ${vet['contact']}',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              'Email: ${vet['email']}',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end, // Align button to the right
                              children: [
                                ElevatedButton(
                                  onPressed: () => _confirmBooking(vet),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text('Book', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------
// DIET TRACKER PAGE
// ------------------------------

class DietTrackerPage extends StatefulWidget {
  const DietTrackerPage({super.key});

  @override
  _DietTrackerPageState createState() => _DietTrackerPageState();
}

class _DietTrackerPageState extends State<DietTrackerPage> {
  final _mealController = TextEditingController();
  TimeOfDay? selectedTime;
  String? selectedPet;
  List<Map<String, dynamic>> dietMeals = []; // Store the diet meal details
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  @override
  void initState() {
    super.initState();
    _loadDietMeals(); // Load diet meals from Firestore when the page is initialized
  }

  void _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void _addMeal() async {
    if (_mealController.text.trim().isEmpty || selectedTime == null || selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select pet, enter meal, and pick time')));
      return;
    }

    final mealName = _mealController.text.trim();
    final mealData = {
      'meal': mealName,
      'time': selectedTime!.format(context),
      'pet': selectedPet,
      'userId': FirebaseAuth.instance.currentUser?.uid, // Add user ID to associate meals with users
      'hour': selectedTime!.hour,
      'minute': selectedTime!.minute,
    };

    // Save meal data to Firestore
    await _firestore.collection('dietMeals').add(mealData);

    // Update the local list (optional, but it will reflect instantly)
    setState(() {
      dietMeals.add(mealData);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Meal Reminder Added')));

    _mealController.clear();
    selectedTime = null;
  }

  void _deleteMeal(int index) async {
    final meal = dietMeals[index];
    final mealId = meal['id'];

    // Remove meal from Firestore
    await _firestore.collection('dietMeals').doc(mealId).delete();

    setState(() {
      dietMeals.removeAt(index);  // Remove meal from the list
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Meal Reminder Removed')));
  }

  Future<void> _loadDietMeals() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final snapshot = await _firestore.collection('dietMeals')
          .where('userId', isEqualTo: userId) // Filter meals by the current user
          .get();

      setState(() {
        dietMeals = snapshot.docs.map((doc) {
          var data = doc.data();
          return {
            'meal': data['meal'],
            'time': data['time'],
            'pet': data['pet'],
            'id': doc.id,
          };
        }).toList();
      });
    }
  }

  Widget _buildFoodCard(String imagePath, String name, String price, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Card(
        color: Colors.grey[850],
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 100, width: 100, fit: BoxFit.cover),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(price, style: TextStyle(color: Colors.green)),
                  ElevatedButton(
                    onPressed: () => launchUrl(Uri.parse(url)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: Text('Buy Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(
      'Diet Tracker',
      style: TextStyle(color: Colors.white), // Set the text color to white
      ),
      backgroundColor: const Color.fromARGB(221, 41, 41, 41),
      iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/diet_bg.jpg'), fit: BoxFit.cover),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Dropdown for Pet Selection with Black Background and White Font for Text
            DropdownButtonFormField<String>( 
              value: selectedPet,
              decoration: InputDecoration(
                labelText: 'Select Pet',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: const Color.fromARGB(111, 159, 158, 158), // Slightly darker white
              ),
              items: ['Cat', 'Dog', 'Rabbit', 'Hamster']
                  .map((pet) => DropdownMenuItem(
                        value: pet,
                        child: Text(pet, style: TextStyle(color: Colors.black)), // Text inside dropdown items black
                      ))
                  .toList(),
              onChanged: (val) => setState(() => selectedPet = val),
            ),
            SizedBox(height: 10),

            // Meal Name Input Field
            TextField(
              controller: _mealController,
              style: TextStyle(color: Colors.black), // Black text in the input field
              decoration: InputDecoration(
                labelText: 'Meal Name',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: const Color.fromARGB(111, 159, 158, 158), // Slightly darker white
              ),
            ),
            SizedBox(height: 10),

            // Row with two buttons: Pick Time and Add Meal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // First Button - Pick Time
                SizedBox(
                  width: 150, // Adjust the width as needed
                  child: ElevatedButton(
                    onPressed: _pickTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16), // Increased height
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Same border radius
                    ),
                    child: Text(
                      selectedTime == null ? 'Pick Time' : selectedTime!.format(context),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16, // Adjusted font size to match previous buttons
                        fontWeight: FontWeight.w500, // Medium weight for better text appearance
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Adds space between the buttons
                // Second Button - Add Meal
                SizedBox(
                  width: 150, // Adjust the width as needed
                  child: ElevatedButton(
                    onPressed: _addMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16), // Increased height
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Same border radius
                    ),
                    child: Text(
                      'Add Meal',
                      style: TextStyle(
                        fontSize: 16, // Adjusted font size to match previous buttons
                        fontWeight: FontWeight.w500, // Medium weight for better text appearance
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Use ListView.builder inside a SizedBox to avoid overflow issues
            if (dietMeals.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: dietMeals.length,
                itemBuilder: (context, index) {
                  final meal = dietMeals[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                    color: Colors.grey[850],
                    child: ListTile(
                      leading: Icon(Icons.fastfood, color: Colors.orangeAccent),
                      title: Text('${meal['meal']} for ${meal['pet']}', style: TextStyle(color: Colors.white)),
                      subtitle: Text('At: ${meal['time']}', style: TextStyle(color: Colors.white)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMeal(index),
                      ),
                    ),
                  );
                },
              ),
            SizedBox(height: 20),

            // Styled heading
            Text(
              'Recommended Food Items',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Black color for heading
                fontFamily: 'Roboto', // A stylish font
                letterSpacing: 1.5, // Adds spacing for a modern look
              ),
            ),
            SizedBox(
              height: 250, // Adjust height to prevent overflow
              child: Card(
                color: Colors.grey[850],
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10), // Add horizontal padding to the card
                  width: MediaQuery.of(context).size.width * 0.95, // Increase width to 85% of screen width
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFoodCard('assets/images/food1.png', 'Cat Food', '400 Rs', 'https://www.whiskas.in/our-products/dry-food'),
                      _buildFoodCard('assets/images/food2.jpg', 'Dog Food', '680 Rs', 'https://www.pedigree.in/dog-products/dry-dog-food'),
                      _buildFoodCard('assets/images/food3.jpg', 'Rabbit Food', '345 Rs', 'https://www.puprise.com/smartheart-rabbit-food-veggies-cereals-flavour-1kg/'),
                      _buildFoodCard('assets/images/food4.jpg', 'Hamster Food', '380 Rs', 'https://petsleague.com/primus-premium-hamster-food-750-gm.html'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------
// VACCINATION TRACKER PAGE
// ------------------------------
class VaccinationTrackerPage extends StatefulWidget {
  const VaccinationTrackerPage({super.key});

  @override
  _VaccinationTrackerPageState createState() => _VaccinationTrackerPageState();
}
class _VaccinationTrackerPageState extends State<VaccinationTrackerPage> {
  DateTime? selectedDateTime;
  String? selectedPetType;
  String? selectedVaccine;
  bool isVaccinationBooked = false;

  final List<Map<String, dynamic>> vetStores = [];
  final List<String> vaccines = [];

  @override
  void initState() {
    super.initState();
    _fetchVaccines();
    _fetchVetStores();
  }

  void _fetchVaccines() async {
    final vaccineSnapshot = await FirebaseFirestore.instance.collection('vaccines').get();
    setState(() {
      vaccines.addAll(vaccineSnapshot.docs.map((doc) => doc['name'].toString()));
    });
  }

  void _fetchVetStores() async {
    final vetStoreSnapshot = await FirebaseFirestore.instance.collection('vet_stores').get();
    setState(() {
      vetStores.addAll(vetStoreSnapshot.docs.map((doc) => {
        'name': doc['name'],
        'contact': doc['contact'],
        'email': doc['email'],
        'price': doc['price'],
        'image': doc['image'],
      }).toList());
    });
  }

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() {
          selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _bookVetStore(Map<String, dynamic> store) async {
    if (isVaccinationBooked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You cannot book more than one vaccination at a time.')));
    } else {
      setState(() {
        isVaccinationBooked = true;
      });

      // Save vaccination history to Firebase under 'vaccinationHistory' collection
      await FirebaseFirestore.instance.collection('vaccinationHistory').add({
        'petType': selectedPetType,
        'vaccine': selectedVaccine,
        'dateTime': selectedDateTime,
        'vetStore': store['name'],
        'contact': store['contact'],
        'email': store['email'],
        'price': store['price'],
        'image': store['image'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show success message with all details
      _showBookingConfirmationDialog(store);

      // Reset the selections
      setState(() {
        selectedPetType = null;
        selectedVaccine = null;
        selectedDateTime = null;
      });
    }
  }

  void _showBookingConfirmationDialog(Map<String, dynamic> store) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking Confirmation'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedPetType != null) Text('Pet Type: $selectedPetType'),
              if (selectedVaccine != null) Text('Vaccine: $selectedVaccine'),
              if (selectedDateTime != null) Text('Date and Time: ${selectedDateTime?.toLocal().toString()}'),
              SizedBox(height: 10),
              Text('Vet Store: ${store['name']}'),
              Text('Contact: ${store['contact']}'),
              Text('Email: ${store['email']}'),
              Text('Price: ${store['price']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(
      'Vaccination Tracker',
      style: TextStyle(color: Colors.white), // Set the text color to white
      ),
      backgroundColor: const Color.fromARGB(221, 41, 41, 41),
      iconTheme: IconThemeData(color: Colors.white), // Set the back button color to white
      ),

      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/vaccination_bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet Type Dropdown
              DropdownButtonFormField<String>(
                value: selectedPetType,
                decoration: InputDecoration(
                  labelText: 'Select Pet Type',
                  labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: const Color.fromARGB(111, 159, 158, 158),
                ),
                items: ['Dog', 'Cat', 'Rabbit']
                    .map((type) => DropdownMenuItem<String>(value: type, child: Text(type, style: TextStyle(color: Colors.black))))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedPetType = val;
                  });
                },
              ),
              SizedBox(height: 20),

              // Vaccine Dropdown
              DropdownButtonFormField<String>(
                value: selectedVaccine,
                decoration: InputDecoration(
                  labelText: 'Select Vaccine',
                  labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: const Color.fromARGB(111, 159, 158, 158),
                ),
                items: vaccines
                    .map((vaccine) => DropdownMenuItem<String>(value: vaccine, child: Text(vaccine, style: TextStyle(color: Colors.black))))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedVaccine = val;
                  });
                },
              ),
              SizedBox(height: 20),

              // Date & Time picker button
              ElevatedButton.icon(
                onPressed: _pickDateTime,
                icon: Icon(Icons.date_range),
                label: Text(
                  selectedDateTime == null ? 'Pick Date & Time' : 'Change Date & Time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008080),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  minimumSize: Size(150, 50),
                ),
              ),
              SizedBox(height: 20),

              // Vet Store List (only shown if all selections are made)
              if (selectedPetType != null && selectedVaccine != null && selectedDateTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: vetStores.map((store) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      color: Colors.grey[850],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Vet Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                store['image'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 16),
                            // Vet Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(store['name'], style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text('Price: ${store['price']}', style: TextStyle(color: Colors.white)),
                                  Text('Contact: ${store['contact']}', style: TextStyle(color: Colors.white)),
                                  Text('Email: ${store['email']}', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _bookVetStore(store),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                minimumSize: Size(120, 50),
                              ),
                              child: Text('Book Now'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------
// EXPENSE TRACKER PAGE
// ------------------------------
class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({super.key});

  @override
  _ExpenseTrackerPageState createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  final _itemController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? selectedDate;
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses(); // Load saved expenses when the page is initialized
  }

  // Load expenses from SharedPreferences
  _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesString = prefs.getString('expenses');
    if (expensesString != null) {
      final List<dynamic> expensesList = jsonDecode(expensesString);
      setState(() {
        _expenses = List<Map<String, dynamic>>.from(expensesList);
      });
    }
  }

  // Save expenses to SharedPreferences
  _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesString = jsonEncode(_expenses); // Convert to JSON string
    prefs.setString('expenses', expensesString); // Save in SharedPreferences
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  void _addExpense() {
    if (_itemController.text.trim().isEmpty || _amountController.text.trim().isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter all expense details')));
      return;
    }
    double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final dateStr = selectedDate!.toIso8601String().substring(0, 10);
    setState(() {
      _expenses.add({'item': _itemController.text.trim(), 'amount': amount, 'date': dateStr});
    });
    _saveExpenses(); // Save updated expenses list to SharedPreferences
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Expense added')));
    _itemController.clear();
    _amountController.clear();
    selectedDate = null;
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });
    _saveExpenses(); // Save updated expenses list after deletion
  }

  @override
  Widget build(BuildContext context) {
    // Group expenses by month/year
    Map<String, List<Map<String, dynamic>>> groupedExpenses = {};
    for (var exp in _expenses) {
      final monthYear = DateFormat('MMMM yyyy').format(DateTime.parse(exp['date']));
      if (groupedExpenses[monthYear] == null) {
        groupedExpenses[monthYear] = [];
      }
      groupedExpenses[monthYear]!.add(exp);
    }

    // Sort by date in descending order (most recent first)
    var sortedMonthYears = groupedExpenses.keys.toList()
      ..sort((a, b) => DateFormat('MMMM yyyy').parse(b).compareTo(DateFormat('MMMM yyyy').parse(a)));

    return Scaffold(
      appBar: AppBar(
  title: Text(
    'Expense Tracker',
    style: TextStyle(color: Colors.white), // Set the text color to white
    ),
    backgroundColor: const Color.fromARGB(221, 41, 41, 41),
    iconTheme: IconThemeData(color: Colors.white), // Set the back button color to white
    ),

      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/expense_bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item TextField with better design
                _buildTextField(
                  controller: _itemController,
                  label: 'Expense Item',
                ),
                SizedBox(height: 10),

                // Amount TextField with better design
                _buildTextField(
                  controller: _amountController,
                  label: 'Amount (₹)',
                  isAmount: true,
                ),
                SizedBox(height: 10),

                // Buttons in a Row (Pick Date & Add Expense)
                _buildButtonsRow(),
                SizedBox(height: 20),

                // Expenses List grouped by Month
                _buildExpenseList(groupedExpenses, sortedMonthYears),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a text field
  Widget _buildTextField({required TextEditingController controller, required String label, bool isAmount = false}) {
    return TextField(
      controller: controller,
      keyboardType: isAmount ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: const Color.fromARGB(111, 159, 158, 158), // Lighter grey for input fields
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }

  // Helper method to build the date picker button
  Widget _buildDateButton() {
    return ElevatedButton.icon(
      onPressed: _pickDate,
      icon: Icon(Icons.date_range),
      label: Text(
        selectedDate == null ? 'Pick Date' : 'Change Date',
        style: TextStyle(
          fontSize: 16, // Adjust font size
          fontWeight: FontWeight.w500, // Medium weight for better text appearance
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF008080), // Deep teal color (better than cyan)
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Adjusted padding to match Add Expense button
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        minimumSize: Size(150, 50), // Set a fixed width and height (matching Add Expense button)
      ),
    );
  }

  // Helper method to build the "Add Expense" button
  Widget _buildAddExpenseButton() {
    return ElevatedButton(
      onPressed: _addExpense,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Green color for the button
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Adjusted padding
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        minimumSize: Size(150, 50), // Fixed width and height (same as Pick Date button)
      ),
      child: Text(
        'Add Expense',
        style: TextStyle(
          fontSize: 16, // Adjust font size for better appearance
          fontWeight: FontWeight.w500, // Medium weight for better text visibility
        ),
      ),
    );
  }

  // Helper method to build the buttons row
  Widget _buildButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align buttons at the corners
      children: [
        SizedBox(
          width: 160, // Fixed width for the first button
          child: _buildDateButton(),
        ),
        SizedBox(
          width: 160, // Fixed width for the second button
          child: _buildAddExpenseButton(),
        ),
      ],
    );
  }

  // Helper method to build the expense list
  Widget _buildExpenseList(Map<String, List<Map<String, dynamic>>> groupedExpenses, List<String> sortedMonthYears) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sortedMonthYears.length,
      itemBuilder: (context, index) {
        final monthYear = sortedMonthYears[index];
        final expenses = groupedExpenses[monthYear]!;

        // Calculate total expenses for the month
        double totalExpense = 0.0;
        for (var exp in expenses) {
          totalExpense += exp['amount'];
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month and Year Heading
              Text(
                monthYear,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan),
              ),
              SizedBox(height: 10),
              Column(
                children: expenses.map((exp) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Item name, amount and date
                        Text('${exp['item']} - ₹${exp['amount'].toStringAsFixed(2)}', style: TextStyle(color: Colors.white)),
                        Text(DateFormat('dd MMM yyyy').format(DateTime.parse(exp['date'])), style: TextStyle(color: Colors.white70)),
                        // Delete Button
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteExpense(_expenses.indexOf(exp)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              // Total Expense for the month
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Total: ₹${totalExpense.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


// ------------------------------
// GROOMING TRACKER PAGE
// ------------------------------

class GroomingTrackerPage extends StatefulWidget {
  const GroomingTrackerPage({super.key});

  @override
  _GroomingTrackerPageState createState() => _GroomingTrackerPageState();
}

class _GroomingTrackerPageState extends State<GroomingTrackerPage> {
  DateTime? selectedDateTime;
  String? selectedPetType;
  List<String> selectedServices = [];
  String? selectedSalon;

  // Dummy data for grooming services
  List<String> services = [
    "Nail Clipping",
    "Full Body Trim",
    "Ear and Paw Cleaning",
    "Shampoo and Conditioning",
    "Full Body Bath"
  ];

  // Dummy data for pet grooming salons
  List<Map<String, dynamic>> groomingSalons = [
    {
      'name': 'Dogwood',
      'openTime': '8:00 AM',
      'closeTime': '6:00 PM',
      'price': '500 Rs - 4000 Rs',
      'rating': 4.5,
      'contact': '+91 7698453120',
      'email': 'dogwood@dgservice.com',
      'image': 'assets/images/g1.png',
    },
    {
      'name': 'Paws N Claws',
      'openTime': '9:00 AM',
      'closeTime': '7:00 PM',
      'price': '450 Rs - 3500 Rs',
      'rating': 4.8,
      'contact': '+91 9768450315',
      'email': 'pawsnclaws@paradise.com',
      'image': 'assets/images/g2.png',
    },
    {
      'name': 'Vetic',
      'openTime': '8:30 AM',
      'closeTime': '6:30 PM',
      'price': '400 Rs - 5000 Rs',
      'rating': 4.7,
      'contact': '+91 8979462505',
      'email': 'vetic01@serviceforpets.com',
      'image': 'assets/images/g3.png',
    },
    {
      'name': 'Pet House',
      'openTime': '10:00 AM',
      'closeTime': '5:00 PM',
      'price': '450 Rs - 4500 Rs',
      'rating': 4.3,
      'contact': '+91 9586713244',
      'email': 'pethouse@petcare.com',
      'image': 'assets/images/g4.png',
    },
  ];

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pick Date & Time
  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() {
          selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  // Book Salon and save data to Firestore
  void _bookSalon(String salonName) async {
    if (selectedSalon == null) {
      setState(() {
        selectedSalon = salonName;
      });

      // Get the selected salon details
      Map<String, dynamic> selectedSalonDetails = groomingSalons.firstWhere((salon) => salon['name'] == salonName);

      // Save to Firebase Firestore
      await _firestore.collection('grooming_bookings').add({
        'petType': selectedPetType,
        'services': selectedServices,
        'dateTime': selectedDateTime,
        'salonName': salonName,
        'salonDetails': selectedSalonDetails,
      });

      // Display booking confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking for $salonName has been confirmed!')),
      );
      
      // Show confirmation dialog with booking details
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Booking Confirmation'),
            content: Text('Your booking for $selectedPetType at $salonName has been confirmed.\n'
                'Services: ${selectedServices.join(', ')}\n'
                'Date & Time: ${selectedDateTime?.toLocal()}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      // Show error if another salon is selected after booking one
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot book more than one salon at a time.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(
      'Grooming Tracker',
      style: TextStyle(color: Colors.white), // Set the text color to white
      ),
    backgroundColor: const Color.fromARGB(221, 41, 41, 41),
    iconTheme: IconThemeData(color: Colors.white), // Set the back button color to white
    ),

      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/grooming_bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet Type Dropdown
                _buildPetTypeDropdown(),
                SizedBox(height: 20),

                // Grooming Services (Multiple selection using checkboxes)
                _buildGroomingServices(),
                SizedBox(height: 20),

                // Date & Time picker button
                _buildDateButton(),
                SizedBox(height: 20),

                // Pet Grooming Salons (only shown if pet type, services, and date are selected)
                if (selectedPetType != null && selectedServices.isNotEmpty && selectedDateTime != null)
                  _buildSalonList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pet Type Selection Dropdown
  Widget _buildPetTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedPetType,
      decoration: InputDecoration(
        labelText: 'Select Pet Type',
        labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: const Color.fromARGB(111, 159, 158, 158),
      ),
      items: ["Cat", "Dog", "Rabbit"]
          .map((petType) => DropdownMenuItem<String>(
                value: petType,
                child: Text(petType, style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)))),
          )
          .toList(),
      onChanged: (val) {
        setState(() {
          selectedPetType = val;
        });
      },
    );
  }

  // Grooming Services (Multiple selection with checkboxes)
  Widget _buildGroomingServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: services.map((service) {
        return CheckboxListTile(
          title: Text(service, style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
          value: selectedServices.contains(service),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selectedServices.add(service);
              } else {
                selectedServices.remove(service);
              }
            });
          },
          activeColor: Colors.teal,
          checkColor: Colors.white,
        );
      }).toList(),
    );
  }

  // Date & Time button
  Widget _buildDateButton() {
    return ElevatedButton.icon(
      onPressed: _pickDateTime,
      icon: Icon(Icons.date_range),
      label: Text(
        selectedDateTime == null ? 'Pick Date & Time' : 'Change Date & Time',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF008080),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        minimumSize: Size(150, 50),
      ),
    );
  }

  // Pet Grooming Salons List (Only shown if all selections are made)
  Widget _buildSalonList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groomingSalons.map((salon) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          color: Colors.grey[850],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Salon Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        salon['image'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Salon Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(salon['name'], style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Open: ${salon['openTime']} - ${salon['closeTime']}', style: TextStyle(color: Colors.white70)),
                        Text('Price: ${salon['price']}', style: TextStyle(color: Colors.white)),
                        Text('Rating: ${salon['rating']} ⭐', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Salon Contact
                Text('Contact: ${salon['contact']}', style: TextStyle(color: Colors.white)),
                Text('Email: ${salon['email']}', style: TextStyle(color: Colors.white)),
                SizedBox(height: 10),
                // Book Button
                ElevatedButton(
                  onPressed: () => _bookSalon(salon['name']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    minimumSize: Size(120, 50),
                  ),
                  child: Text('Book Now'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}


// ------------------------------
// PET ADOPTION PAGE
// ------------------------------
class PetAdoptionPage extends StatefulWidget {
  const PetAdoptionPage({super.key});

  @override
  _PetAdoptionPageState createState() => _PetAdoptionPageState();
}

class _PetAdoptionPageState extends State<PetAdoptionPage> {
  String? selectedPet; // To hold the selected pet category
  final List<Map<String, String>> allPets = [
    // Cats
    {
      'photoUrl': 'assets/images/m1.jpeg',
      'name': 'Simba',
      'breed': 'Magpie',
      'ownerName': 'Atif Ansari',
      'contact': '9876543210',
      'email': 'atif@gmail.com',
      'description': 'A playful and loving cat.',
      'age': '2 years',
      'gender': 'Male',
      'type': 'Cat',
    },
    {
      'photoUrl': 'assets/images/m2.jpeg',
      'name': 'Jerry',
      'breed': 'American Curl',
      'ownerName': 'Rakesh Sharma',
      'contact': '7894561230',
      'email': 'rakesh33@example.com',
      'description': 'A calm and affectionate cat.',
      'age': '3 years',
      'gender': 'Female',
      'type': 'Cat', // Added pet type
    },
    {
      'photoUrl': 'assets/images/m3.jpeg',
      'name': 'John',
      'breed': 'Magpie',
      'ownerName': 'Aegon Targaryen',
      'contact': '9998887770',
      'email': 'aegon123@gmail.com',
      'description': 'Cute and clumsy cat.',
      'age': '4 years',
      'gender': 'Male',
      'type': 'Cat', // Added pet type
    },
    {
      'photoUrl': 'assets/images/m4.jpeg',
      'name': 'Larry',
      'breed': 'American Wirehair',
      'ownerName': 'Noah Smith',
      'contact': '9510375069',
      'email': 'noahsmith01@gmail.com',
      'description': 'Energetic and playful cat.',
      'age': '3 years',
      'gender': 'Male',
      'type': 'Cat', // Added pet type
    },
    // Dogs
    {
      'photoUrl': 'assets/images/d1.jpg',
      'name': 'Max',
      'breed': 'Akbash',
      'ownerName': 'Mark Thomas',
      'contact': '7741419999',
      'email': 'markthomas12@gmail.com',
      'description': 'Friendly and loyal dog.',
      'age': '4 years',
      'gender': 'Male',
      'type': 'Dog',
    },
    {
      'photoUrl': 'assets/images/d2.jpg',
      'name': 'Mark',
      'breed': 'Maltipoo',
      'ownerName': 'Sarah Lee',
      'contact': '9250643333',
      'email': 'martin1512@gmail.com',
      'description': 'Loyal and protective dog.',
      'age': '2 years',
      'gender': 'Male',
      'type': 'Dog',
    },
    // Rabbits
    {
      'photoUrl': 'assets/images/r1.jpg',
      'name': 'Coco',
      'breed': 'Holland Lop',
      'ownerName': 'Sarah Khan',
      'contact': '8667778888',
      'email': 'sarah321@gmail.com',
      'description': 'A sweet and gentle rabbit.',
      'age': '1 year',
      'gender': 'Female',
      'type': 'Rabbit',
    },
    {
      'photoUrl': 'assets/images/r2.jpg',
      'name': 'Thumper',
      'breed': 'Mini Rex',
      'ownerName': 'Rashid Khan',
      'contact': '8932221160',
      'email': 'rashid89@gmail.com',
      'description': 'Curious and energetic rabbit.',
      'age': '1.5 years',
      'gender': 'Male',
      'type': 'Rabbit',
    },
    {
      'photoUrl': 'assets/images/r3.jpg',
      'name': 'Limo',
      'breed': 'Mini Rex',
      'ownerName': 'John',
      'contact': '9449773845',
      'email': 'john@gmail.com',
      'description': 'Calm and chill rabbit.',
      'age': '2 years',
      'gender': 'Male',
      'type': 'Rabbit',
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredPets = [];

    if (selectedPet != null) {
      if (selectedPet == 'Cats') {
        filteredPets = allPets.sublist(0, 4); // First 4 cats
      } else if (selectedPet == 'Dogs') {
        filteredPets = allPets.sublist(4, 6); // 5th and 6th are dogs
      } else if (selectedPet == 'Rabbits') {
        filteredPets = allPets.sublist(6, 9); // Last 2 are rabbits
      }
    }

    return Scaffold(
      appBar: AppBar(
  title: Text(
    'Pet Adoption',
    style: TextStyle(color: Colors.white), // Set the text color to white
    ),
    backgroundColor: const Color.fromARGB(221, 41, 41, 41),
    iconTheme: IconThemeData(color: Colors.white), // Set the back button color to white
    ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/adopt_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPet,
                  decoration: InputDecoration(
                    labelText: 'Select Pet',
                    labelStyle: TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Color.fromARGB(111, 159, 158, 158),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Cats', 'Dogs', 'Rabbits']
                      .map((pet) => DropdownMenuItem<String>(
                            value: pet,
                            child: Text(
                              pet,
                              style: TextStyle(color: Colors.black),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedPet = val;
                    });
                  },
                ),
                SizedBox(height: 20),
                if (selectedPet == null)
                  Center(
                    child: Text(
                      'Please select a pet category to view available pets.',
                      style: TextStyle(color: const Color.fromARGB(179, 0, 0, 0), fontSize: 16),
                    ),
                  )
                else if (filteredPets.isEmpty)
                  Center(
                    child: Text(
                      'No pets available for adoption in the selected category.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredPets.length,
                      itemBuilder: (context, index) {
                        final pet = filteredPets[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.black87,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PetProfilePage(pet: pet),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      pet['photoUrl']!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pet['name']!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.cyanAccent,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${pet['breed']} | Age: ${pet['age']} | Gender: ${pet['gender']} | Type: ${pet['type']}',
                                          style: TextStyle(color: Colors.grey[300]),
                                        ),
                                        SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            _adoptPet(pet);  // New method to save pet details
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.black, backgroundColor: Colors.cyanAccent,
                                          ),
                                          child: Text('Adopt'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Save the adopted pet to Firestore
  void _adoptPet(Map<String, String> pet) async {
    try {
      // Get the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Create a collection and add the pet adoption data
      await firestore.collection('adoptedPets').add({
        'name': pet['name'],
        'breed': pet['breed'],
        'ownerName': pet['ownerName'],
        'contact': pet['contact'],
        'email': pet['email'],
        'description': pet['description'],
        'age': pet['age'],
        'gender': pet['gender'],
        'type': pet['type'],
        'photoUrl': pet['photoUrl'],
        'adoptedAt': Timestamp.now(),  // Timestamp when the adoption happens
      });

      // Show a confirmation message
      _showAdoptDialog(context, pet);
    } catch (e) {
      debugPrint('Error saving adoption: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adopting pet')));
    }
  }

  void _showAdoptDialog(BuildContext context, Map<String, String> pet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          'Thank you for initiating the adoption!',
          style: TextStyle(color: Colors.cyanAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The owner will soon contact you.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 10),
            Text(
              'Owner: ${pet['ownerName']}',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Contact: ${pet['contact']}',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Email: ${pet['email']}',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}

class PetProfilePage extends StatelessWidget {
  final Map<String, String> pet;
  const PetProfilePage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${pet['name']}\'s Profile'),
        backgroundColor: Colors.black87,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        color: Colors.black87,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    pet['photoUrl']!,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                pet['name']!,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              SizedBox(height: 10),
              _buildSectionHeader('Pet Information'),
              SizedBox(height: 8),
              _buildInfoRow('Breed', pet['breed']!),
              _buildInfoRow('Age', pet['age']!),
              _buildInfoRow('Gender', pet['gender']!),
              _buildInfoRow('Type', pet['type']!),
              SizedBox(height: 20),
              _buildSectionHeader('Description'),
              SizedBox(height: 8),
              Text(
                pet['description']!,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 20),
              _buildSectionHeader('Owner Info'),
              SizedBox(height: 8),
              _buildInfoRow('Name', pet['ownerName']!),
              _buildInfoRow('Contact', pet['contact']!),
              _buildInfoRow('Email', pet['email']!),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}