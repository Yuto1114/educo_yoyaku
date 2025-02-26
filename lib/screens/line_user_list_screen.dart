import 'package:educo_yoyaku/models/line_user.dart';
import 'package:educo_yoyaku/repositories/line_user_repository.dart';
import 'package:educo_yoyaku/widgets/drawer.dart';
import 'package:educo_yoyaku/widgets/line_user_list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LineUserListScreen extends StatefulWidget {
  const LineUserListScreen({super.key});

  @override
  State<LineUserListScreen> createState() => _LineUserListPageState();
}

class _LineUserListPageState extends State<LineUserListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _repository = LineUserRepository();
  List<LineUser> lineUsers = [];
  String error = '';
  bool loading = false;

  void getAllUsers() async {
    try {
      setState(() => loading = true);
      lineUsers = await _repository.getAllUsers();
      error = '';
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    getAllUsers();
    super.initState();
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
          'お客様リスト',
          style: GoogleFonts.kiwiMaru(),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text('Error: $error'))
              : LineUserList(
                  users: lineUsers,
                  getAllUsers: _repository.getAllUsers,
                ),
      drawer: CustomDrawer(),
    );
  }
}
