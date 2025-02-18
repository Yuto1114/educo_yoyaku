import 'package:educo_yoyaku/models/line_user.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LineUserDetailScreen extends StatelessWidget {
  const LineUserDetailScreen({super.key, required this.user});
  final LineUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${user.displayName}さん',
          style: GoogleFonts.kiwiMaru(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              color: Theme.of(context).secondaryHeaderColor,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user.pictureUrl),
                    ),
                    SizedBox(
                      width: 25,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.displayName,
                            style: GoogleFonts.zenMaruGothic(fontSize: 30),
                          ),
                          SizedBox(height: 2),
                          user.course.isNotEmpty
                              ? Text(user.course)
                              : TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {},
                                  child: Text(
                                    'タップしてコースを設定',
                                    style: GoogleFonts.zenMaruGothic(),
                                  ))
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
