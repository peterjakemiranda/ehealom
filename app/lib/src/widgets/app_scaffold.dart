import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../views/appointments/appointment_list_view.dart';
import '../views/resources/resource_list_view.dart';
import 'bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool hideBackButton;

  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.currentIndex,
    this.actions,
    this.floatingActionButton,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !hideBackButton,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('My Profile'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/profile');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Logout'),
                          onTap: () async {
                            Navigator.pop(context);
                            await authController.logout();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (actions != null) ...actions!,
        ],
      ),
      body: body,
      bottomNavigationBar: currentIndex >= 0 ? Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavBar(currentIndex: currentIndex),
      ) : null,
      floatingActionButton: floatingActionButton,
    );
  }
}

class NoTransitionRoute<T> extends MaterialPageRoute<T> {
  NoTransitionRoute({required WidgetBuilder builder}) 
    : super(builder: builder);

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;  // Return the child directly without any transition animation
  }
}
