import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment.dart';
import '../../models/resource.dart';
import '../../services/appointment_service.dart';
import '../../services/resource_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../resources/resource_details_view.dart';
import 'dart:convert';

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
      
      // Add listener for auth state changes
      context.read<AuthController>().addListener(_handleAuthStateChange);
    });
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authController = context.read<AuthController>();
    
    if (!authController.isAuthenticated && !authController.isLoading) {
      debugPrint('User not authenticated, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    
    final user = authController.user;
    debugPrint('HomeView - didChangeDependencies - User data: $user');
  }

  @override
  void dispose() {
    // Remove listener when disposing
    context.read<AuthController>().removeListener(_handleAuthStateChange);
    super.dispose();
  }

  void _handleAuthStateChange() {
    final authController = context.read<AuthController>();
    if (!authController.isAuthenticated && !authController.isLoading) {
      debugPrint('User logged out, redirecting to login');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final appointmentsResult = await _appointmentService.fetchAppointments(
        perPage: 5,
        page: 1,
        upcoming: true,
      );
      
      final resourcesResult = await _resourceService.fetchResources(
        perPage: 3,
      );

      debugPrint('Appointments Result: ${jsonEncode(appointmentsResult)}');
      debugPrint('Resources Result: ${jsonEncode(resourcesResult)}');

      final appointmentsList = appointmentsResult['data'] as List?;
      final resourcesList = resourcesResult['data'] as List?;

      debugPrint('Appointments List Length: ${appointmentsList?.length}');
      debugPrint('Resources List Length: ${resourcesList?.length}');

      setState(() {
        _upcomingAppointments = (appointmentsList ?? [])
            .map((item) {
              debugPrint('Processing appointment item: $item');
              return Appointment.fromJson(item as Map<String, dynamic>);
            })
            .toList();

        _relatedResources = (resourcesList ?? [])
            .map((item) {
              debugPrint('Processing resource item: $item');
              return Resource.fromJson(item as Map<String, dynamic>);
            })
            .toList();
        
        debugPrint('Processed Appointments Count: ${_upcomingAppointments.length}');
        debugPrint('Processed Resources Count: ${_relatedResources.length}');
        
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _loadData: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createAppointment() async {
    final result = await Navigator.pushNamed(
      context,
      '/appointments/create',
    );
    
    if (result == true) {
      // Refresh data when returning from appointment creation
      debugPrint('🔄 Refreshing home data after appointment creation');
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final userName = user?['user']?['name']?.split(' ')[0] ?? 'there';

    return AppScaffold(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 30,
            fit: BoxFit.contain,
          ),
        ],
      ),
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
                    ElevatedButton.icon(
                      onPressed: _createAppointment,
                      icon: const Icon(Icons.add),
                      label: const Text('Book Appointment'),
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
    final isPending = nextAppointment.status.toLowerCase() == 'pending';

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
                              nextAppointment.counselor?['name'] ?? 'Counselor',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Counselor',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(nextAppointment.appointmentDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        nextAppointment.locationType == 'online'
                            ? 'Online'
                            : nextAppointment.location ?? 'On-site',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFA726),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pending_outlined,
                            size: 16,
                            color: const Color(0xFFFFA726),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pending Confirmation',
                            style: TextStyle(
                              color: const Color(0xFFFFA726),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 240,
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
    final categoryTitle = resource.categories.isNotEmpty 
        ? resource.categories.first['title'].toLowerCase()
        : 'general';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          debugPrint('Navigating to resource: ${resource.uuid}');
          Navigator.pushNamed(
            context,
            ResourceDetailsView.routeName,
            arguments: resource.uuid,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.imageUrl != null)
              Image.network(
                resource.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                  ),
                ),
              )
            else
              Container(
                height: 120,
                color: _getResourceColor(categoryTitle),
                child: Icon(
                  _getResourceIcon(categoryTitle),
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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