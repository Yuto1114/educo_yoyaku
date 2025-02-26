import 'package:educo_yoyaku/models/line_user.dart';
import 'package:educo_yoyaku/models/reservation.dart';
import 'package:educo_yoyaku/repositories/line_user_repository.dart';
import 'package:educo_yoyaku/repositories/classroom_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:educo_yoyaku/models/classroom.dart';
import 'package:educo_yoyaku/repositories/reservation_repository.dart';

class Calendar extends StatefulWidget {
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
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  bool isShowingMordal = false;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: _getBookings(context, widget.classroom),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return SizedBox(
            height: widget.height ??
                MediaQuery.of(context).size.height *
                    0.8, // heightが指定されていない場合は画面の80%を使用
            width: MediaQuery.of(context).size.width * 0.95,
            child: Padding(
              padding: const EdgeInsets.all(0),
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
                                CalendarElement.calendarCell &&
                            isShowingMordal == false) {
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

  Future<List<Booking>> _getBookings(
      BuildContext context, Classroom classroom) async {
    final reservationRepository = ReservationRepository();
    final reservations =
        await reservationRepository.getAllReservations(classroom);

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
    bookingCounts.forEach(
      (date, count) {
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
      },
    );

    return bookings;
  }

  Future<List<Reservation>> _getReservationsByDate(DateTime date) async {
    final reservationRepository = ReservationRepository();
    return await reservationRepository.getReservationsByDate(date);
  }

  void _showReservationsModal(BuildContext context, DateTime date,
      List<Reservation> reservations) async {
    isShowingMordal = true;
    final List<LineUser> lineUsers = [];
    final classroomRepository = ClassroomRepository();
    final classroom = await classroomRepository
        .getClassroomWithSlotsById(widget.classroom.classroomId);

    for (var reservation in reservations) {
      final lineUser =
          await widget.lineUserRepository.getUser(reservation.userId);
      if (lineUser != null) {
        lineUsers.add(lineUser);
      }
    }

    // 予約を開始時間でグループ化
    final Map<DateTime, Map<String, List<int>>> groupedReservations = {};
    for (var i = 0; i < reservations.length; i++) {
      final startTime = DateTime(
        reservations[i].startTime.year,
        reservations[i].startTime.month,
        reservations[i].startTime.day,
        reservations[i].startTime.hour,
        reservations[i].startTime.minute,
      );
      final courseName = reservations[i].courseName;

      if (groupedReservations.containsKey(startTime)) {
        if (groupedReservations[startTime]!.containsKey(courseName)) {
          groupedReservations[startTime]![courseName]!.add(i);
        } else {
          groupedReservations[startTime]![courseName] = [i];
        }
      } else {
        groupedReservations[startTime] = {
          courseName: [i]
        };
      }
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width,
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
                  Column(
                    children: [
                      Text('予約はありません'),
                      SizedBox(height: 35),
                    ],
                  )
                else
                  Column(
                    children: groupedReservations.entries.map(
                      (entry) {
                        final startTime = entry.key;
                        final courseGroups = entry.value;
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ...courseGroups.entries.map(
                                (courseEntry) {
                                  final courseName = courseEntry.key;
                                  final indices = courseEntry.value;
                                  Color courseColor;
                                  switch (courseName) {
                                    case 'ロボット':
                                      courseColor = Colors.red;
                                      break;
                                    case 'サイエンス':
                                      courseColor = Colors.green;
                                      break;
                                    case 'こどプロ':
                                      courseColor = Colors.blue;
                                      break;
                                    default:
                                      courseColor = Colors.grey;
                                  }
                                  return Container(
                                    margin: EdgeInsets.only(top: 8),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: courseColor.withAlpha(51),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              courseName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: courseColor,
                                              ),
                                            ),
                                            Text(
                                              '${indices.length}/${classroom?.slots.firstWhere((slot) => slot.slotId == reservations[indices.first].slotId).capacity ?? 8}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: courseColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: indices.map(
                                              (index) {
                                                final lineUser =
                                                    lineUsers[index];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4.0, right: 8.0),
                                                  child: Text(
                                                    lineUser.displayName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  ),
                SizedBox(
                  height: 50,
                ),
              ],
            ),
          ),
        );
      },
    );
    isShowingMordal = false;
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
