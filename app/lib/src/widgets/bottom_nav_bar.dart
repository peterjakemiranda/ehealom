import 'package:flutter/material.dart';
import '../views/home/home_view.dart';
import '../views/appointments/appointment_list_view.dart';
import '../views/resources/resource_list_view.dart';
import 'app_scaffold.dart';

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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Appointments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          activeIcon: Icon(Icons.library_books),
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
    
    final routes = [
      '/',
      '/appointments',
      '/resources',
    ];

    Navigator.pushReplacement(
      context,
      NoTransitionRoute(
        builder: (context) {
          switch (index) {
            case 0:
              return const HomeView();
            case 1:
              return const AppointmentListView();
            case 2:
              return const ResourceListView();
            default:
              return const HomeView();
          }
        },
      ),
    );
  }
} 