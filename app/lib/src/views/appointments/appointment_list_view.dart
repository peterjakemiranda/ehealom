import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../widgets/app_scaffold.dart';
import 'appointment_form_view.dart';
import 'appointment_details_sheet.dart';

class AppointmentListView extends StatefulWidget {
  static const routeName = '/appointments';

  const AppointmentListView({Key? key}) : super(key: key);

  @override
  State<AppointmentListView> createState() => _AppointmentListViewState();
}

class _AppointmentListViewState extends State<AppointmentListView> {
  final _appointmentService = AppointmentService();
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String _selectedFilter = 'upcoming';
  DateTime? _selectedDate;
  String? _selectedStatus;
  Map<String, dynamic> _meta = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final result = await _appointmentService.fetchAppointments(
        status: _selectedStatus,
        date: _selectedDate?.toIso8601String(),
      );
      setState(() {
        _appointments = result['appointments'];
        _meta = result['meta'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appointments: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Appointments',
      currentIndex: 1,
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('Upcoming'),
                _buildFilterChip('Pending'),
                _buildFilterChip('Confirmed'),
                _buildFilterChip('Completed'),
                _buildFilterChip('Cancelled'),
              ],
            ),
          ),

          // Appointments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? const Center(child: Text('No appointments found'))
                    : ListView.builder(
                        itemCount: _appointments.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          return _AppointmentCard(
                            appointment: appointment,
                            onTap: () => _showAppointmentDetails(appointment),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAppointment,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = label.toLowerCase());
          _loadAppointments();
        },
      ),
    );
  }

  Future<void> _createAppointment() async {
    final result = await Navigator.pushNamed(
      context,
      AppointmentFormView.routeName,
    );
    if (result == true) {
      _loadAppointments();
    }
  }

  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AppointmentDetailsSheet(appointment: appointment),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;

  const _AppointmentCard({
    Key? key,
    required this.appointment,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appointment.reason,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(_formatDate(appointment.appointmentDate)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    appointment.locationType == 'online'
                        ? 'Online'
                        : appointment.location ?? 'On-site',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        appointment.status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (appointment.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 