import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../views/appointments/appointment_list_view.dart';
import '../views/resources/resource_list_view.dart';
import 'bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final Widget? title;
  final Widget body;
  final int currentIndex;
  final bool hideBackButton;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Function(int)? onNavigationItemSelected;

  const AppScaffold({
    Key? key,
    this.title,
    required this.body,
    required this.currentIndex,
    this.hideBackButton = false,
    this.actions,
    this.floatingActionButton,
    this.onNavigationItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !hideBackButton,
        title: title ?? const Text(''),
        backgroundColor: const Color(0xFFE8F3F1),
        foregroundColor: const Color(0xFF2D3436),
        elevation: 0,
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
                            final navigator = Navigator.of(context);
                            Navigator.pop(context);
                            await context.read<AuthController>().logout();
                            navigator.pushNamedAndRemoveUntil('/login', (route) => false);
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
        child: BottomNavBar(
          currentIndex: currentIndex,
          onTap: onNavigationItemSelected,
        ),
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
