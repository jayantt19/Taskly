import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'task_form_screen.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final TaskService _taskService = TaskService();
  final ScrollController _scrollController = ScrollController();

  String priorityFilter = 'All';
  String statusFilter = 'All';

  static const Color primary = Color(0xFF4F46E5);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime weekStart(DateTime date) {
    final current = day(date);
    return current.subtract(Duration(days: current.weekday - 1));
  }

  String dateLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${days[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]}';
  }

  String monthLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  void message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> addTask() async {
    final task = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );

    if (task == null || !mounted) return;

    try {
      await _taskService.addTask(task);
    } catch (_) {
      message('Could not save task.');
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
      message('Could not update task.');
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id);
      message('Task deleted.');
    } catch (_) {
      message('Could not delete task.');
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
      message('Could not update task status.');
    }
  }

  List<Task> filteredTasks(List<Task> tasks) {
    return tasks.where((task) {
      final priorityMatches = priorityFilter == 'All' ||
          task.priority.toLowerCase() == priorityFilter.toLowerCase();

      final statusMatches = statusFilter == 'All' ||
          (statusFilter == 'Pending' && !task.isCompleted) ||
          (statusFilter == 'Completed' && task.isCompleted);

      return priorityMatches && statusMatches;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Tasks',
          style: TextStyle(
            color: textDark,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _taskService.watchTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load tasks.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primary),
            );
          }

          final tasks = filteredTasks(snapshot.data ?? []);
          final today = day(DateTime.now());
          final tomorrow = today.add(const Duration(days: 1));
          final endOfWeek = weekStart(today).add(
            const Duration(days: 6),
          );

          final overdue = tasks.where((task) =>
              day(task.dueDate).isBefore(today) &&
              !task.isCompleted).toList();

          final todayTasks = tasks.where(
            (task) => day(task.dueDate) == today,
          ).toList();

          final tomorrowTasks = tasks.where(
            (task) => day(task.dueDate) == tomorrow,
          ).toList();

          final thisWeekTasks = tasks.where((task) {
            final date = day(task.dueDate);
            return date.isAfter(tomorrow) &&
                !date.isAfter(endOfWeek);
          }).toList();

          final laterTasks = tasks.where(
            (task) => day(task.dueDate).isAfter(endOfWeek),
          ).toList();

          final grouped = <String, List<Task>>{};

          for (final task in laterTasks) {
            grouped.putIfAbsent(
              monthLabel(task.dueDate),
              () => [],
            ).add(task);
          }

          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: false,
            trackVisibility: false,
            thickness: 4,
            radius: const Radius.circular(10),
            interactive: true,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                const Text(
                  'Everything you need to get done, in one place.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),

                // Filters
                Row(
                  children: [
                    Expanded(
                      child: dropdown(
                        'Priority',
                        priorityFilter,
                        const ['All', 'Low', 'Medium', 'High'],
                        (value) => setState(() {
                          priorityFilter = value;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: dropdown(
                        'Status',
                        statusFilter,
                        const ['All', 'Pending', 'Completed'],
                        (value) => setState(() {
                          statusFilter = value;
                        }),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                if (tasks.isEmpty)
                  emptyState()
                else ...[
                  section('Overdue', overdue, color: const Color(0xFFDC2626)),
                  section('Today', todayTasks),
                  section('Tomorrow', tomorrowTasks),
                  section('This Week', thisWeekTasks),
                  for (final entry in grouped.entries)
                    section(entry.key, entry.value),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        tooltip: 'Add Task',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }

  Widget dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: textMuted,
      ),
      style: const TextStyle(
        color: textDark,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: textMuted,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tasks found',
            style: TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing your filters or tap + to create a new task.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget section(
    String title,
    List<Task> tasks, {
    Color? color,
  }) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color ?? textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color == null
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    color: color ?? primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tasks.map(taskCard),
        ],
      ),
    );
  }

  Widget taskCard(Task task) {
    final priority = task.priority.toLowerCase();

    final Color priorityColor;
    final Color priorityBackground;

    switch (priority) {
      case 'high':
        priorityColor = const Color(0xFFDC2626);
        priorityBackground = const Color(0xFFFEE2E2);
        break;
      case 'medium':
        priorityColor = const Color(0xFFB45309);
        priorityBackground = const Color(0xFFFEF3C7);
        break;
      default:
        priorityColor = const Color(0xFF15803D);
        priorityBackground = const Color(0xFFDCFCE7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 13,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isCompleted,
              activeColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (value) {
                if (value != null) toggleTask(task, value);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => editTask(task),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted
                              ? textMuted
                              : textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (task.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                dateLabel(task.dueDate),
                                style: const TextStyle(
                                  color: textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: priorityBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              task.priority,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Task options',
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: textMuted,
              ),
              onSelected: (value) {
                if (value == 'edit') editTask(task);
                if (value == 'delete') confirmDelete(task);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 19),
                      SizedBox(width: 10),
                      Text('Edit task'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text('Delete task'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await deleteTask(task);
    }
  }
}
