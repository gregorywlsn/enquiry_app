import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:enquiry_app/models/enquiry_model.dart';
import 'package:enquiry_app/services/api_service.dart';
import 'package:enquiry_app/userEntryPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dotted_border/dotted_border.dart';
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
  
  // Filter variables
  String? _selectedStatusFilter;
  DateTime? _selectedDateFilter;
  String? _selectedDateFilterType; // 'today', 'tomorrow', 'custom'
  
  // Helper method to convert hex color string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // Add alpha value if missing
    return Color(int.parse(hex, radix: 16));
  }

  bool _isAlertDialogShowing = false;
  List<User> _pendingAlerts = [];
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
    
    // Start callback check timer
    _startCallbackCheck();
  }
  
  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }
  
  // Apply filters to the user list
  void _applyFilters() {
    setState(() {
      _filteredUsers = users.where((user) {
        // Apply status filter
        if (_selectedStatusFilter != null) {
          // Find the status option with the matching display name
          final selectedStatus = statusOptions.firstWhere(
            (status) => status.displyName == _selectedStatusFilter,
            orElse: () => SelectionStatus(id: "", displyName: "", statusColorCode: "", type: ""),
          );
          
          // Compare the status ID with the user's status
          if (user.statusId != selectedStatus.id) {
            return false;
          }
        }
        
        // Apply date filter for callback status
        if (_selectedStatusFilter == "Callback" && _selectedDateFilterType != null && user.callbackTime != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));
          
          if (_selectedDateFilterType == 'today') {
            final callbackDate = DateTime(
              user.callbackTime!.year,
              user.callbackTime!.month,
              user.callbackTime!.day,
            );
            return callbackDate.isAtSameMomentAs(today);
          } else if (_selectedDateFilterType == 'tomorrow') {
            final callbackDate = DateTime(
              user.callbackTime!.year,
              user.callbackTime!.month,
              user.callbackTime!.day,
            );
            return callbackDate.isAtSameMomentAs(tomorrow);
          } else if (_selectedDateFilterType == 'custom' && _selectedDateFilter != null) {
            final callbackDate = DateTime(
              user.callbackTime!.year,
              user.callbackTime!.month,
              user.callbackTime!.day,
            );
            final filterDate = DateTime(
              _selectedDateFilter!.year,
              _selectedDateFilter!.month,
              _selectedDateFilter!.day,
            );
            return callbackDate.isAtSameMomentAs(filterDate);
          }
        }
        
        return true;
      }).toList();
    });
  }
  
  // Show filter dialog
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Title
                  const Text(
                    "Filter Enquiries",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Status filter
                  const Text(
                    "Status",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Status options
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // All option
                      FilterChip(
                        label: const Text("All"),
                        selected: _selectedStatusFilter == null,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedStatusFilter = null;
                            _selectedDateFilterType = null;
                            _selectedDateFilter = null;
                          });
                        },
                        backgroundColor: const Color(0xFF3A3A3C),
                        selectedColor: const Color(0xFFA3FF40).withOpacity(0.2),
                        checkmarkColor: const Color(0xFFA3FF40),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      
                      // Status options
                      ...statusOptions.map((status) {
                        return FilterChip(
                          label: Text(status.displyName),
                          selected: _selectedStatusFilter == status.displyName,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedStatusFilter = status.displyName;
                                // Reset date filter when changing status
                                _selectedDateFilterType = null;
                                _selectedDateFilter = null;
                              } else {
                                _selectedStatusFilter = null;
                                _selectedDateFilterType = null;
                                _selectedDateFilter = null;
                              }
                            });
                          },
                          backgroundColor: const Color(0xFF3A3A3C),
                          selectedColor: _hexToColor(status.statusColorCode).withOpacity(0.2),
                          checkmarkColor: _hexToColor(status.statusColorCode),
                          labelStyle: const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ],
                  ),
                  
                  // Date filter for Callback status
                  if (_selectedStatusFilter == "Callback") ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Callback Date",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Date filter options
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // All dates option
                        FilterChip(
                          label: const Text("All Dates"),
                          selected: _selectedDateFilterType == null,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedDateFilterType = null;
                              _selectedDateFilter = null;
                            });
                          },
                          backgroundColor: const Color(0xFF3A3A3C),
                          selectedColor: const Color(0xFFA3FF40).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFA3FF40),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        
                        // Today option
                        FilterChip(
                          label: const Text("Today"),
                          selected: _selectedDateFilterType == 'today',
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedDateFilterType = 'today';
                                _selectedDateFilter = DateTime.now();
                              } else {
                                _selectedDateFilterType = null;
                                _selectedDateFilter = null;
                              }
                            });
                          },
                          backgroundColor: const Color(0xFF3A3A3C),
                          selectedColor: Colors.blue.withOpacity(0.2),
                          checkmarkColor: Colors.blue,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        
                        // Tomorrow option
                        FilterChip(
                          label: const Text("Tomorrow"),
                          selected: _selectedDateFilterType == 'tomorrow',
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedDateFilterType = 'tomorrow';
                                _selectedDateFilter = DateTime.now().add(const Duration(days: 1));
                              } else {
                                _selectedDateFilterType = null;
                                _selectedDateFilter = null;
                              }
                            });
                          },
                          backgroundColor: const Color(0xFF3A3A3C),
                          selectedColor: Colors.purple.withOpacity(0.2),
                          checkmarkColor: Colors.purple,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        
                        // Custom date option
                        FilterChip(
                          label: Text(_selectedDateFilterType == 'custom' && _selectedDateFilter != null
                              ? DateFormat('dd MMM yyyy').format(_selectedDateFilter!)
                              : "Custom Date"),
                          selected: _selectedDateFilterType == 'custom',
                          onSelected: (selected) async {
                            if (selected) {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
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
                              
                              if (pickedDate != null) {
                                setModalState(() {
                                  _selectedDateFilterType = 'custom';
                                  _selectedDateFilter = pickedDate;
                                });
                              }
                            } else {
                              setModalState(() {
                                _selectedDateFilterType = null;
                                _selectedDateFilter = null;
                              });
                            }
                          },
                          backgroundColor: const Color(0xFF3A3A3C),
                          selectedColor: Colors.orange.withOpacity(0.2),
                          checkmarkColor: Colors.orange,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Apply and Reset buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reset button
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset"),
                        onPressed: () {
                          setModalState(() {
                            _selectedStatusFilter = null;
                            _selectedDateFilterType = null;
                            _selectedDateFilter = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                      
                      // Apply button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Apply Filters"),
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA3FF40),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
      
      // Update statusType and statusColorCode for each user
      for (var user in userList) {
        final matchingStatus = statusOptions.firstWhere(
          (status) => status.id == user.statusId,
          orElse: () => SelectionStatus(
            id: "0",
            displyName: "Unknown",
            statusColorCode: "#808080",
            type: "default",
          ),
        );
        user.statusType = matchingStatus.type;
        user.statusColorCode = matchingStatus.statusColorCode;
      }
      
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
        
        // Fallback to sample data for testing
        users = [
          User(
            name: "John Doe",
            mobile: "1234567890",
            callbackTime: DateTime.now().add(const Duration(minutes: 2)),
            remark: "",
            packageName: "Basic Package",
            totalAmount: "1000",
            paidAmount: "900",
            statusId: "1",
            isScheduled: true,
          ),
          User(
            name: "Jane Smith",
            mobile: "0987654321",
            callbackTime: DateTime.now().add(const Duration(minutes: 3)),
            remark: "",
            packageName: "Premium Package",
            totalAmount: "2500",
            paidAmount: "1500",
            statusId: "1",
            isScheduled: true,
          ),
        ];
        _filteredUsers = users; // Initialize filtered list with sample data
      });
      
      // Start list animation even with sample data
      _listAnimationController.forward();
    }
  }

  void _startCallbackCheck() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      DateTime now = DateTime.now();
      List<User> newlyAlertedUsers = [];

      for (var user in users) {
        if (user.statusType == "timer" && user.callbackTime != null) {
          DateTime nowTruncated = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
          );
          DateTime callbackTruncated = DateTime(
            user.callbackTime!.year,
            user.callbackTime!.month,
            user.callbackTime!.day,
            user.callbackTime!.hour,
            user.callbackTime!.minute,
          );

          if (nowTruncated.isAtSameMomentAs(callbackTruncated.subtract(const Duration(minutes: 1))) &&
              !_alertedUsers.contains(user.mobile)) {
            newlyAlertedUsers.add(user);
            _alertedUsers.add(user.mobile);
          }
        }
      }

      if (newlyAlertedUsers.isNotEmpty) {
        _pendingAlerts.addAll(newlyAlertedUsers);
        if (_isAlertDialogShowing && mounted) {
          // Force dialog content to update
          Navigator.of(context, rootNavigator: true).pop();
          _isAlertDialogShowing = false;
        }

        if (!_isAlertDialogShowing && mounted) {
          _showNextAlert();
        }
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _playAlertSound() async {
    final player = AudioPlayer();
    await player.play(
      AssetSource('callBackAlert.mp3'),
      mode: PlayerMode.lowLatency,
    );
  }

  void _showNextAlert() {
    if (_pendingAlerts.isEmpty) {
      _isAlertDialogShowing = false;
      return;
    }

    _isAlertDialogShowing = true;

    _playAlertSound();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFF2C2C2E),
              title: const Text(
                "Callback Reminders",
                style: TextStyle(
                  color: Color(0xFFA3FF40),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _pendingAlerts.reversed.map((user) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.orange.withOpacity(0.2),
                            Colors.orange.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFFA3FF40),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.mobile,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (user.remark.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.comment,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Remark: ${user.remark}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Callback: ${DateFormat('dd MMM yyyy hh:mm a').format(user.callbackTime!)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.call),
                              label: const Text("Call Now"),
                              onPressed: () {
                                launchUrl(Uri.parse("tel:${user.mobile}"));
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Dismiss All"),
                  onPressed: () {
                    Navigator.pop(context);
                    _pendingAlerts.clear();
                    _isAlertDialogShowing = false;
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to update user status
  void _updateStatus(int index) {
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
                "Update Status",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...statusOptions.map((status) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _hexToColor(status.statusColorCode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hexToColor(status.statusColorCode).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      status.type == 'timer' ? Icons.timer : Icons.check_circle,
                      color: _hexToColor(status.statusColorCode),
                    ),
                    title: Text(
                      status.displyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      status.type == 'timer' ? 'Set callback time' : 'Update status',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      if (status.type == 'timer') {
                        DateTime? selectedDateTime = await _selectCallbackTime(
                          context,
                        );
                        if (selectedDateTime != null) {
                          // Update locally first for immediate UI feedback
                          setState(() {
                            users[index].statusId = status.id;
                            users[index].statusType = status.type;
                            users[index].statusColorCode = status.statusColorCode;
                            users[index].callbackTime = selectedDateTime;
                          });
                          
                          Navigator.pop(context);
                          
                          // Then update via API
                          _updateEnquiryStatus(index);
                          
                          // Apply filters if active
                          if (_selectedStatusFilter != null || _selectedDateFilterType != null) {
                            _applyFilters();
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                "Please select a valid date and time for the callback.",
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      } else {
                        // Update locally first for immediate UI feedback
                        setState(() {
                          users[index].statusId = status.id;
                          users[index].statusType = status.type;
                          users[index].statusColorCode = status.statusColorCode;
                          users[index].callbackTime = null;
                        });
                        
                        Navigator.pop(context);
                        
                        // Then update via API
                        _updateEnquiryStatus(index);
                        
                        // Apply filters if active
                        if (_selectedStatusFilter != null || _selectedDateFilterType != null) {
                          _applyFilters();
                        }
                      }
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
  
  // Helper method to determine if a color is bright (for text contrast)
  bool _isColorBright(Color color) {
    // Calculate the perceived brightness using the formula:
    // (0.299 * R + 0.587 * G + 0.114 * B)
    double brightness = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return brightness > 0.5; // If brightness > 0.5, consider it bright
  }
  
  // Helper method to format duration for overdue callbacks
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }
  
  // Helper method to format time remaining until callback
  String _formatTimeToCallback(DateTime callbackTime) {
    final now = DateTime.now();
    final difference = callbackTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
  }

  // Function to show date and time picker
  Future<DateTime?> _selectCallbackTime(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
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

    if (pickedDate == null) return null;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
  
  // Helper method to update enquiry status via API
  Future<void> _updateEnquiryStatus(int index) async {
    try {
      // Get the enquiry ID from the User object
      final user = users[index];
      
      // Parse ID safely
      int enquiryId;
      if (user.id != null) {
        try {
          // Try to parse as integer first
          enquiryId = int.parse(user.id!);
        } catch (e) {
          // If that fails, try to parse as double and convert to int
          try {
            double doubleId = double.parse(user.id!);
            enquiryId = doubleId.toInt();
          } catch (e) {
            // If all parsing fails, use the index
            enquiryId = index;
            print('Error parsing ID for status update: $e');
          }
        }
      } else {
        enquiryId = index;
      }
      
      // Create status data from User object
      final statusData = {
        'status': user.statusId,
        'callback_time': user.callbackTime?.toIso8601String(),
      };
      
      // Update enquiry status through API
      await _apiService.updateEnquiryStatus(enquiryId.toString(), user.statusId.toString(), statusData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFFA3FF40)),
                const SizedBox(width: 10),
                const Text('Status updated successfully'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(child: Text('Failed to update status: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red.withOpacity(0.2),
          ),
        );
      }
    }
  }

  // Navigate to UserEntryPage and wait for result
  void _addNewUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserEntryPage(statusOptions: statusOptions),
      ),
    );

    if (result != null && result is User) {
      try {
        // Show loading indicator
        setState(() {
          _isLoading = true;
        });
        
        // Create enquiry data from User object
        final enquiryData = {
          'name': result.name,
          'mobile': result.mobile,
          'callback_time': result.callbackTime?.toIso8601String(),
          'remark': result.remark,
          'package_name': result.packageName,
          'total_amount': result.totalAmount,
          'paid_amount': result.paidAmount,
          'status': result.statusId,
        };
        
        // Create enquiry through API
        await _apiService.createEnquiry(enquiryData);
        
        // Refresh enquiry list
        await _fetchEnquiries();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFA3FF40)),
                  const SizedBox(width: 10),
                  const Text('Enquiry added successfully'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Failed to add enquiry: $e')),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.red.withOpacity(0.2),
            ),
          );
        }
        
        // Add to local list as fallback
        setState(() {
          users.add(result);
          _filteredUsers = users; // Update filtered list
        });
      }
    }
  }

  // Function to edit user details
  void _editUser(int index) async {
    final currentUser = users[index];
    
    // Preserve the ID when passing to the edit page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserEntryPage(user: currentUser, statusOptions: statusOptions),
      ),
    );

    if (result != null && result is User) {
      try {
        // Show loading indicator
        setState(() {
          _isLoading = true;
        });
        
        // Parse ID safely
        int enquiryId;
        if (currentUser.id != null) {
          try {
            // Try to parse as integer first
            enquiryId = int.parse(currentUser.id!);
          } catch (e) {
            // If that fails, try to parse as double and convert to int
            try {
              double doubleId = double.parse(currentUser.id!);
              enquiryId = doubleId.toInt();
            } catch (e) {
              // If all parsing fails, use the index
              enquiryId = index;
              print('Error parsing ID for edit: $e');
            }
          }
        } else {
          enquiryId = index;
        }
        
        // Preserve the ID in the updated user
        result.id = currentUser.id;
        
        // Create enquiry data from User object
        final enquiryData = {
          'name': result.name,
          'mobile': result.mobile,
          'callback_time': result.callbackTime?.toIso8601String(),
          'remark': result.remark,
          'package_name': result.packageName,
          'total_amount': result.totalAmount,
          'paid_amount': result.paidAmount,
          'status': result.statusId,
        };
        
        // Update enquiry through API
        await _apiService.updateEnquiry(enquiryId.toString(), enquiryData);
        
        // Refresh enquiry list
        await _fetchEnquiries();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFA3FF40)),
                  const SizedBox(width: 10),
                  const Text('Enquiry updated successfully'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          users[index] = result; // Update user in the local list as fallback
          _filteredUsers = users; // Update filtered list
          
          // Apply filters if active
          if (_selectedStatusFilter != null || _selectedDateFilterType != null) {
            _applyFilters();
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Failed to update enquiry: $e')),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.red.withOpacity(0.2),
            ),
          );
        }
      }
    }
  }
  
  // Build card for each enquiry based on the provided design in the image
  Widget _buildEnquiryCard(BuildContext context, int index) {
    final user = _filteredUsers[index];
    
    // Determine status display and color based on statusId
    // Find the status option with the matching ID
    SelectionStatus matchingStatus = statusOptions.firstWhere(
      (status) => status.id == user.statusId,
      orElse: () => SelectionStatus(
        id: "0",
        displyName: "Unknown",
        statusColorCode: "#808080",
        type: "default",
      ),
    );
    
    String statusDisplay = matchingStatus.displyName;
    Color statusColor = _hexToColor(matchingStatus.statusColorCode);
    
    // Check if callback is overdue
    bool isCallbackOverdue = false;
    Duration? overdueTime;
    if (matchingStatus.type == 'timer' && user.callbackTime != null) {
      DateTime now = DateTime.now();
      if (now.isAfter(user.callbackTime!)) {
        isCallbackOverdue = true;
        overdueTime = now.difference(user.callbackTime!);
      }
    }
    
    // Format callback date
    String callbackDateStr = user.callbackTime != null 
        ? "Apr ${user.callbackTime!.day}, ${user.callbackTime!.year}"
        : "";
    
    // Determine if this is a callback scheduled card
    bool hasScheduledCallback = user.statusType == 'timer' && user.callbackTime != null && user.isScheduled == true;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Status badge - make it tappable
                GestureDetector(
                  onTap: () => _updateStatus(users.indexOf(user)), // Show status selection window
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusDisplay,
                          style: TextStyle(
                            color: _isColorBright(statusColor) ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Phone number
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_android,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  user.mobile.length >= 10 
                      ? "(${user.mobile.substring(0, 3)}) ${user.mobile.substring(3, 6)}-${user.mobile.substring(6)}"
                      : user.mobile,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Package and Total Amount
            Row(
              children: [
                // Package
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Package",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.packageName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Total Amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${user.totalAmount}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Paid Amount and Date
            Row(
              children: [
                // Paid Amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Paid Amount",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${user.paidAmount}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        callbackDateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Remarks
            if (user.remark.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.remark,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Callback scheduled info - make it tappable
            if (hasScheduledCallback) ...[
              GestureDetector(
                onTap: () async {
                  // Show date picker to edit callback time
                  DateTime? selectedDateTime = await _selectCallbackTime(context);
                  if (selectedDateTime != null) {
                    setState(() {
                      user.callbackTime = selectedDateTime;
                      user.isScheduled = true;
                    });
                    // Update via API
                    _updateEnquiryStatus(users.indexOf(user));
                  }
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Callback scheduled for ${DateFormat('MMM d, h:mm a').format(user.callbackTime!)}",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit,
                      color: Colors.orange,
                      size: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Action buttons (removed Schedule Callback button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mark as Converted button
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Mark as Converted"),
                    onPressed: () {
                      // Find the "Converted" status option
                      final convertedStatus = statusOptions.firstWhere(
                        (status) => status.displyName == "Converted",
                        orElse: () => SelectionStatus(
                          id: "4", // Using "Interested" as fallback
                          displyName: "Converted",
                          statusColorCode: "#008000",
                          type: "default",
                        ),
                      );
                      
                      // Update status to Converted
                      setState(() {
                        users[users.indexOf(user)].statusId = convertedStatus.id;
                        users[users.indexOf(user)].statusType = convertedStatus.type;
                        users[users.indexOf(user)].statusColorCode = convertedStatus.statusColorCode;
                      });
                      _updateEnquiryStatus(users.indexOf(user));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Call button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () {
                      launchUrl(Uri.parse("tel:${user.mobile}"));
                    },
                    color: Colors.white,
                  ),
                ),
              ],
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
        title: const Text("Enquiries"),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: "Filter",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFA3FF40),
              ),
            )
          : _errorMessage != null && users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        onPressed: _fetchEnquiries,
                      ),
                    ],
                  ),
                )
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            color: Colors.white54,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No enquiries match your filters",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.filter_alt_off),
                            label: const Text("Clear Filters"),
                            onPressed: () {
                              setState(() {
                                _selectedStatusFilter = null;
                                _selectedDateFilterType = null;
                                _selectedDateFilter = null;
                                _filteredUsers = users;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 12, bottom: 80),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        return _buildEnquiryCard(context, index);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewUser,
        child: const Icon(Icons.add),
      ),
    );
  }
}
