import 'package:educo_yoyaku/widgets/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:educo_yoyaku/repositories/classroom_repository.dart';
import 'package:educo_yoyaku/models/classroom.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _storage = const FlutterSecureStorage();
  final ClassroomRepository _classroomRepository = ClassroomRepository();
  Classroom? _selectedClassroom;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    List<Classroom> classrooms = await _classroomRepository.getClassrooms();
    if (classrooms.isNotEmpty) {
      setState(() {
        _selectedClassroom = classrooms.first;
      });
    }
  }

  void _showClassroomSelection() async {
    List<Classroom> classrooms = await _classroomRepository.getClassrooms();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: classrooms.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(classrooms[index].classroomName),
              onTap: () {
                setState(() {
                  _selectedClassroom = classrooms[index];
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    await _storage.write(key: 'isLoggedIn', value: 'false');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Educo カレンダー',
          style: GoogleFonts.kiwiMaru(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 10,
              ),
              Text(
                '教室選択',
                style: GoogleFonts.zenMaruGothic(
                    fontSize: 24, color: const Color.fromARGB(255, 71, 71, 71)),
              ),
              SizedBox(height: 0),
              OutlinedButton(
                onPressed: _showClassroomSelection,
                child: Text(
                  _selectedClassroom?.classroomName ?? '選択してください',
                  style: GoogleFonts.zenMaruGothic(
                    fontSize: 19,
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (_selectedClassroom != null)
                Calendar(classroom: _selectedClassroom!)
              else
                Text('教室を選択してください'),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: Text('ログアウト'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
