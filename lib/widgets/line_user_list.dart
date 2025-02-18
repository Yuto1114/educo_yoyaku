import 'package:educo_yoyaku/models/line_user.dart';
import 'package:educo_yoyaku/screens/line_user_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LineUserList extends StatefulWidget {
  final List<LineUser> users;
  final Future<List<LineUser>> Function() getAllUsers;
  const LineUserList(
      {super.key, required this.users, required this.getAllUsers});

  @override
  State<LineUserList> createState() => _LineUserListState();
}

class _LineUserListState extends State<LineUserList> {
  late List<LineUser> users;

  @override
  void initState() {
    super.initState();
    users = widget.users;
  }

  Future<void> refreshUserData() async {
    final newUsers = await widget.getAllUsers();
    setState(() {
      users = newUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: RefreshIndicator(
        onRefresh: refreshUserData,
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (BuildContext context, int index) {
            final LineUser user = users[index];
            return ListTile(
              minTileHeight: 70,
              leading: CircleAvatar(
                radius: 23,
                backgroundImage: NetworkImage(user.pictureUrl),
              ),
              tileColor: index % 2 == 0 ? Colors.white : Colors.grey[300],
              title: Text(
                user.displayName,
                style: GoogleFonts.notoSansJp(),
              ),
              subtitle: user.course.isNotEmpty
                  ? Text(user.course, style: GoogleFonts.zenMaruGothic())
                  : Text('コース未設定',
                      style: GoogleFonts.zenMaruGothic(
                          color: Color.fromARGB(255, 100, 100, 100))),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LineUserDetailScreen(user: user),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
