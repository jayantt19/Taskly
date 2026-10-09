
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _tasksRef {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to manage your tasks.');
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks');
  }

  Stream<List<Task>> watchTasks() {
    return _tasksRef.snapshots().map((snapshot) {
      final tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        final dueDate = data['dueDate'];

        return Task(
          id: doc.id,
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          dueDate: dueDate is Timestamp
              ? dueDate.toDate()
              : DateTime.now(),
          priority: data['priority'] as String? ?? 'Medium',
          isCompleted: data['isCompleted'] as bool? ?? false,
        );
      }).toList();

      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  Future<void> addTask(Task task) async {
    await _tasksRef.add({
      'title': task.title,
      'description': task.description,
      'dueDate': Timestamp.fromDate(task.dueDate),
      'priority': task.priority,
      'isCompleted': task.isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask(Task task) async {
    await _tasksRef.doc(task.id).update({
      'title': task.title,
      'description': task.description,
      'dueDate': Timestamp.fromDate(task.dueDate),
      'priority': task.priority,
      'isCompleted': task.isCompleted,
    });
  }

  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
  }
}