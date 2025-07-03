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
    final Map<String, List<Map<String, dynamic>>> groupedReservations = {};
    final classroomRepository = ClassroomRepository();

    // 予約を開始時間でグループ化
    for (var reservation in reservations) {
      final lineUser =
          await widget.lineUserRepository.getUser(reservation.userId);
      final classroom =
          await classroomRepository.getClassroomById(reservation.classroomId);
      final classroomName = classroom?.classroomName ?? 'Unknown Classroom';

      // 時間のフォーマット (HH:MM形式)
      final timeKey =
          '${reservation.startTime.hour.toString().padLeft(2, '0')}:${reservation.startTime.minute.toString().padLeft(2, '0')}';

      if (!groupedReservations.containsKey(timeKey)) {
        groupedReservations[timeKey] = [];
      }

      groupedReservations[timeKey]!.add({
        'reservation': reservation,
        'lineUser': lineUser,
        'classroomName': classroomName,
      });
    }

    // 時間でソート
    final sortedTimes = groupedReservations.keys.toList()..sort();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // モーダルの高さを内容に合わせる
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.8, // 画面の80%の高さで表示に変更
          minChildSize: 0.4, // 最小サイズも40%に拡大
          maxChildSize: 0.95, // 最大サイズは95%
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ドラッグハンドル
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // タイトル
                  Text(
                    '${date.year}年${date.month}月${date.day}日の予約',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 予約リスト
                  Expanded(
                    child: reservations.isEmpty
                        ? const Center(child: Text('予約はありません'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: sortedTimes.length,
                            itemBuilder: (context, timeIndex) {
                              final timeKey = sortedTimes[timeIndex];
                              final reservationsAtTime =
                                  groupedReservations[timeKey]!;

                              // コースごとのグループ化
                              final Map<String, List<Map<String, dynamic>>>
                                  courseGroups = {};
                              for (var item in reservationsAtTime) {
                                final courseName =
                                    (item['reservation'] as Reservation)
                                        .courseName;
                                if (!courseGroups.containsKey(courseName)) {
                                  courseGroups[courseName] = [];
                                }
                                courseGroups[courseName]!.add(item);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 時間ヘッダー
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    margin: const EdgeInsets.only(
                                        bottom: 8, top: 16),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: theme.primaryColor
                                              .withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 18,
                                            color: theme.primaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeKey,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // コースごとのグループ
                                  ...courseGroups.entries.map((courseEntry) {
                                    final courseName = courseEntry.key;
                                    final courseItems = courseEntry.value;
                                    // より鮮明な色分けを実装
                                    final courseColor =
                                        _getCourseColor(courseName);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: courseColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: courseColor.withOpacity(0.7),
                                            width: 1.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // コース名ヘッダー
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Icon(Icons.school,
                                                    color: theme.primaryColor),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    courseName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // 予約者リスト（名前のみの簡素化バージョン）
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: courseItems.map((item) {
                                                final lineUser =
                                                    item['lineUser']
                                                        as LineUser?;

                                                if (lineUser == null) {
                                                  return const Chip(
                                                    label: Text('不明なユーザー'),
                                                    backgroundColor:
                                                        Colors.white70,
                                                  );
                                                }

                                                return Chip(
                                                  label: Text(
                                                    lineUser.displayName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.white
                                                      .withOpacity(0.9),
                                                  side: BorderSide(
                                                    color: courseColor
                                                        .withOpacity(0.5),
                                                    width: 1,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    isShowingMordal = false;
  }

  // コースごとの色を生成するメソッドを更新
  Color _getCourseColor(String courseName) {
    // 定義済みの色のリスト
    final List<Color> courseColors = [
      Color(0xFFF8BBD0), // ピンク
      Color(0xFFBBDEFB), // 水色
      Color(0xFFC8E6C9), // 緑
      Color(0xFFFFE0B2), // オレンジ
      Color(0xFFE1BEE7), // 紫
      Color(0xFFFFCCBC), // サーモンピンク
      Color(0xFFCFD8DC), // グレー
      Color(0xFFFFECB3), // 黄色
      Color(0xFFD7CCC8), // 茶色
      Color(0xFFB3E5FC), // 明るい青
    ];

    // コース名のハッシュ値から色を選択
    final hash = courseName.hashCode.abs();
    return courseColors[hash % courseColors.length];
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
