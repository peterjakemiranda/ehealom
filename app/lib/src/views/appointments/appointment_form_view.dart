import 'package:flutter/material.dart';
import '../../services/appointment_service.dart';
import '../../widgets/app_scaffold.dart';

class AppointmentFormView extends StatefulWidget {
  static const routeName = '/appointments/create';

  const AppointmentFormView({Key? key}) : super(key: key);

  @override
  State<AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<AppointmentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _appointmentService = AppointmentService();
  
  String? _selectedCounselorId;
  DateTime? _selectedDate;
  String? _selectedTime;
  String _reason = '';
  String _locationType = 'online';
  String? _location;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _counselors = [];
  List<Map<String, dynamic>> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadCounselors();
  }

  Future<void> _loadCounselors() async {
    setState(() => _isLoading = true);
    try {
      _counselors = await _appointmentService.getCounselors();
      if (_counselors.isNotEmpty) {
        _selectedCounselorId = _counselors.first['id'].toString();
        if (_selectedDate != null) {
          await _loadTimeSlots();
        }
      }
    } catch (e) {
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
    if (_selectedCounselorId == null || _selectedDate == null) return;
    
    setState(() => _isLoading = true);
    try {
      _timeSlots = await _appointmentService.fetchAvailableSlots(
        counselorId: _selectedCounselorId!,
        date: _selectedDate!.toIso8601String().split('T')[0],
      );
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load time slots: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Book Appointment',
      currentIndex: -1,
      body: _isLoading && _counselors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDatePicker(),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 16),
                    _buildTimeSlots(),
                  ],
                  const SizedBox(height: 16),
                  _buildReasonField(),
                  const SizedBox(height: 16),
                  _buildLocationTypeField(),
                  if (_locationType == 'on-site') ...[
                    const SizedBox(height: 16),
                    _buildLocationField(),
                  ],
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
    if (_timeSlots.isEmpty) {
      return const Center(
        child: Text('No available time slots for selected date'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timeSlots.map((slot) {
        final time = slot['time'];
        final isAvailable = slot['available'];
        final isSelected = _selectedTime == time;

        return FilterChip(
          label: Text(slot['display_time']),
          selected: isSelected,
          onSelected: isAvailable ? (selected) {
            setState(() => _selectedTime = selected ? time : null);
          } : null,
          backgroundColor: isAvailable ? null : Colors.grey.shade200,
          labelStyle: TextStyle(
            color: isAvailable ? null : Colors.grey,
          ),
        );
      }).toList(),
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
            onChanged: (value) => setState(() => _locationType = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Location Details',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => _location = value,
      validator: (value) {
        if (_locationType == 'on-site' && (value == null || value.isEmpty)) {
          return 'Please enter location details';
        }
        return null;
      },
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
    if (_selectedCounselorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No counselor available')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appointmentDate = DateTime.parse(
        '${_selectedDate!.toIso8601String().split('T')[0]}T$_selectedTime:00',
      );
      
      await _appointmentService.createAppointment({
        'counselor_id': _selectedCounselorId!,
        'appointment_date': appointmentDate.toIso8601String(),
        'reason': _reason,
        'location_type': _locationType,
        'location': _location,
      });
      
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