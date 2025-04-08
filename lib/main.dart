import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:enquiry_app/models/enquiry_model.dart';
import 'package:enquiry_app/services/api_service.dart';
import 'package:enquiry_app/userEntryPage.dart';
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
    ),
    SelectionStatus(
      displyName: "Not Interested",
      statusColorCode: "#FF0000",
      type: "default",
    ),
    SelectionStatus(
      displyName: "Using an App",
      statusColorCode: "#00FF00",
      type: "default",
    ),
    SelectionStatus(
      displyName: "Interested",
      statusColorCode: "#008000",
      type: "default",
    ),
    SelectionStatus(
      displyName: "Call Not Attended ",
      statusColorCode: "#808080",
      type: "default",
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserEntryPage(
                    statusOptions: statusOptions,
                  ),
                ),
              ).then((_) {
                _fetchEnquiries();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : users.isEmpty
                  ? const Center(child: Text('No enquiries found'))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildEnquiryCard(user);
                      },
                    ),
    );
  }
  
  // Build enquiry card widget
  Widget _buildEnquiryCard(User user) {
    // Format currency values
    final formattedTotal = '\$${user.totalAmount}';
    final formattedPaid = '\$${user.paidAmount}';
    
    // Format date
    final formattedDate = user.createdAt != null 
        ? DateFormat('MMM d, yyyy').format(user.createdAt!)
        : 'N/A';
    
    // Determine status color
    final statusColor = _hexToColor(user.statusColorCode);
    
    // Check if callback is scheduled
    final hasCallback = user.callbackTime != null;
    final formattedCallbackTime = hasCallback 
        ? DateFormat('MMM d, h:mm a').format(user.callbackTime!)
        : null;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name, phone and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_iphone,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.mobile,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _showStatusChangeDialog(user);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: user.status == "Callback" 
                          ? const Color(0xFFFFA500) 
                          : user.status == "Pending" 
                              ? const Color(0xFF4285F4)
                              : statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.status,
                      style: TextStyle(
                        color: user.status == "Callback" || user.status == "Pending" 
                            ? Colors.white 
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Package and amount info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Package',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.packageName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedTotal,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Paid amount and date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paid Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedPaid,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Remark/Notes section
            if (user.remark.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.remark,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              
            // Callback time if scheduled
            if (hasCallback)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFFFFA500),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Callback scheduled for $formattedCallbackTime',
                      style: const TextStyle(
                        color: Color(0xFFFFA500),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Handle mark as converted
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Converted'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: user.statusType == 'timer' 
                    ? OutlinedButton.icon(
                        onPressed: () {
                          // Handle schedule callback
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(hasCallback ? 'Reschedule' : 'Schedule Callback'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () {
                          // Handle mark as converted
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark as Completed'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Call button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle call action
                  _makePhoneCall(user.mobile);
                },
                icon: const Icon(Icons.call),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7E57C2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show status change dialog
  void _showStatusChangeDialog(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "Select Status",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...statusOptions.map((status) {
                final isSelected = user.status == status.displyName;
                final statusColor = _hexToColor(status.statusColorCode);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      status.type == 'timer' ? Icons.timer : Icons.check_circle,
                      color: statusColor,
                    ),
                    title: Text(
                      status.displyName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      status.type == 'timer' ? 'Set callback time' : 'Update status',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected 
                        ? Icon(Icons.check_circle, color: statusColor)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      
                      if (status.type == 'timer' && status.displyName != user.status) {
                        // Show date picker for callback status
                        await _selectCallbackTime(user);
                      }
                      
                      _updateUserStatus(user, status);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
  
  // Select callback time
  Future<void> _selectCallbackTime(User user) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: user.callbackTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA3FF40),
              onPrimary: Colors.black,
              surface: Color(0xFF2C2C2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1C1C1E),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: user.callbackTime != null
          ? TimeOfDay(hour: user.callbackTime!.hour, minute: user.callbackTime!.minute)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA3FF40),
              onPrimary: Colors.black,
              surface: Color(0xFF2C2C2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1C1C1E),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      user.callbackTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }
  
  // Update user status
  Future<void> _updateUserStatus(User user, SelectionStatus status) async {
    // Show loading indicator
    final loadingDialog = _showLoadingDialog('Updating status...');
    
    try {
      // Prepare status data for API
      final statusData = {
        'status': status.displyName,
        'status_color_code': status.statusColorCode,
        'status_type': status.type,
      };
      
      // If callback time is set and status type is timer, include it
      if (user.callbackTime != null && status.type == 'timer') {
        statusData['callback_time'] = user.callbackTime!.toIso8601String();
      } else {
        // Use empty string for null callback time
        statusData['callback_time'] = '';
      }
      
      // Call API to update status
      if (user.id != null) {
        await _apiService.updateEnquiryStatus(user.id!, statusData);
        
        // Update UI after successful API call
        setState(() {
          user.status = status.displyName;
          user.statusColorCode = status.statusColorCode;
          user.statusType = status.type;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${status.displyName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('User ID is null');
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
  
  // Show loading dialog
  Widget _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
    
    return Container(); // Return a dummy widget
  }
  
  // Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
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
