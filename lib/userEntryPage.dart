import 'package:enquiry_app/models/enquiry_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserEntryPage extends StatefulWidget {
  final User? user;
  final List<SelectionStatus> statusOptions;

  const UserEntryPage({
    Key? key,
    this.user,
    required this.statusOptions,
  }) : super(key: key);

  @override
  _UserEntryPageState createState() => _UserEntryPageState();
}

class _UserEntryPageState extends State<UserEntryPage> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _remarkController;
  late TextEditingController _packageNameController;
  late TextEditingController _totalAmountController;
  late TextEditingController _paidAmountController;
  
  DateTime? _callbackTime;
  String _statusId = "5"; // Default to "Call Not Attended" (id: 5)
  String _statusDisplayName = "Call Not Attended";
  String _statusColorCode = "#808080";
  String _statusType = "default";

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _mobileController = TextEditingController(text: widget.user?.mobile ?? '');
    _remarkController = TextEditingController(text: widget.user?.remark ?? '');
    _packageNameController = TextEditingController(text: widget.user?.packageName ?? '');
    _totalAmountController = TextEditingController(text: widget.user?.totalAmount ?? '');
    _paidAmountController = TextEditingController(text: widget.user?.paidAmount ?? '');
    
    // Set other fields if editing
    if (widget.user != null) {
      _callbackTime = widget.user!.callbackTime;
      _statusId = widget.user!.statusId.toString();
      
      // Find the status display name from the ID
      final matchingStatus = widget.statusOptions.firstWhere(
        (status) => status.id == _statusId,
        orElse: () => SelectionStatus(
          id: "5",
          displyName: "Call Not Attended",
          statusColorCode: "#808080",
          type: "default",
        ),
      );
      _statusDisplayName = matchingStatus.displyName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _remarkController.dispose();
    _packageNameController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  // Function to show date and time picker
  Future<void> _selectCallbackTime(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _callbackTime ?? now,
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
      initialTime: _callbackTime != null
          ? TimeOfDay(hour: _callbackTime!.hour, minute: _callbackTime!.minute)
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
      _callbackTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // Function to show status selection
  void _showStatusSelection(BuildContext context) {
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
              ...widget.statusOptions.map((status) {
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
                      Navigator.pop(context);
                      
                      // Update status
                      setState(() {
                        _statusId = status.id;
                        _statusDisplayName = status.displyName;
                        _statusColorCode = status.statusColorCode;
                        _statusType = status.type;
                      });
                      
                      // Handle callback time based on status type
                      if (status.type == 'timer') {
                        // Always prompt for callback time for timer status
                        await _selectCallbackTime(context);
                      } else {
                        // Clear callback time for non-timer status
                        setState(() {
                          _callbackTime = null;
                        });
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

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // Add alpha value if missing
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Add New Enquiry' : 'Edit Enquiry'),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1C1C1E),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA3FF40)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Mobile field
              TextFormField(
                controller: _mobileController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA3FF40)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Package Name field
              TextFormField(
                controller: _packageNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Package Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA3FF40)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  prefixIcon: const Icon(Icons.inventory, color: Colors.white70),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a package name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Amount fields in a row
              Row(
                children: [
                  // Total Amount field
                  Expanded(
                    child: TextFormField(
                      controller: _totalAmountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Amount',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFA3FF40)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        prefixIcon: const Icon(Icons.attach_money, color: Colors.white70),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Paid Amount field
                  Expanded(
                    child: TextFormField(
                      controller: _paidAmountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Paid Amount',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFA3FF40)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        prefixIcon: const Icon(Icons.payments, color: Colors.white70),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Remark field
              TextFormField(
                controller: _remarkController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Remark',
                  labelStyle: const TextStyle(color: Colors.white70),
                  alignLabelWithHint: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA3FF40)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 45),
                    child: Icon(Icons.comment, color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Status selection
              const Text(
                'Status',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showStatusSelection(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _hexToColor(_statusColorCode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hexToColor(_statusColorCode).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusType == 'timer' ? Icons.timer : Icons.check_circle,
                        color: _hexToColor(_statusColorCode),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _statusDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Callback time selection (if status type is timer)
              if (_statusType == 'timer')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Callback Time',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectCallbackTime(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _callbackTime != null
                                  ? DateFormat('dd MMM yyyy hh:mm a').format(_callbackTime!)
                                  : 'Select Callback Time',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Validate callback time if status type is timer
                      if (_statusType == 'timer' && _callbackTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a callback time'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // Create user object
                      final user = User(
                        name: _nameController.text,
                        mobile: _mobileController.text,
                        callbackTime: _callbackTime,
                        remark: _remarkController.text,
                        packageName: _packageNameController.text,
                        totalAmount: _totalAmountController.text,
                        paidAmount: _paidAmountController.text,
                        statusId: _statusId,
                        isScheduled: _statusType == 'timer' && _callbackTime != null,
                      );
                      
                      // Return user to previous screen
                      Navigator.pop(context, user);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA3FF40),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.user == null ? 'Add Enquiry' : 'Update Enquiry',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
