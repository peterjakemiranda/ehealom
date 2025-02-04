import 'package:flutter/material.dart';
import '../../models/appointment.dart';

class AppointmentDetailsSheet extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailsSheet({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: Theme.of(context).textTheme.titleLarge,
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
            'Counselor', 
            appointment.counselor?['name'] ?? 'Not assigned'
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
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