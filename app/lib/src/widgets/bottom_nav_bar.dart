import 'package:flutter/material.dart';
import '../views/home/home_view.dart';
import '../views/appointments/appointment_list_view.dart';
import '../views/resources/resource_list_view.dart';
import 'app_scaffold.dart';
import '../controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final roles = authController.user?['user']?['roles'] as List<dynamic>?;
    final isCounselor = roles?.any((role) => role['name'] == 'counselor') ?? false;
    
    // Calculate the correct index for each tab based on user role
    final homeIndex = isCounselor ? -1 : 0;
    final appointmentsIndex = isCounselor ? 0 : 1;
    final resourcesIndex = isCounselor ? 1 : 2;
    final chatIndex = isCounselor ? 2 : 3;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (isCounselor) {
          // Adjust index mapping for counselors (no home tab)
          switch (index) {
            case 0: // Appointments
              Navigator.pushReplacementNamed(context, '/appointments');
              break;
            case 1: // Resources
              Navigator.pushReplacementNamed(context, '/resources');
              break;
            case 2: // Chat
              Navigator.pushReplacementNamed(context, '/chat');
              break;
          }
        } else {
          // Regular users
          switch (index) {
            case 0: // Home
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1: // Appointments
              Navigator.pushReplacementNamed(context, '/appointments');
              break;
            case 2: // Resources
              Navigator.pushReplacementNamed(context, '/resources');
              break;
            case 3: // Chat
              Navigator.pushReplacementNamed(context, '/chat');
              break;
          }
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.6),
      items: [
        if (!isCounselor)
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Appointments',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: 'Resources',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
      ],
    );
  }
} 