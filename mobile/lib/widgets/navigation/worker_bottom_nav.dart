import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../routes/app_routes.dart';

class WorkerBottomNav extends StatelessWidget {
  final Widget child;

  const WorkerBottomNav({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/worker/dashboard')) return 0;
    if (location.startsWith('/worker/jobs')) return 1;
    if (location.startsWith('/worker/applications')) return 2;
    if (location.startsWith('/worker/bookings')) return 3;
    if (location.startsWith('/worker/profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.workerDashboard);
        break;
      case 1:
        context.go(AppRoutes.workerJobFeed);
        break;
      case 2:
        context.go(AppRoutes.workerApplications);
        break;
      case 3:
        context.go(AppRoutes.workerBookings);
        break;
      case 4:
        context.go(AppRoutes.workerProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(context, index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
