import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({
    super.key,
    this.task,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime? selectedDate;
  String selectedPriority = 'Medium';

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      titleController.text = widget.task!.title;
      descriptionController.text = widget.task!.description;
      selectedDate = widget.task!.dueDate;
      selectedPriority = widget.task!.priority;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void saveTask() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      showMessage('Please enter a task title');
      return;
    }

    if (selectedDate == null) {
      showMessage('Please select a due date');
      return;
    }

    final task = Task(
      id: widget.task?.id ?? '',
      title: title,
      description: description,
      dueDate: selectedDate!,
      priority: selectedPriority,
      isCompleted: widget.task?.isCompleted ?? false,
    );

    Navigator.pop(context, task);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Task' : 'Add Task',
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? 'Update your task'
                        : 'Create a new task',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isEditing
                        ? 'Make changes to your task details.'
                        : 'Add the details of the work you need to complete.',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Title',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: titleController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'e.g. Deliver package',
                      prefixIcon: const Icon(
                        Icons.task_alt_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe what needs to be done...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Due Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap: selectDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedDate == null
                                ? 'Select due date'
                                : '${selectedDate!.day}/'
                                    '${selectedDate!.month}/'
                                    '${selectedDate!.year}',
                            style: TextStyle(
                              color: selectedDate == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Priority',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.flag_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Low',
                        child: Text('Low'),
                      ),
                      DropdownMenuItem(
                        value: 'Medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'High',
                        child: Text('High'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedPriority = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: saveTask,
                      icon: Icon(
                        isEditing
                            ? Icons.save_outlined
                            : Icons.add,
                      ),
                      label: Text(
                        isEditing ? 'Update Task' : 'Save Task',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}