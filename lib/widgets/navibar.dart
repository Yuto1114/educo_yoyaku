import 'package:educo_yoyaku/screens/attendance_screen.dart';
import 'package:educo_yoyaku/screens/home_screen.dart';
import 'package:educo_yoyaku/screens/line_user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Navibar extends StatefulWidget {
  const Navibar({super.key});

  @override
  State<Navibar> createState() => _NavibarState();
}

class _NavibarState extends State<Navibar> {
  static const _screens = [
    HomeScreen(),
    AttendanceScreen(),
    LineUserListScreen(),
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory, // 波紋エフェクトを無効にする
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'カレンダー'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '出席簿'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'アカウント'),
          ],
          selectedLabelStyle: GoogleFonts.kiwiMaru(),
          unselectedLabelStyle: GoogleFonts.kiwiMaru(),
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
