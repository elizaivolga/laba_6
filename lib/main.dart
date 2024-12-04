import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'android_firebase_push_notification.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ReminderApp());
}

class ReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Напоминания',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ReminderListScreen(),
    );
  }
}

class ReminderListScreen extends StatefulWidget {

  @override
  _ReminderListScreenState createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  late Future<List<Reminder>> reminders;
  final AndroidFirebasePushNotification _notificationService = AndroidFirebasePushNotification();

  @override
  void initState() {
    super.initState();
    reminders = DatabaseHelper.instance.getReminders();
    _notificationService.init();
  }

  void _refreshReminders() {
    setState(() {
      reminders = DatabaseHelper.instance.getReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Напоминания')),
      body: FutureBuilder<List<Reminder>>(
        future: reminders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Нет напоминаний'));
          }

          final reminderList = snapshot.data!;
          return ListView.builder(
            itemCount: reminderList.length,
            itemBuilder: (context, index) {
              final reminder = reminderList[index];
              return ListTile(
                title: Text(reminder.title),
                subtitle: Text(formatDateTime(DateTime.parse(reminder.date))),
                onTap: () => _editReminder(context, reminder),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteReminder(context, reminder.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createReminder(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _createReminder(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReminderEditScreen()),
    );
    if (result == true) _refreshReminders();
  }

  Future<void> _editReminder(BuildContext context, Reminder reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderEditScreen(reminder: reminder),
      ),
    );
    if (result == true) _refreshReminders();
  }

  Future<void> _deleteReminder(BuildContext context, int id) async {
    await DatabaseHelper.instance.deleteReminder(id);
    _refreshReminders();
  }
}

String formatDateTime(DateTime dateTime) {
  final dateFormatter = DateFormat('HH:mm dd.MM.yyyy');
  return dateFormatter.format(dateTime);
}

class ReminderEditScreen extends StatefulWidget {
  final Reminder? reminder;

  ReminderEditScreen({this.reminder});

  @override
  _ReminderEditScreenState createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description;
      _selectedDateTime = DateTime.parse(widget.reminder!.date);
    }
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Новое напоминание' : 'Редактировать'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Заголовок'),
                validator: (value) => value!.isEmpty ? 'Введите заголовок' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Текст уведомления'),
                validator: (value) => value!.isEmpty ? 'Введите текст' : null,
              ),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateTime == null
                          ? 'Выберите дату и время'
                          : 'Выбрано: ${formatDateTime(_selectedDateTime!)}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickDateTime(context),
                    child: Text('Выбрать'),
                  ),
                ],
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _selectedDateTime != null) {
                    final newReminder = Reminder(
                      id: widget.reminder?.id,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      date: _selectedDateTime!.toIso8601String(),
                    );
                    if (widget.reminder == null) {
                      await DatabaseHelper.instance.insertReminder(newReminder);
                    } else {
                      await DatabaseHelper.instance.updateReminder(newReminder);
                    }
                    Navigator.pop(context, true);
                  }
                },
                child: Text(widget.reminder == null ? 'Создать' : 'Сохранить'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
