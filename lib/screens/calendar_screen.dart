import 'package:educo_yoyaku/repositories/line_user_repository.dart';
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
  final LineUserRepository lineUserRepository = LineUserRepository();
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
      backgroundColor: const Color.fromARGB(255, 255, 247, 243),
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: classrooms.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 247, 243),
                borderRadius: index == 0
                    ? BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      )
                    : BorderRadius.zero,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  classrooms[index].classroomName,
                  style: GoogleFonts.kiwiMaru(
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  setState(() {
                    _selectedClassroom = classrooms[index];
                  });
                  Navigator.pop(context);
                },
              ),
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
          'Educo',
          style: GoogleFonts.kiwiMaru(),
        ),
        actions: [
          OutlinedButton(
            style: ButtonStyle(
              side: WidgetStateProperty.all(
                BorderSide(color: Colors.deepOrangeAccent),
              ),
              padding: WidgetStateProperty.all(
                EdgeInsets.only(top: 6, bottom: 9, left: 11, right: 12),
              ),
              backgroundColor: WidgetStateProperty.all(Colors.deepOrangeAccent),
            ),
            onPressed: _showClassroomSelection,
            child: Text(
              _selectedClassroom?.classroomName ?? '選択してください',
              style: GoogleFonts.zenMaruGothic(
                fontSize: 19,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (_selectedClassroom != null)
                Calendar(
                  classroom: _selectedClassroom!,
                  height: 600,
                  lineUserRepository: lineUserRepository,
                )
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
