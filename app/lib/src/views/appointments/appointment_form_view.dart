import 'package:flutter/material.dart';
import '../../services/appointment_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../controllers/auth_controller.dart';
import 'dart:async';  // Add this import for Timer
import 'package:provider/provider.dart';  // Add this for context.read()
import '../../services/category_service.dart';

class AppointmentFormView extends StatefulWidget {
  static const routeName = '/appointments/create';

  const AppointmentFormView({Key? key}) : super(key: key);

  @override
  State<AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<AppointmentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _appointmentService = AppointmentService();
  final _studentSearchController = TextEditingController();
  final _authController = AuthController();
  final _studentNameController = TextEditingController();
  final _studentIdNumberController = TextEditingController();
  final _studentEmailController = TextEditingController();
  
  String? _selectedCounselorId;
  DateTime? _selectedDate;
  String? _selectedTime;
  String _reason = '';
  String _locationType = 'online';
  String? _location;
  bool _isLoading = false;
  bool _isNewStudent = false;
  
  List<Map<String, dynamic>> _counselors = [];
  List<String> _timeSlots = [];
  Map<String, dynamic>? _selectedStudent;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  final _categoryService = CategoryService();
  String? _excludedDateReason;

  @override
  void initState() {
    super.initState();
    _loadCounselors();
    _loadCategories();
  }

  Future<void> _loadCounselors() async {
    debugPrint('🔄 Loading counselors...');
    setState(() => _isLoading = true);
    try {
      _counselors = await _appointmentService.getCounselors();
      debugPrint('✅ Loaded ${_counselors.length} counselors');
      if (_counselors.isNotEmpty) {
        _selectedCounselorId = _counselors.first['id'].toString();
        debugPrint('👉 Selected counselor ID: $_selectedCounselorId');
        if (_selectedDate != null) {
          await _loadTimeSlots();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading counselors: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load counselor: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimeSlots() async {
    if (_selectedCounselorId == null || _selectedDate == null) {
      debugPrint('⚠️ Cannot load time slots: counselor or date not selected');
      return;
    }
    
    debugPrint('🔄 Loading time slots for counselor: $_selectedCounselorId, date: $_selectedDate');
    setState(() => _isLoading = true);
    try {
      final result = await _appointmentService.fetchAvailableSlots(
        counselorId: _selectedCounselorId!,
        date: _selectedDate!.toIso8601String().split('T')[0],
      );
      
      debugPrint('✅ Loaded time slots response: $result');
      setState(() {
        _timeSlots = List<String>.from(result['slots'] as List);
        _excludedDateReason = (result['is_excluded'] as bool?) == true ? result['reason'] as String? : null;
      });
    } catch (e) {
      debugPrint('❌ Error loading time slots: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load time slots: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isCounselor = authController.user?['roles']?.contains('counselor') ?? false;

    return AppScaffold(
      title: const Text('Book Appointment'),
      currentIndex: -1,
      body: _isLoading && _counselors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Only show student selection for counselors
                  if (isCounselor) _buildStudentSection(),
                  
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 16),
                    _buildTimeSlots(),
                  ],
                  const SizedBox(height: 16),
                  _buildReasonField(),
                  const SizedBox(height: 16),
                  _buildLocationTypeField(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Book Appointment'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(_isNewStudent ? 'New Student' : 'Existing Student'),
          value: _isNewStudent,
          onChanged: (value) {
            setState(() {
              _isNewStudent = value;
              _selectedStudent = null;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_isNewStudent) ...[
          TextFormField(
            controller: _studentNameController,
            decoration: const InputDecoration(
              labelText: 'Student Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _studentIdNumberController,
            decoration: const InputDecoration(
              labelText: 'Student ID Number',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _studentEmailController,
            decoration: const InputDecoration(
              labelText: 'Student Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (!value!.contains('@')) return 'Invalid email';
              return null;
            },
          ),
        ] else
          _buildStudentSearch(),
      ],
    );
  }

  Widget _buildStudentSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (option) => 
            '${option['name']} (${option['student_id'] ?? 'No ID'})',
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) return const [];
            
            try {
              final results = await _appointmentService.searchStudents(
                textEditingValue.text,
                role: 'student',  // Add role parameter
              );
              return results;
            } catch (e) {
              debugPrint('Error searching students: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to search students: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return const [];
            }
          },
          onSelected: (Map<String, dynamic> selection) {
            setState(() {
              _selectedStudent = selection;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Search Student',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              validator: (value) {
                if (_selectedStudent == null) {
                  return 'Please select a student';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: [
        // Add a default "Select category" item
        const DropdownMenuItem(
          value: '',
          child: Text('Select category'),
        ),
        ..._categories.map((category) {
          return DropdownMenuItem(
            value: category['id'].toString(),
            child: Text(category['title']), // Changed from 'name' to 'title'
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Select Date',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: _selectedDate != null 
          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
          : '',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        
        if (date != null) {
          setState(() {
            _selectedDate = date;
            _selectedTime = null;
            _timeSlots.clear();
          });
          _loadTimeSlots();
        }
      },
      validator: (value) {
        if (_selectedDate == null) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }

  Widget _buildTimeSlots() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_timeSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_excludedDateReason != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _excludedDateReason!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              const Text('No available time slots for selected date'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time Slots',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeSlots.map((time) {
            final isSelected = _selectedTime == time;
            
            // Convert 24hr to 12hr format
            final timeComponents = time.split(':');
            final hour = int.parse(timeComponents[0]);
            final minute = timeComponents[1];
            final period = hour >= 12 ? 'PM' : 'AM';
            final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            final displayTime = '$displayHour:$minute $period';

            return FilterChip(
              label: Text(displayTime),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedTime = selected ? time : null);
              },
              backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Reason for Appointment',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      onChanged: (value) => _reason = value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a reason';
        }
        return null;
      },
    );
  }

  Widget _buildLocationTypeField() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Online'),
            value: 'online',
            groupValue: _locationType,
            onChanged: (value) => setState(() => _locationType = value!),
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('On-site'),
            value: 'on-site',
            groupValue: _locationType,
            onChanged: (value) => setState(() {
              _locationType = value!;
              _location = null; // Clear location when switching to on-site
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appointmentDate = DateTime.parse(
        '${_selectedDate!.toIso8601String().split('T')[0]}T$_selectedTime',
      );
      
      final authController = context.read<AuthController>();
      final isCounselor = authController.user?['roles']?.contains('counselor') ?? false;
      final currentUserId = authController.user?['id'] ?? 
                           authController.user?['user']?['id']; // Check both locations

      debugPrint('Current user data: ${authController.user}'); // Debug log
      
      if (!isCounselor && currentUserId == null) {
        throw Exception('User ID not found');
      }

      final appointmentData = <String, dynamic>{
        'appointment_date': appointmentDate.toIso8601String(),
        'reason': _reason,
        'location_type': _locationType,
        'category_id': _selectedCategoryId,
      };

      if (isCounselor) {
        if (_isNewStudent) {
          appointmentData.addAll({
            'student_name': _studentNameController.text,
            'student_id_number': _studentIdNumberController.text,
            'student_email': _studentEmailController.text,
          });
        } else {
          appointmentData['student_id'] = _selectedStudent!['id'];
        }
      } else {
        appointmentData.addAll({
          'counselor_id': _selectedCounselorId,
          'student_id': currentUserId,
        });
      }

      debugPrint('Submitting appointment data: $appointmentData'); // Debug log
      await _appointmentService.createAppointment(appointmentData);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book appointment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 