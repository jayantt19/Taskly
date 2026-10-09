
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import 'login_screen.dart';
import 'my_tasks_screen.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  Future<void> addTask() async {
    final task = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );

    if (task == null || !mounted) return;

    try {
      await _taskService.addTask(task);
    } catch (_) {
      showMessage('Could not save task.');
    }
  }

  Future<void> editTask(Task task) async {
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );

    if (updated == null || !mounted) return;

    try {
      await _taskService.updateTask(updated);
    } catch (_) {
      showMessage('Could not update task.');
    }
  }

  Future<void> toggleTask(Task task, bool completed) async {
    try {
      await _taskService.updateTask(
        Task(
          id: task.id,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate,
          priority: task.priority,
          isCompleted: completed,
        ),
      );
    } catch (_) {
      showMessage('Could not update task status.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void openMyTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyTasksScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Taskly',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Profile and menu',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'my_tasks') openMyTasks();
              if (value == 'logout') logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                child: SizedBox(
                  width: 190,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE5E7FF),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'My Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'my_tasks',
                child: Row(
                  children: [
                    Icon(Icons.checklist_rounded),
                    SizedBox(width: 10),
                    Text('My Tasks'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Log out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFFE5E7FF),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.indigo,
                ),
              ),
            ),
          ),
        ],
      ),

      body: StreamBuilder<List<Task>>(
        stream: _taskService.watchTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load tasks. Check your connection.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data ?? [];
          final pending = tasks.where((t) => !t.isCompleted).length;
          final completed = tasks.where((t) => t.isCompleted).length;

          // Show the three tasks with the nearest due dates.
          final recentTasks = [...tasks]
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final previewTasks = recentTasks.take(3).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Text(
                'Hello, ${email.split('@').first} 👋',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Let’s make today productive.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: summaryCard(
                      'Pending',
                      '$pending',
                      Icons.pending_actions,
                      const Color(0xFFFFF0D9),
                      Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: summaryCard(
                      'Completed',
                      '$completed',
                      Icons.task_alt,
                      const Color(0xFFE0F6E9),
                      Colors.green.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: openMyTasks,
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (previewTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 45,
                        color: Colors.indigo.shade200,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Tap + to create your first task.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              else
                ...previewTasks.map(
                  (task) => taskCard(task),
                ),
            ],
          );
        },
      ),

      // Round plus button fixed at the bottom center.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        tooltip: 'Add Task',
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget summaryCard(
    String title,
    String count,
    IconData icon,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
          Text(title, style: TextStyle(color: foreground)),
        ],
      ),
    );
  }

  Widget taskCard(Task task) {
    final priorityColor = switch (task.priority.toLowerCase()) {
      'high' => Colors.red,
      'medium' => Colors.orange.shade800,
      _ => Colors.green.shade700,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              if (value != null) toggleTask(task, value);
            },
            activeColor: Colors.indigo,
          ),
          Expanded(
            child: InkWell(
              onTap: () => editTask(task),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: priorityColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.priority,
              style: TextStyle(
                color: priorityColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => editTask(task),
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: 'Edit task',
          ),
        ],
      ),
    );
  }
}