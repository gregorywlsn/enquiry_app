import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:enquiry_app/models/enquiry_model.dart';
import 'package:enquiry_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1C1C1E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1C1C1E),
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFA3FF40),
          secondary: Color(0xFFA3FF40),
          surface: Color(0xFF2C2C2E),
          background: Color(0xFF1C1C1E),
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF1C1C1E),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA3FF40),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFA3FF40),
          foregroundColor: Colors.black,
          elevation: 8,
        ),
      ),
      home: const UserListPage(),
    );
  }
}

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> with TickerProviderStateMixin {
  // API service instance
  late ApiService _apiService;
  
  // Animation controllers
  late AnimationController _listAnimationController;
  
  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _alertedUsers = {};
  List<User> users = [];
  List<User> _filteredUsers = [];
  
  // Search and filter variables
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatusFilter;
  DateTime? _selectedDateFilter;
  String? _selectedDateFilterType; // 'today', 'tomorrow', 'custom'
  
  // Alert dialog variables
  bool _isAlertDialogShowing = false;
  List<User> _pendingAlerts = [];
  
  // Status options
  final List<SelectionStatus> statusOptions = [
    SelectionStatus(
      displyName: "Callback",
      statusColorCode: "#FFA500",
      type: "timer",
      id: "1",
    ),
    SelectionStatus(
      displyName: "Not Interested",
      statusColorCode: "#FF0000",
      type: "default",
      id: "2",
    ),
    SelectionStatus(
      displyName: "Using an App",
      statusColorCode: "#00FF00",
      type: "default",
      id: "3",
    ),
    SelectionStatus(
      displyName: "Interested",
      statusColorCode: "#008000",
      type: "default",
      id: "4",
    ),
    SelectionStatus(
      displyName: "Call Not Attended ",
      statusColorCode: "#808080",
      type: "default",
      id: "5",
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry App'),
      ),
      body: Center(
        child: Text('Enquiry App'),
      ),
    );
  }
  
  // Helper method to convert hex color string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // Add alpha value if missing
    return Color(int.parse(hex, radix: 16));
  }
  
  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialize API service
    _apiService = ApiService();
    
    // Fetch enquiries from API
    _fetchEnquiries();
  }
  
  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }
  
  // Fetch enquiries from API
  Future<void> _fetchEnquiries() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final enquiries = await _apiService.getEnquiries();
      
      // Convert Enquiry objects to User objects
      final userList = enquiries.map((enquiry) => enquiry.toUser()).toList();
      
      setState(() {
        users = userList;
        _filteredUsers = userList; // Initialize filtered list with all users
        _isLoading = false;
      });
      
      // Start list animation
      _listAnimationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load enquiries: $e';
        _isLoading = false;
      });
    }
  }
}
