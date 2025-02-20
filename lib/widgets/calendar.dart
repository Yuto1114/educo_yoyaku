import 'package:educo_yoyaku/models/line_user.dart';
import 'package:educo_yoyaku/models/reservation.dart';
import 'package:educo_yoyaku/repositories/line_user_repository.dart';
import 'package:educo_yoyaku/repositories/classroom_repository.dart'; // 追加
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:educo_yoyaku/models/classroom.dart';
import 'package:educo_yoyaku/repositories/reservation_repository.dart';

class Calendar extends StatelessWidget {
  final Classroom classroom;
  final double? height; // カレンダーの高さ
  final LineUserRepository lineUserRepository;

  const Calendar({
    super.key,
    required this.classroom,
    this.height,
    required this.lineUserRepository,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: _getBookings(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No bookings available'));
        } else {
          return SizedBox(
            height: height ??
                MediaQuery.of(context).size.height *
                    0.8, // heightが指定されていない場合は画面の80%を使用
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: SfCalendar(
                      view: CalendarView.month,
                      headerDateFormat: 'yyyy年M月',
                      showNavigationArrow: true,
                      headerStyle: CalendarHeaderStyle(
                        textAlign: TextAlign.center,
                        textStyle: GoogleFonts.kiwiMaru(),
                        backgroundColor: Theme.of(context).secondaryHeaderColor,
                      ),
                      dataSource: BookingDataSource(snapshot.data!),
                      monthViewSettings: MonthViewSettings(
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment,
                      ),
                      appointmentBuilder: (context, details) {
                        final Booking booking = details.appointments.first;
                        return Container(
                          width: details.bounds.width,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: booking.background,
                          ),
                          child: Center(
                            child: Text(
                              booking.eventName,
                              style: TextStyle(
                                color: const Color.fromARGB(255, 255, 129, 129),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      onTap: (calendarTapDetails) async {
                        if (calendarTapDetails.targetElement ==
                            CalendarElement.calendarCell) {
                          final reservations = await _getReservationsByDate(
                              calendarTapDetails.date!);
                          if (!context.mounted) return;
                          _showReservationsModal(
                              context, calendarTapDetails.date!, reservations);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<List<Booking>> _getBookings(BuildContext context) async {
    final reservationRepository = ReservationRepository();
    final reservations = await reservationRepository.getAllReservations();

    // 日付ごとに予約を集計
    final Map<DateTime, int> bookingCounts = {};
    for (var reservation in reservations) {
      final date = DateTime(reservation.startTime.year,
          reservation.startTime.month, reservation.startTime.day);
      if (bookingCounts.containsKey(date)) {
        bookingCounts[date] = bookingCounts[date]! + 1;
      } else {
        bookingCounts[date] = 1;
      }
    }

    // 集計結果からBookingを作成
    final List<Booking> bookings = [];
    bookingCounts.forEach((date, count) {
      if (count > 0) {
        final booking = Booking(
          '$count件',
          date,
          date.add(Duration(hours: 23, minutes: 59, seconds: 59)),
          Theme.of(context).secondaryHeaderColor,
          true,
        );
        bookings.add(booking);
      }
    });

    return bookings;
  }

  Future<List<Reservation>> _getReservationsByDate(DateTime date) async {
    final reservationRepository = ReservationRepository();
    return await reservationRepository.getReservationsByDate(date);
  }

  void _showReservationsModal(BuildContext context, DateTime date,
      List<Reservation> reservations) async {
    final List<LineUser> lineUsers = [];
    final List<String> classroomNames = [];
    final classroomRepository = ClassroomRepository();

    for (var reservation in reservations) {
      final lineUser = await lineUserRepository.getUser(reservation.userId);
      if (lineUser != null) {
        lineUsers.add(lineUser);
      }

      final classroom =
          await classroomRepository.getClassroomById(reservation.classroomId);
      if (classroom != null) {
        classroomNames.add(classroom.classroomName);
      } else {
        classroomNames.add('Unknown Classroom');
      }
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.year}年${date.month}月${date.day}日の予約',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (reservations.isEmpty)
                  Text('予約はありません')
                else
                  ...reservations.asMap().entries.map(
                    (entry) {
                      final lineUser = lineUsers[entry.key];
                      return ListTile(
                        title: Text('ユーザー名: ${lineUser.displayName}'),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BookingDataSource extends CalendarDataSource {
  BookingDataSource(List<Booking> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}

class Booking {
  Booking(this.eventName, this.from, this.to, this.background, this.isAllDay);

  final String eventName;
  final DateTime from;
  final DateTime to;
  final Color background;
  final bool isAllDay;

  @override
  String toString() {
    return 'Booking(eventName: $eventName, from: $from, to: $to, background: $background, isAllDay: $isAllDay)';
  }
}
