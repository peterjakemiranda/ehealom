import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment.dart';
import '../../models/resource.dart';
import '../../services/appointment_service.dart';
import '../../services/resource_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../resources/resource_details_view.dart';

class HomeView extends StatefulWidget {
  static const routeName = '/home';
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _appointmentService = AppointmentService();
  final _resourceService = ResourceService();
  
  List<Appointment> _upcomingAppointments = [];
  List<Resource> _relatedResources = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().user;
      debugPrint('HomeView - User data: $user');
    });
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthController>().user;
    debugPrint('HomeView - didChangeDependencies - User data: $user');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final appointmentsResult = await _appointmentService.fetchAppointments(
        perPage: 5,
        page: 1,
      );
      
      final resourcesResult = await _resourceService.fetchResources(
        perPage: 3,
      );

      setState(() {
        _upcomingAppointments = appointmentsResult['appointments'];
        _relatedResources = resourcesResult['resources'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final userName = user?['user']?['name']?.split(' ')[0] ?? 'there';

    return AppScaffold(
      title: '',
      currentIndex: 0,
      hideBackButton: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(userName),
                        if (_upcomingAppointments.isNotEmpty)
                          _buildUpcomingAppointment(),
                        _buildWellnessResources(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildWelcomeSection(String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hey, $name',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Every day is a new opportunity to grow and find strength within yourself',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (_upcomingAppointments.isEmpty) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: const Color(0xFFE8F3F1),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Need someone to talk to?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Book an appointment with your counselor',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/appointments/create',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Book Now'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointment() {
    final nextAppointment = _upcomingAppointments.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming appointment',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/appointments'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: const Color(0xFFE8F3F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextAppointment.counselor?['name'] ?? 'Your Counselor',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Therapist',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_horiz,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          // Show appointment details
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatAppointmentDate(nextAppointment.appointmentDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatAppointmentTime(nextAppointment.appointmentDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/appointments/create',
              ),
              icon: const Icon(Icons.add),
              label: const Text('Book another appointment'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAppointmentDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatAppointmentTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final endHour = (date.hour + 1) > 12 ? (date.hour + 1) - 12 : (date.hour + 1);
    return '$hour:00 - $endHour:00 $period';
  }

  Widget _buildWellnessResources() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wellness resources',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/resources'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: _relatedResources.length,
            itemBuilder: (context, index) {
              final resource = _relatedResources[index];
              return _buildResourceCard(resource);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Resource resource) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        ResourceDetailsView.routeName,
        arguments: resource.uuid,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _getResourceColor(resource.category),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  _getResourceIcon(resource.category),
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.content,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResourceColor(String category) {
    switch (category.toLowerCase()) {
      case 'mental-health':
        return const Color(0xFFE8F3F1); // Soft mint
      case 'academic':
        return const Color(0xFFF8E8D4); // Soft peach
      case 'career':
        return const Color(0xFFF0F4FD); // Soft blue
      default:
        return const Color(0xFFF5F5F5); // Light gray
    }
  }

  IconData _getResourceIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mental-health':
        return Icons.psychology;
      case 'academic':
        return Icons.school;
      case 'career':
        return Icons.work;
      default:
        return Icons.article;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final time = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    return '$date at $time';
  }
} 