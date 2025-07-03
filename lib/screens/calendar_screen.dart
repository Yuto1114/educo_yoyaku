import 'package:educo_yoyaku/repositories/line_user_repository.dart';
import 'package:educo_yoyaku/widgets/calendar.dart';
import 'package:educo_yoyaku/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:educo_yoyaku/repositories/classroom_repository.dart';
import 'package:educo_yoyaku/models/classroom.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ClassroomRepository _classroomRepository = ClassroomRepository();
  final LineUserRepository lineUserRepository = LineUserRepository();
  Classroom? selectedClassroom;

  @override
  void initState() {
    super.initState();
    _loadSelectedClassroomFromLocalStorage();
  }

  Future<void> _loadClassrooms() async {
    List<Classroom> classrooms = await _classroomRepository.getClassrooms();
    if (classrooms.isNotEmpty) {
      setState(() {
        selectedClassroom = classrooms.first;
      });
    }
  }

  // 教室選択を前回の履歴から復元
  Future<void> _loadSelectedClassroomFromLocalStorage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? classroomId = prefs.getString('selectedClassroomId');
    if (classroomId != null) {
      Classroom? classroom =
          await _classroomRepository.getClassroomById(classroomId);
      setState(() {
        selectedClassroom = classroom;
      });
    } else {
      _loadClassrooms();
    }
  }

  // 教室選択を履歴として保存
  Future<void> _saveSelectedClassroomToLocalStorage(Classroom classroom) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedClassroomId', classroom.classroomId);
  }

  void _showClassroomSelection() async {
    List<Classroom> classrooms = await _classroomRepository.getClassrooms();
    if (!mounted) return;
    showModalBottomSheet(
      backgroundColor: Colors.white, // 背景色を白に変更
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: ListView.builder(
            itemCount: classrooms.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(64),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    classrooms[index].classroomName,
                    style: GoogleFonts.kiwiMaru(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    setState(() {
                      selectedClassroom = classrooms[index];
                      if (selectedClassroom != null) {
                        _saveSelectedClassroomToLocalStorage(
                            selectedClassroom!);
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
          icon: Icon(Icons.menu),
          iconSize: 30,
        ),
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
              selectedClassroom?.classroomName ?? '読み込み中',
              style: GoogleFonts.zenMaruGothic(
                fontSize: 19,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (selectedClassroom != null)
                Calendar(
                  classroom: selectedClassroom!,
                  height: 600,
                  lineUserRepository: lineUserRepository,
                )
              else
                Text('教室を選択してください'),
            ],
          ),
        ),
      ),
    );
  }
}
