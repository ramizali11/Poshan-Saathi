import 'package:flutter/material.dart';
import 'package:frontend/core/services/child_session.dart';
import 'package:frontend/core/widgets/app_bottom_nav.dart';
import 'parent_dashboard_screen.dart';
import 'meal_planner_screen.dart';
import 'growth_monitoring_screen.dart';
import 'ai_assistant_screen.dart';
import 'reminders_screen.dart';

class ParentMainScaffold extends StatefulWidget {
  final int initialIndex;

  const ParentMainScaffold({super.key, this.initialIndex = 0});

  @override
  State<ParentMainScaffold> createState() => _ParentMainScaffoldState();
}

class _ParentMainScaffoldState extends State<ParentMainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    ChildSession.instance.loadChildren();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ParentDashboardScreen(
        onNavigateToMeals: () => setState(() => _currentIndex = 1),
        onNavigateToGrowth: () => setState(() => _currentIndex = 2),
        onNavigateToAI: () => setState(() => _currentIndex = 3),
      ),
      const MealPlannerScreen(),
      const GrowthMonitoringScreen(),
      const AiAssistantScreen(),
      const RemindersScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        sizing: StackFit.expand,
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
