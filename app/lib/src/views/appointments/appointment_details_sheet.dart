import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class AppointmentDetailsSheet extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onStatusUpdated;

  const AppointmentDetailsSheet({
    Key? key,
    required this.appointment,
    this.onStatusUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final roles = authController.user?['user']?['roles'] as List<dynamic>?;
    final isCounselor = roles?.any((role) => role['name'] == 'counselor') ?? false;
    final isStudent = roles?.any((role) => role['name'] == 'student' || role['name'] == 'personnel') ?? false;
    final isOwnAppointment = authController.user?['user']?['id'].toString() == appointment.studentId.toString();
    final canUpdateStatus = isCounselor && 
        ['pending', 'confirmed'].contains(appointment.status.toLowerCase());
    final canCancel = (isStudent && isOwnAppointment && 
        ['pending', 'confirmed'].contains(appointment.status.toLowerCase()));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Appointment Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Status', appointment.status.toUpperCase()),
          _buildDetailRow('Date', _formatDate(appointment.appointmentDate)),
          _buildDetailRow('Location', 
            appointment.locationType == 'online' ? 'Online' : appointment.location ?? 'On-site'
          ),
          _buildDetailRow('Reason', appointment.reason),
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            _buildDetailRow('Notes', appointment.notes!),
          _buildDetailRow(
            'User', 
            appointment.student?['name'] ?? 'Not assigned'
          ),
          _buildDetailRow(
            'Counselor', 
            appointment.counselor?['name'] ?? 'Not assigned'
          ),
          const SizedBox(height: 16),
          
          // Action Buttons for Counselors
          if (canUpdateStatus) ...[
            if (appointment.status.toLowerCase() == 'pending') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, 'confirmed'),
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Colors.white,
                  ),
                  child: const Text('Confirm Appointment'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, 'cancelled'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red.shade400,
                    onPrimary: Colors.white,
                  ),
                  child: const Text('Cancel Appointment'),
                ),
              ),
            ] else if (appointment.status.toLowerCase() == 'confirmed') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, 'completed'),
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Colors.white,
                  ),
                  child: const Text('Mark as Completed'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, 'cancelled'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red.shade400,
                    onPrimary: Colors.white,
                  ),
                  child: const Text('Cancel Appointment'),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
          
          // Cancel Button for Students
          if (canCancel) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmCancel(context),
                style: ElevatedButton.styleFrom(
                  primary: Colors.red.shade400,
                  onPrimary: Colors.white,
                ),
                child: const Text('Cancel Appointment'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                primary: Colors.grey[300],  // Light gray background
                onPrimary: Colors.grey[800],  // Dark gray text
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      final appointmentService = AppointmentService();
      await appointmentService.updateStatus(
        appointment.uuid,
        newStatus,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment ${newStatus.toLowerCase()} successfully')),
      );
      Navigator.pop(context);
      onStatusUpdated?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 