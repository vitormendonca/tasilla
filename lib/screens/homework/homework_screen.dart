import 'package:flutter/material.dart';

import '../../data/homework_data.dart';
import '../../models/homework_activity.dart';
import '../../services/student_progress_service.dart';
import 'homework_activity_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  Map<String, int> activityScores = {};
  Map<String, bool> completedActivities = {};

  @override
  void initState() {
    super.initState();
    loadHomeworkResults();
  }

  Future<void> loadHomeworkResults() async {
    final Map<String, int> loadedScores = {};
    final Map<String, bool> loadedCompleted = {};

    for (final activity in homeworkActivities) {
      final score = await StudentProgressService.getActivityScore(
        activityId: activity.id,
        category: 'homework',
      );

      final isCompleted = await StudentProgressService.isActivityCompleted(
        activityId: activity.id,
        category: 'homework',
      );

      loadedScores[activity.id] = score ?? -1;
      loadedCompleted[activity.id] = isCompleted;
    }

    if (!mounted) return;

    setState(() {
      activityScores = loadedScores;
      completedActivities = loadedCompleted;
    });
  }

  Future<void> openActivity(
    BuildContext context,
    HomeworkActivity activity,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkActivityScreen(activity: activity),
      ),
    );

    await loadHomeworkResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Homework Support'),
        backgroundColor: const Color(0xFFB00020),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Homework Support',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Complete extra practice assigned by your teacher and track your results.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),

          const SizedBox(height: 24),

          for (final activity in homeworkActivities)
            _homeworkActivityCard(
              activity: activity,
              onTap: () => openActivity(context, activity),
            ),
        ],
      ),
    );
  }

  Widget _homeworkActivityCard({
    required HomeworkActivity activity,
    required VoidCallback onTap,
  }) {
    final int score = activityScores[activity.id] ?? -1;
    final bool isCompleted = completedActivities[activity.id] ?? false;
    final bool hasResult = score >= 0;

    String statusText = 'Not started';
    Color statusColor = Colors.white38;
    IconData statusIcon = Icons.radio_button_unchecked;

    if (hasResult) {
      if (isCompleted) {
        statusText = 'Completed • Accuracy: $score%';
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
      } else {
        statusText = 'Review Needed • Accuracy: $score%';
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.info;
      }
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFB00020).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : hasResult
                      ? Icons.info
                      : Icons.assignment,
                  color: isCompleted
                      ? Colors.greenAccent
                      : hasResult
                      ? Colors.orangeAccent
                      : const Color(0xFFB00020),
                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      activity.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB00020),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activity.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
