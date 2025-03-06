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
    final isCounselor = authController.user?['roles']?.contains('counselor') ?? false;

    return BottomNavigationBar(
      currentIndex: currentIndex,
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
      ],
      onTap: (index) {
        if (onTap != null) {
          onTap!(index);
        } else {
          _onNavigationTap(context, index);
        }
      },
    );
  }

  void _onNavigationTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    
    final authController = context.read<AuthController>();
    final isCounselor = authController.user?['roles']?.contains('counselor') ?? false;

    // Adjust index for counselors (who don't have home tab)
    final adjustedIndex = isCounselor ? index + 1 : index;

    Navigator.pushReplacement(
      context,
      NoTransitionRoute(
        builder: (context) {
          switch (adjustedIndex) {
            case 0:
              return const HomeView();
            case 1:
              return const AppointmentListView();
            case 2:
              return const ResourceListView();
            default:
              return isCounselor ? const AppointmentListView() : const HomeView();
          }
        },
      ),
    );
  }
} 