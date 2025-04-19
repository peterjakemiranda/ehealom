import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final isOnline = appointment.locationType == 'online';
    final canUpdateMeetingLink = isCounselor && isOnline && 
        ['pending', 'confirmed'].contains(appointment.status.toLowerCase());

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
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
            _buildDetailRow('Location Type', 
              appointment.locationType == 'online' ? 'Online' : 'On-site'
            ),
            if (appointment.locationType == 'online')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 100,
                      child: Text(
                        'Meeting Link',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMeetingLinkText(context),
                          ),
                          if (canUpdateMeetingLink)
                            IconButton(
                              onPressed: () => _updateMeetingLink(context),
                              icon: const Icon(Icons.edit, size: 16),
                              tooltip: 'Update Meeting Link',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            _buildDetailRow('Reason', appointment.reason),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _buildDetailRow('Remarks', appointment.notes!),
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
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    try {
      final appointmentService = AppointmentService();
      
      // If completing the appointment, show a dialog for remarks
      if (newStatus.toLowerCase() == 'completed') {
        // Use the new stateful dialog
        final remarks = await _showRemarksDialog(context);
        if (remarks == null) return; // User cancelled
        
        await appointmentService.updateStatus(
          appointment.uuid,
          newStatus,
          notes: remarks,
        );
      } else {
        await appointmentService.updateStatus(
          appointment.uuid,
          newStatus,
        );
      }
      
      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Appointment ${newStatus.toLowerCase()} successfully')),
      );
      
      // Close the dialog and notify parent
      navigator.pop();
      onStatusUpdated?.call();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }

  Future<String?> _showRemarksDialog(BuildContext context) async {
    // Show the stateful dialog widget
    final result = await showDialog<String>(
      context: context,
      // Use the new _RemarksDialog widget
      builder: (dialogContext) => const _RemarksDialog(), 
    );
    // No controller creation or disposal needed here anymore
    return result;
  }

  Future<void> _updateMeetingLink(BuildContext context) async {
    // Get the initial value, handling the placeholder '-' and potential nulls
    final initialLink = (appointment.location == null || appointment.location == '-') 
                          ? '' 
                          : appointment.location!;
    
    // Show the stateful dialog widget
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _MeetingLinkDialog(initialValue: initialLink),
    );
    
    // No controller creation or disposal needed here anymore
    
    // Process the result if not null (dialog was not cancelled)
    if (result != null) {
      final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture messenger
      final navigator = Navigator.of(context); // Capture navigator
      try {
        final appointmentService = AppointmentService();
        await appointmentService.updateLocation(
          appointment.uuid,
          result.isEmpty ? '-' : result, // Handle empty input back to placeholder
        );
        
        // Close the details sheet and refresh the parent
        navigator.pop(); 
        onStatusUpdated?.call();
        
        // Show success message
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Meeting link updated successfully')),
        );
      } catch (e) {
        // Show error message
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to update meeting link: $e')),
        );
      }
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

  Widget _buildMeetingLinkText(BuildContext context) {
    final location = appointment.location ?? '-';
    return location == '-'
        ? Text(location, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic))
        : InkWell(
            onTap: () => _launchURL(location),
            child: Text(
              location,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Define the stateful widget for the remarks dialog
class _RemarksDialog extends StatefulWidget {
  const _RemarksDialog({Key? key}) : super(key: key);

  @override
  _RemarksDialogState createState() => _RemarksDialogState();
}

class _RemarksDialogState extends State<_RemarksDialog> {
  late final TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController();
  }

  @override
  void dispose() {
    _remarksController.dispose(); // Dispose the controller here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Appointment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter any remarks about this appointment:'),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksController, // Use the state's controller
              decoration: const InputDecoration(
                hintText: 'Enter remarks...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Pop without value (cancel)
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Pop with the text value
            Navigator.of(context).pop(_remarksController.text); 
          },
          child: const Text('Complete'),
        ),
      ],
    );
  }
}

// Define the stateful widget for the meeting link dialog
class _MeetingLinkDialog extends StatefulWidget {
  final String initialValue;

  const _MeetingLinkDialog({Key? key, required this.initialValue}) : super(key: key);

  @override
  _MeetingLinkDialogState createState() => _MeetingLinkDialogState();
}

class _MeetingLinkDialogState extends State<_MeetingLinkDialog> {
  late final TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _linkController.dispose(); // Dispose the controller here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Meeting Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the meeting URL for this appointment:'),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController, // Use the state's controller
            decoration: const InputDecoration(
              hintText: 'https://meet.google.com/...',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Pop without value (cancel)
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
             // Pop with the text value
            Navigator.of(context).pop(_linkController.text);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 