// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:math' as math;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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
  String? _selectedGender;
  bool _isChanged = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _pickProfilePhoto() async {
    if (await Permission.photos.request().isGranted) {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          _profileImage = imageBytes;
          _isChanged = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo permission is required")),
      );
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
        User? user = _auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in first!')),
          );
          return;
        }

        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'gender': _selectedGender,
        }, SetOptions(merge: true));

        setState(() {
          _isChanged = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProfile() async {
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
          _selectedGender = data['gender'] ?? 'Male';
        });
      } else {
        setState(() {
          _selectedGender = 'Male';
        });
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () {
                _auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Reduced vertical padding
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(fontSize: 14), // Slightly smaller font
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.purple.shade300, size: 20), // Smaller icon
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Slightly smaller radius
            borderSide: const BorderSide(color: Colors.purple, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purple.shade400, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purple.shade200, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.2),
          ),
          filled: true,
          fillColor: Colors.white.withAlpha((0.9 * 255).toInt()),
          labelStyle: TextStyle(color: Colors.purple.shade700, fontSize: 14),
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
          return null;
        },
        onChanged: (value) {
          setState(() {
            _isChanged = true;
          });
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: Icon(Icons.person, color: Colors.purple.shade300, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.purple, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purple.shade400, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purple.shade200, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.2),
          ),
          filled: true,
          fillColor: Colors.white.withAlpha((0.9 * 255).toInt()),
          labelStyle: TextStyle(color: Colors.purple.shade700, fontSize: 14),
        ),
        items: ['Male', 'Female'].map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue;
            _profileImage = null;
            _isChanged = true;
          });
        },
        validator: (value) => value == null ? 'Please select a gender' : null,
        icon: Icon(Icons.arrow_drop_down_circle, color: Colors.purple.shade300, size: 20),
        dropdownColor: Colors.white,
        style: TextStyle(color: Colors.purple.shade800, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/user_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 30, 12, 70), // Adjusted padding for Realme P1
              child: Center(
                child: Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 360), // Adjusted for 1080px width
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: Colors.white.withAlpha((0.85 * 255).toInt()),
                        child: Padding(
                          padding: const EdgeInsets.all(16), // Reduced padding
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Profile Details",
                                  style: TextStyle(
                                    fontSize: 22, // Slightly smaller
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: _pickProfilePhoto,
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        height: 100, // Reduced size
                                        width: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.purple.shade300, width: 2.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha((0.2 * 255).toInt()),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(50),
                                          child: _profileImage != null
                                              ? Image.memory(
                                                  _profileImage!,
                                                  height: 100,
                                                  width: 100,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.asset(
                                                  _selectedGender == 'Female'
                                                      ? 'assets/images/female_profile.jpg'
                                                      : 'assets/images/male_profile.jpg',
                                                  height: 100,
                                                  width: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade500,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(_nameController, "Name", Icons.person),
                                _buildGenderDropdown(),
                                _buildTextField(_phoneController, "Phone Number", Icons.phone, isNumeric: true),
                                _buildTextField(_emailController, "Email", Icons.email),
                                _buildTextField(_addressController, "Address", Icons.home),
                                const SizedBox(height: 20),
                                if (_isChanged && _allFieldsFilled())
                                  Container(
                                    width: double.infinity,
                                    height: 45, // Slightly smaller
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [Colors.purple.shade300, Colors.purple.shade700],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withAlpha((0.4 * 255).toInt()),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.save, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "Save Profile",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 180, // Slightly smaller for better fit
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha((0.4 * 255).toInt()),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt()), width: 1.5),
                      ),
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha((0.3 * 255).toInt()),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _allFieldsFilled() {
    return _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _selectedGender != null;
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
  Uint8List? pickedImage;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isLoading = false;

  // Map of default pet images by type
  final Map<String, String> defaultPetIcons = {
    "Dog": "assets/images/default_dog.png",
    "Cat": "assets/images/default_cat.jpg",
    "Rabbit": "assets/images/default_rabbit.png",
    "Hamster": "assets/images/default_hamster.png",
  };

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadDefaultPetImage(); // Load the default image for the initial pet type
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      
      if (await Permission.photos.request().isGranted) {
        debugPrint("Photos permission granted");
      }
    }
  }

  // Add method to load default pet image
  Uint8List? defaultImageData; // Add this to your state variables

Future<void> _loadDefaultPetImage() async {
  try {
    if (pickedImage == null) {
      final asset = defaultPetIcons[selectedPetType]!;
      final byteData = await rootBundle.load(asset);
      setState(() {
        defaultImageData = byteData.buffer.asUint8List();
      });
    }
  } catch (e) {
    debugPrint('Error loading default pet image: $e');
  }
}

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          pickedImage = imageBytes;
        });
        
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('temp_pet_image', base64Encode(imageBytes));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<String?> _uploadPetImage(String petId) async {
    if (pickedImage == null) return null;
    
    try {
      final ref = _storage.ref().child('pet_images/$petId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-from': 'user-gallery'},
      );
      
      await ref.putData(pickedImage!, metadata);
      final url = await ref.getDownloadURL();
      
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('temp_pet_image');
      
      return url;
    } catch (e) {
      debugPrint('Error uploading pet image: $e');
      return null;
    }
  }

  Future<void> savePetProfile() async {
    if (petNameController.text.isEmpty || ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pet name and age are required!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String defaultImageUrl = await _getDefaultPetImageUrl(selectedPetType);

      DocumentReference docRef = await FirebaseFirestore.instance.collection('pet_profiles').add({
        'name': petNameController.text,
        'age': ageController.text,
        'gender': selectedGender,
        'type': selectedPetType,
        'bio': '',
        'activities': [],
        'timestamp': FieldValue.serverTimestamp(),
        'image_url': pickedImage == null ? defaultImageUrl : '',
        'using_default_image': pickedImage == null,
      });

      String? imageUrl;
      if (pickedImage != null) {
        imageUrl = await _uploadPetImage(docRef.id);
        if (imageUrl != null) {
          await docRef.update({
            'image_url': imageUrl,
            'using_default_image': false,
          });
        }
      }

      setState(() {
        petNameController.clear();
        ageController.clear();
        selectedGender = "Male";
        selectedPetType = "Dog";
        pickedImage = null;
        isLoading = false;
      });

      // Reset to default Dog image after saving
      _loadDefaultPetImage();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pet Profile Saved Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _getDefaultPetImageUrl(String petType) async {
    try {
      // Return the asset path based on pet type
      return defaultPetIcons[petType.toLowerCase().capitalize()] ?? 'assets/images/default_generic.jpg';
    } catch (e) {
      debugPrint('Error selecting default image: $e');
      return 'assets/images/default_generic.jpg'; // Fallback to generic pet image
    }
  }

  void deleteProfile(String petId) async {
    try {
      await FirebaseFirestore.instance.collection('pet_profiles').doc(petId).delete();
      await _storage.ref().child('pet_images/$petId.jpg').delete().catchError((e) {
        debugPrint('Error deleting pet image: $e');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile deleted successfully!"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("Error deleting profile: $e");
    }
  }

  Widget _buildImagePlaceholder() {
    IconData petIcon = Icons.pets;
    Color tintColor = Colors.amber;
    
    switch (selectedPetType) {
      case "Dog":
        petIcon = Icons.pets;
        tintColor = Colors.brown;
        break;
      case "Cat":
        petIcon = Icons.pets;
        tintColor = Colors.grey;
        break;
      case "Rabbit":
        petIcon = Icons.pets;
        tintColor = Colors.white;
        break;
      case "Hamster":
        petIcon = Icons.pets;
        tintColor = Colors.orange;
        break;
    }
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: FutureBuilder<ByteData>(
          future: rootBundle.load(defaultPetIcons[selectedPetType]!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return ClipOval(
                child: Image.memory(
                  snapshot.data!.buffer.asUint8List(),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              );
            } else {
              return Icon(
                petIcon,
                size: 50,
                color: tintColor,
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationX(math.pi),
          child:Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/petprofile_bg.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha((0.3 * 255).toInt()),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
        ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.85 * 255).toInt()),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pets, size: 32, color: Colors.orange),
                          const SizedBox(width: 16),
                          const Text(
                            "Manage Pet Profiles",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white.withAlpha((0.7 * 255).toInt()),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Add New Pet",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 25),
                          
                          GestureDetector(
                            onTap: pickImage,
                            child: Column(
                              children: [
                                pickedImage != null
                                    ? Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.memory(
                                            pickedImage!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : _buildImagePlaceholder(),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: pickImage,
                                  icon: const Icon(Icons.photo_camera, size: 18),
                                  label: const Text("Select Pet Photo"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    elevation: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          TextField(
                            controller: petNameController,
                            decoration: InputDecoration(
                              labelText: "Pet Name",
                              hintText: "Enter your pet's name",
                              prefixIcon: const Icon(Icons.favorite, color: Colors.pink),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[400]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.orange, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Age",
                              hintText: "Enter your pet's age",
                              prefixIcon: Icon(Icons.calendar_today, color: Colors.blue[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[400]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.orange, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[400]!),
                              color: Colors.white,
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedGender,
                              decoration: InputDecoration(
                                labelText: "Gender",
                                prefixIcon: Icon(
                                  selectedGender == "Male" ? Icons.male : Icons.female,
                                  color: selectedGender == "Male" ? Colors.blue : Colors.pink,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: ["Male", "Female"]
                                  .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value!;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.orange),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[400]!),
                              color: Colors.white,
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedPetType,
                              decoration: InputDecoration(
                                labelText: "Pet Category",
                                prefixIcon: const Icon(Icons.pets, color: Colors.brown),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: ["Dog", "Cat", "Rabbit", "Hamster"].map((type) {
                                IconData iconData = Icons.pets;
                                Color iconColor = Colors.brown;
                                
                                switch (type) {
                                  case "Dog":
                                    iconColor = Colors.brown;
                                    break;
                                  case "Cat":
                                    iconColor = Colors.grey[700]!;
                                    break;
                                  case "Rabbit":
                                    iconColor = Colors.grey[500]!;
                                    break;
                                  case "Hamster":
                                    iconColor = Colors.orange[300]!;
                                    break;
                                }
                                
                                return DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(iconData, color: iconColor, size: 20),
                                      const SizedBox(width: 8),
                                      Text(type),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPetType = value!;
                                  // Reset pickedImage to null and reload default image
                                  if (pickedImage != null) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Change Pet Type"),
                                          content: const Text("Do you want to keep your current pet image or use the default for this pet type?"),
                                          actions: [
                                            TextButton(
                                              child: const Text("Use Default"),
                                              onPressed: () {
                                                setState(() {
                                                  pickedImage = null;
                                                });
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text("Keep Current"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.orange),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : savePetProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey,
                                elevation: 4,
                                shadowColor: Colors.orange.withAlpha((0.5 * 255).toInt()),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Saving...",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.save_alt, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Save Pet Profile",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.85 * 255).toInt()),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pets, color: Colors.orange, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                "Your Pet Profiles",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('pet_profiles').snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(30),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.pets,
                                        size: 60,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No pet profiles yet",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Add your first pet above",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              var petProfiles = snapshot.data!.docs;

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: petProfiles.length,
                                itemBuilder: (context, index) {
                                  var pet = petProfiles[index].data() as Map<String, dynamic>;
                                  String petId = petProfiles[index].id;
                                  String? imageUrl = pet['image_url'];
                                  bool usingDefaultImage = pet['using_default_image'] ?? false;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PetProfileDetailPage(
                                              petId: petId,
                                              petImage: null,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(15),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipOval(
                                                child: usingDefaultImage
                                                    ? Image.asset(
                                                        imageUrl!,
                                                        width: 70,
                                                        height: 70,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return _getPetTypeIcon(pet['type']);
                                                        },
                                                      )
                                                    : (imageUrl != null && imageUrl.isNotEmpty
                                                        ? Image.network(
                                                            imageUrl,
                                                            width: 70,
                                                            height: 70,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return _getPetTypeIcon(pet['type']);
                                                            },
                                                            loadingBuilder: (context, child, loadingProgress) {
                                                              if (loadingProgress == null) return child;
                                                              return Center(
                                                                child: CircularProgressIndicator(
                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                                          loadingProgress.expectedTotalBytes!
                                                                      : null,
                                                                  strokeWidth: 2,
                                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : _getPetTypeIcon(pet['type'])),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pet['name'],
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${pet['type']} • ${pet['age']} years • ${pet['gender']}",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  if (pet['bio'] != null && pet['bio'].toString().isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Text(
                                                        pet['bio'],
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey[600],
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[50],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(Icons.edit, color: Colors.blue[700], size: 22),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => PetProfileDetailPage(
                                                            petId: petId,
                                                            petImage: null,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(Icons.delete, color: Colors.red[700], size: 22),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return AlertDialog(
                                                            title: Text("Delete ${pet['name']}?"),
                                                            content: const Text("This action cannot be undone."),
                                                            actions: [
                                                              TextButton(
                                                                child: const Text("Cancel"),
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                              ),
                                                              TextButton(
                                                                child: const Text(
                                                                  "Delete",
                                                                  style: TextStyle(color: Colors.red),
                                                                ),
                                                                onPressed: () {
                                                                  deleteProfile(petId);
                                                                  Navigator.of(context).pop();
                                                                },
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPetTypeIcon(String petType) {
    IconData icon = Icons.pets;
    Color color = Colors.brown;
    
    switch (petType) {
      case "Cat":
        color = Colors.grey;
        break;
      case "Rabbit":
        color = Colors.grey[400]!;
        break;
      case "Hamster":
        color = Colors.orange[300]!;
        break;
      default: // Dog or any other
        color = Colors.brown;
    }
    
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    petNameController.dispose();
    ageController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// ===============================
// Pet Profile Detail Page
// ===============================

class PetProfileDetailPage extends StatefulWidget {
  final String petId;
  final Uint8List? petImage;

  const PetProfileDetailPage({
    required this.petId,
    required this.petImage,
    super.key,
  });

  @override
  _PetProfileDetailPageState createState() => _PetProfileDetailPageState();
}

class _PetProfileDetailPageState extends State<PetProfileDetailPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController customActivityController = TextEditingController();
  String selectedGender = "Male";
  String selectedPetType = "Dog";
  bool isLoading = true;
  bool isSaving = false;
  
  List<String> selectedActivities = [];
  final List<Map<String, dynamic>> availableActivities = [
    {"id": "walking", "name": "Walking", "icon": Icons.directions_walk},
    {"id": "playing", "name": "Playing", "icon": Icons.sports_tennis},
    {"id": "grooming", "name": "Grooming", "icon": Icons.content_cut},
    {"id": "training", "name": "Training", "icon": Icons.school},
    {"id": "veterinary", "name": "Veterinary", "icon": Icons.local_hospital},
    {"id": "feeding", "name": "Feeding", "icon": Icons.restaurant},
    {"id": "sleeping", "name": "Sleeping", "icon": Icons.hotel},
    {"id": "bathing", "name": "Bathing", "icon": Icons.shower},
  ];
  List<Map<String, dynamic>> customActivities = [];

  @override
  void initState() {
    super.initState();
    loadPetData();
  }

  Future<void> loadPetData() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final petDoc = await FirebaseFirestore.instance
          .collection('pet_profiles')
          .doc(widget.petId)
          .get();
      
      if (!petDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pet profile not found!")),
        );
        Navigator.pop(context);
        return;
      }
      
      var petData = petDoc.data() as Map<String, dynamic>;
      
      nameController.text = petData['name'] ?? '';
      ageController.text = petData['age']?.toString() ?? '';
      bioController.text = petData['bio'] ?? '';
      breedController.text = petData['breed'] ?? '';
      selectedGender = petData['gender'] ?? 'Male';
      selectedPetType = petData['type'] ?? 'Dog';
      
      if (petData['activities'] != null) {
        selectedActivities = List<String>.from(petData['activities']);
        // Load custom activities from the database if they exist
        for (String activity in selectedActivities) {
          if (!availableActivities.any((a) => a['id'] == activity) &&
              !customActivities.any((a) => a['id'] == activity)) {
            customActivities.add({
              'id': activity,
              'name': activity,
              'icon': Icons.pets,
            });
          }
        }
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading pet data: $e")),
      );
    }
  }

  Future<void> savePetProfile() async {
    if (nameController.text.isEmpty || ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pet name and age are required!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('pet_profiles').doc(widget.petId).update({
        'name': nameController.text,
        'age': ageController.text,
        'gender': selectedGender,
        'type': selectedPetType,
        'breed': breedController.text,
        'bio': bioController.text,
        'activities': selectedActivities,
        'last_updated': FieldValue.serverTimestamp(),
      });

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pet Profile Updated Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void addCustomActivity() {
    if (customActivityController.text.isNotEmpty) {
      String newActivity = customActivityController.text.trim();
      setState(() {
        customActivities.add({
          'id': newActivity,
          'name': newActivity,
          'icon': Icons.pets,
        });
        selectedActivities.add(newActivity);
        customActivityController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Pet Profile"),
        backgroundColor: Colors.pink[300],
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            )
          : Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.pink[200]!.withAlpha((0.7 * 255).toInt()),
                        Colors.yellow[100]!.withAlpha((0.6 * 255).toInt()),
                        Colors.white,
                      ],
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Basic Information",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink[800],
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: "Pet Name",
                                    prefixIcon: Icon(Icons.pets, color: Colors.pink),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                TextField(
                                  controller: ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Age",
                                    prefixIcon: Icon(Icons.calendar_today, color: Colors.pink),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                DropdownButtonFormField<String>(
                                  value: selectedGender,
                                  decoration: InputDecoration(
                                    labelText: "Gender",
                                    prefixIcon: Icon(
                                      selectedGender == "Male" ? Icons.male : Icons.female,
                                      color: selectedGender == "Male" ? Colors.blue : Colors.pink,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: ["Male", "Female"]
                                      .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedGender = value!;
                                    });
                                  },
                                ),
                                SizedBox(height: 16),
                                
                                DropdownButtonFormField<String>(
                                  value: selectedPetType,
                                  decoration: InputDecoration(
                                    labelText: "Pet Type",
                                    prefixIcon: Icon(Icons.category, color: Colors.pink),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: ["Dog", "Cat", "Rabbit", "Hamster"]
                                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPetType = value!;
                                    });
                                  },
                                ),
                                SizedBox(height: 16),
                                
                                TextField(
                                  controller: breedController,
                                  decoration: InputDecoration(
                                    labelText: "Breed",
                                    prefixIcon: Icon(Icons.pets, color: Colors.pink),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                TextField(
                                  controller: bioController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: "Pet Bio",
                                    hintText: "Tell us about your pet...",
                                    prefixIcon: Icon(Icons.description, color: Colors.pink),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_activity, color: Colors.pink[800]),
                                    SizedBox(width: 8),
                                    Text(
                                      "Pet Activities",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.pink[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                
                                Text(
                                  "Select activities that your pet enjoys:",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 12),
                                
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 12,
                                  children: [
                                    ...availableActivities.map((activity) {
                                      bool isSelected = selectedActivities.contains(activity['id']);
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedActivities.remove(activity['id']);
                                            } else {
                                              selectedActivities.add(activity['id']);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.pink : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.pink.withAlpha((0.3 * 255).toInt()),
                                                      blurRadius: 5,
                                                      offset: Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                activity['icon'] as IconData,
                                                size: 18,
                                                color: isSelected ? Colors.white : Colors.grey[700],
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                activity['name'],
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.grey[700],
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    ...customActivities.map((activity) {
                                      bool isSelected = selectedActivities.contains(activity['id']);
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedActivities.remove(activity['id']);
                                            } else {
                                              selectedActivities.add(activity['id']);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.pink : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.pink.withAlpha((0.3 * 255).toInt()),
                                                      blurRadius: 5,
                                                      offset: Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                activity['icon'] as IconData,
                                                size: 18,
                                                color: isSelected ? Colors.white : Colors.grey[700],
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                activity['name'],
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.grey[700],
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: customActivityController,
                                        decoration: InputDecoration(
                                          labelText: "Add Custom Activity",
                                          prefixIcon: Icon(Icons.add_circle, color: Colors.pink),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      height: 56, // Match the height of the TextField
                                      child: ElevatedButton(
                                        onPressed: addCustomActivity,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.pink[300],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 16), // Add some horizontal padding
                                        ),
                                        child: Text("Add"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : savePetProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            child: isSaving
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  )
                                : Text(
                                    "Save Changes",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    bioController.dispose();
    breedController.dispose();
    customActivityController.dispose();
    super.dispose();
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
  List<Map<String, dynamic>> dietMeals = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadDietMeals();
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
// Request permissions
    if (await Permission.notification.request().isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission is required for reminders')),
      );
    }
    if (await Permission.scheduleExactAlarm.request().isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm permission is required for exact timing')),
      );
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {},
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'meal_reminder_channel',
      'Meal Reminders',
      description: 'Notifications for meal reminders',
      importance: Importance.max,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

   Future<void> _scheduleNotification(int hour, int minute, String mealName, String petName, String mealId) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      mealId.hashCode, // Use meal ID for uniqueness
      'Meal Reminder for $petName',
      'Time to feed $petName: $mealName',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminder_channel',
          'Meal Reminders',
          channelDescription: 'Notifications for meal reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  Future<void> _addMeal() async {
    if (_mealController.text.trim().isEmpty || selectedTime == null || selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select pet, enter meal, and pick time')));
      return;
    }

    final mealName = _mealController.text.trim();
    final mealData = {
      'meal': mealName,
      'time': selectedTime!.format(context),
      'pet': selectedPet,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'hour': selectedTime!.hour,
      'minute': selectedTime!.minute,
    };

    final docRef = await _firestore.collection('dietMeals').add(mealData);
    mealData['id'] = docRef.id;

    setState(() {
      dietMeals.add(mealData);
    });

    final isPM = selectedTime!.hour >= 12;
    final adjustedHour = isPM && selectedTime!.hour != 12
        ? selectedTime!.hour + 12
        : (selectedTime!.hour == 12 && !isPM ? 0 : selectedTime!.hour);

    await _scheduleNotification(
      adjustedHour,
      selectedTime!.minute,
      mealName,
      selectedPet!,
      docRef.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal Reminder Added')));
    _mealController.clear();
    setState(() {
      selectedTime = null;
    });
  }

  Future<void> _deleteMeal(int index) async {
    final meal = dietMeals[index];
    final mealId = meal['id'];

    await _firestore.collection('dietMeals').doc(mealId).delete();
    await flutterLocalNotificationsPlugin.cancel(mealId.hashCode);

    setState(() {
      dietMeals.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal Reminder Removed')));
  }

  Future<void> _loadDietMeals() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await _firestore.collection('dietMeals')
          .where('userId', isEqualTo: userId)
          .get();

      setState(() {
        dietMeals = snapshot.docs.map((doc) {
          var data = doc.data();
          return {
            'meal': data['meal'],
            'time': data['time'],
            'pet': data['pet'],
            'id': doc.id,
            'hour': data['hour'],
            'minute': data['minute'],
          };
        }).toList();
      });

      // Schedule all loaded meals
      for (final meal in dietMeals) {
        final timeParts = meal['time'].split(' ');
        final time = timeParts[0].split(':');
        final hour = int.parse(time[0]);
        final minute = int.parse(time[1]);
        final isPM = timeParts[1] == 'PM';
        final adjustedHour = isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);

        await _scheduleNotification(
          adjustedHour,
          minute,
          meal['meal'],
          meal['pet'],
          meal['id'],
        );
      }
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
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(price, style: const TextStyle(color: Colors.green)),
                  ElevatedButton(
                    onPressed: () => launchUrl(Uri.parse(url)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Buy Now'),
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
        title: const Text(
          'Diet Tracker',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(221, 41, 41, 41),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/diet_bg.jpg'), fit: BoxFit.cover),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>( 
              value: selectedPet,
              decoration: InputDecoration(
                labelText: 'Select Pet',
                labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: const Color.fromARGB(111, 159, 158, 158),
              ),
              items: ['Cat', 'Dog', 'Rabbit', 'Hamster']
                  .map((pet) => DropdownMenuItem(
                        value: pet,
                        child: Text(pet, style: const TextStyle(color: Colors.black)),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => selectedPet = val),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _mealController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Meal Name',
                labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: const Color.fromARGB(111, 159, 158, 158),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: _pickTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      selectedTime == null ? 'Pick Time' : selectedTime!.format(context),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: _addMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                      'Add Meal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (dietMeals.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dietMeals.length,
                itemBuilder: (context, index) {
                  final meal = dietMeals[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                    color: Colors.grey[850],
                    child: ListTile(
                      leading: const Icon(Icons.fastfood, color: Colors.orangeAccent),
                      title: Text('${meal['meal']} for ${meal['pet']}', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('At: ${meal['time']}', style: const TextStyle(color: Colors.white)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMeal(index),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            const Text(
              'Recommended Food Items',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Roboto',
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(
              height: 250,
              child: Card(
                color: Colors.grey[850],
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  width: MediaQuery.of(context).size.width * 0.95,
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
        title: Text(
        '${pet['name']}\'s Profile',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.black87,
      iconTheme: IconThemeData(color: Colors.white),
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
