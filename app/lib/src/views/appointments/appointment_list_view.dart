import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../widgets/app_scaffold.dart';
import 'appointment_form_view.dart';
import 'appointment_details_sheet.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

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
  String _selectedFilter = 'pending';
  String _selectedUserType = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Map<String, int> _counts = {
    'pending': 0,
    'upcoming': 0,
    'history': 0,
  };
  Map<String, dynamic> _meta = {};

  // Update filter colors
  final Map<String, Color> _filterColors = {
    'pending': Colors.orange,             // Orange for pending
    'upcoming': const Color(0xFF1C0FD6),  // Primary blue
    'history': const Color(0xFF9E9E9E),   // Grey
  };

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadCounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final roles = authController.user?['user']?['roles'] as List<dynamic>?;
    final isCounselor = roles?.any((role) => role['name'] == 'counselor') ?? false;
    
    // Appointments is index 0 for counselors, index 1 for regular users
    final appointmentsIndex = isCounselor ? 0 : 1;
    
    return AppScaffold(
      title: const Text('Appointments'),
      currentIndex: appointmentsIndex,
      body: Column(
        children: [
          // Add filters at the top for counselors
          if (isCounselor) _buildFilters(),
          
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Row(
              children: [
                _buildFilterChip('Pending'),
                _buildFilterChip('Upcoming'),
                _buildFilterChip('History'),
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

  Future<void> _loadCounts() async {
    try {
      final counts = await _appointmentService.getAppointmentCounts(
        userType: _selectedUserType != 'all' ? _selectedUserType : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _counts = {
          'pending': counts['pending'] ?? 0,
          'upcoming': counts['upcoming'] ?? 0,
          'history': counts['history'] ?? 0,
        };
      });
    } catch (e) {
      debugPrint('❌ Error loading appointment counts: $e');
    }
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Type Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Filter by User Type',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedUserType,
            items: [
              DropdownMenuItem(value: 'all', child: Text('All Users')),
              DropdownMenuItem(value: 'student', child: Text('Students')),
              DropdownMenuItem(value: 'personnel', child: Text('Personnel')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedUserType = value!;
                _searchQuery = '';
                _searchController.clear();
              });
              _loadAppointments();
              _loadCounts();
            },
          ),

          // Search field
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by Name',
              hintText: 'Enter student or personnel name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _loadAppointments();
                        _loadCounts();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onSubmitted: (value) {
              _loadAppointments();
              _loadCounts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final filterKey = label.toLowerCase();
    final isSelected = _selectedFilter == filterKey;
    final count = _counts[filterKey] ?? 0;
    final color = _filterColors[filterKey] ?? Theme.of(context).primaryColor;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.3) 
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: color.withOpacity(0.12),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filterKey;
          });
          _loadAppointments();
          _loadCounts();
        },
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final result = await _appointmentService.fetchAppointments(
        status: _selectedFilter,
        userType: _selectedUserType != 'all' ? _selectedUserType : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      debugPrint('Appointments Result: ${jsonEncode(result)}');
      final appointmentsList = result['data'] as List?;
      
      setState(() {
        _appointments = (appointmentsList ?? [])
            .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
            .toList();
        _meta = result['meta'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appointments: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createAppointment() async {
    final result = await Navigator.pushNamed(
      context,
      '/appointments/create',
    );
    if (result == true) {
      _loadAppointments();
    }
  }

  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AppointmentDetailsSheet(
        appointment: appointment,
        onStatusUpdated: () {
          // Reload appointments and counts when status is updated
          _loadAppointments();
          _loadCounts();
        },
      ),
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
    final authController = Provider.of<AuthController>(context);
    final roles = authController.user?['user']?['roles'] as List<dynamic>?;
    final isCounselor = roles?.any((role) => role['name'] == 'counselor') ?? false;
    final isStudent = roles?.any((role) => role['name'] == 'student') ?? false;
    final isOwnAppointment = authController.user?['user']?['id'] == appointment.studentId;
    final canUpdateStatus = isCounselor && 
        ['pending', 'confirmed'].contains(appointment.status.toLowerCase());
    final canCancel = (isStudent && isOwnAppointment && 
        ['pending', 'confirmed'].contains(appointment.status.toLowerCase()));

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.reason,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (appointment.student != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            appointment.student?['name'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildStatusChip(),
                      if (canUpdateStatus) ...[
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String status) => _updateStatus(context, status),
                          itemBuilder: (BuildContext context) => _buildStatusMenuItems(),
                        ),
                      ],
                      if (canCancel) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _confirmCancel(context),
                          tooltip: 'Cancel appointment',
                        ),
                      ],
                    ],
                  ),
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
                  if (appointment.userType != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: appointment.userType == 'student' 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment.userType!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: appointment.userType == 'student' 
                              ? Colors.blue
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildStatusMenuItems() {
    final List<PopupMenuEntry<String>> items = [];
    
    if (appointment.status.toLowerCase() == 'pending') {
      items.addAll([
        const PopupMenuItem(
          value: 'confirmed',
          child: Text('Confirm Appointment'),
        ),
        const PopupMenuItem(
          value: 'cancelled',
          child: Text('Cancel Appointment'),
        ),
      ]);
    } else if (appointment.status.toLowerCase() == 'confirmed') {
      items.addAll([
        const PopupMenuItem(
          value: 'completed',
          child: Text('Mark as Completed'),
        ),
        const PopupMenuItem(
          value: 'cancelled',
          child: Text('Cancel Appointment'),
        ),
      ]);
    }
    
    return items;
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      final appointmentService = AppointmentService();
      await appointmentService.updateStatus(
        appointment.id,
        newStatus,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment ${newStatus.toLowerCase()} successfully')),
      );
      
      // Find the nearest AppointmentListView state and refresh
      final listViewState = context.findAncestorStateOfType<_AppointmentListViewState>();
      listViewState?._loadAppointments();
      listViewState?._loadCounts();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
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
        return const Color(0xFF1C0FD6);  // Primary blue instead of green
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(context, 'cancelled');
    }
  }
} 