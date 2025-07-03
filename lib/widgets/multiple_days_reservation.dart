import 'package:flutter/material.dart';
import 'package:educo_yoyaku/models/classroom.dart';
import 'package:educo_yoyaku/models/course.dart';
import 'package:educo_yoyaku/repositories/classroom_repository.dart';
import 'package:educo_yoyaku/repositories/course_repository.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:day_night_time_picker/day_night_time_picker.dart';

class MultipleDaysReservation extends StatefulWidget {
  const MultipleDaysReservation({super.key});

  @override
  State<MultipleDaysReservation> createState() =>
      _MultipleDaysReservationState();
}

class _MultipleDaysReservationState extends State<MultipleDaysReservation> {
  final ClassroomRepository _classroomRepository = ClassroomRepository();
  final CourseRepository _courseRepository = CourseRepository();

  // フォームのキー
  final _formKey = GlobalKey<FormState>();

  // 選択された教室
  String? _selectedClassroomId;

  // 日付範囲
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // 除外日リスト
  final List<DateTime> _excludeDates = [];

  // 教室リストとコースリスト
  List<Classroom> _classrooms = [];
  List<Course> _courses = [];

  // 曜日ごとの予定リスト
  final Map<int, List<ScheduleSlot>> _daySchedules = {
    0: [], // 日曜日
    1: [], // 月曜日
    2: [], // 火曜日
    3: [], // 水曜日
    4: [], // 木曜日
    5: [], // 金曜日
    6: [], // 土曜日
  };

  // 現在選択されている曜日
  int _selectedDayOfWeek = 0;

  // ローディング状態
  bool _isLoading = true;
  bool _isSending = false;

  // 結果メッセージ
  String? _resultMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 教室とコースデータを読み込む
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 並列で両方のデータを取得
      final classroomsFuture = _classroomRepository.getClassrooms();
      final coursesFuture = _courseRepository.getCourses();

      final results = await Future.wait([classroomsFuture, coursesFuture]);

      setState(() {
        _classrooms = results[0] as List<Classroom>;
        _courses = results[1] as List<Course>;
        _isLoading = false;

        // デフォルト値の設定
        if (_classrooms.isNotEmpty) {
          _selectedClassroomId = _classrooms.first.classroomId;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = 'データ取得エラー: $e';
        _isSuccess = false;
      });
    }
  }

  // 予定スロットを追加
  void _addScheduleSlot(int dayOfWeek) {
    final defaultCourseId = _courses.isNotEmpty ? _courses.first.courseId : '';

    setState(() {
      _daySchedules[dayOfWeek]!.add(ScheduleSlot(
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 30),
        courseId: defaultCourseId,
        capacity: 4,
      ));
    });
  }

  // 予定スロットを削除
  void _removeScheduleSlot(int dayOfWeek, int index) {
    setState(() {
      _daySchedules[dayOfWeek]!.removeAt(index);
    });
  }

  // 除外日の追加
  void _addExcludeDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ja', 'JP'),
    );

    if (picked != null) {
      // 日付の時間部分をリセットして、日付のみで比較できるようにする
      final dateOnly = DateTime(picked.year, picked.month, picked.day);

      // 既に同じ日付が存在するかチェック
      final exists = _excludeDates.any((date) =>
          date.year == dateOnly.year &&
          date.month == dateOnly.month &&
          date.day == dateOnly.day);

      if (!exists) {
        setState(() {
          _excludeDates.add(dateOnly);
        });
      }
    }
  }

  // 除外日の削除
  void _removeExcludeDate(int index) {
    setState(() {
      _excludeDates.removeAt(index);
    });
  }

  // APIでパターン予約を作成
  Future<void> _createPatternSlots() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _resultMessage = null;
    });

    try {
      // 各曜日のパターンデータを準備
      final List<Map<String, dynamic>> patterns = [];

      // 全ての曜日をチェック
      for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
        // その曜日の予定スロットをパターンに変換
        for (var slot in _daySchedules[dayOfWeek]!) {
          patterns.add({
            'dayOfWeek': dayOfWeek,
            'startTime':
                '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}',
            'endTime':
                '${slot.endTime.hour.toString().padLeft(2, '0')}:${slot.endTime.minute.toString().padLeft(2, '0')}',
            'courseId': slot.courseId,
            'capacity': slot.capacity,
          });
        }
      }

      // パターンが空の場合はエラーを表示
      if (patterns.isEmpty) {
        setState(() {
          _resultMessage = 'エラー: 少なくとも1つの予定を追加してください';
          _isSuccess = false;
          _isSending = false;
        });
        return;
      }

      // 除外日の準備 (yyyy-MM-dd形式)
      final List<String> excludeDateStrings = _excludeDates.map((date) {
        return DateFormat('yyyy-MM-dd').format(date);
      }).toList();

      // リクエストデータの作成
      final Map<String, dynamic> requestData = {
        'classroomId': _selectedClassroomId,
        'dateRange': {
          'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
          'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
        },
        'weeklyPattern': patterns,
        'excludeDates': excludeDateStrings,
      };

      // APIリクエスト送信
      final response = await http.post(
        Uri.parse(
            'https://k1abrrebtl.execute-api.ap-northeast-1.amazonaws.com/pattern-slots'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _resultMessage = 'パターン予約が正常に作成されました！';
          _isSuccess = true;
          _isSending = false;
        });
      } else {
        setState(() {
          _resultMessage = 'エラー: ${response.statusCode} - ${response.body}';
          _isSuccess = false;
          _isSending = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '送信エラー: $e';
        _isSuccess = false;
        _isSending = false;
      });
    }
  }

// day_night_time_pickerを使用した時間選択メソッド（シンプル化バージョン）
  void _showTimePicker(
      BuildContext context, ScheduleSlot slot, bool isStartTime) {
    Navigator.of(context).push(
      showPicker(
        context: context,
        value: Time(
            hour: (isStartTime ? slot.startTime : slot.endTime).hour,
            minute: (isStartTime ? slot.startTime : slot.endTime).minute),
        onChange: (Time newTime) {
          setState(() {
            final selectedTime =
                TimeOfDay(hour: newTime.hour, minute: newTime.minute);

            if (isStartTime) {
              slot.startTime = selectedTime;

              // 終了時間が開始時間より前の場合、開始時間+90分に自動調整
              final startInMinutes =
                  slot.startTime.hour * 60 + slot.startTime.minute;
              final endInMinutes = slot.endTime.hour * 60 + slot.endTime.minute;

              if (endInMinutes <= startInMinutes) {
                // 終了時間を開始時間の90分後に設定
                int newEndMinutes = startInMinutes + 90;
                slot.endTime = TimeOfDay(
                    hour: (newEndMinutes ~/ 60) % 24,
                    minute: newEndMinutes % 60);
              }
            } else {
              // 終了時間設定時
              final startInMinutes =
                  slot.startTime.hour * 60 + slot.startTime.minute;
              final newEndMinutes =
                  selectedTime.hour * 60 + selectedTime.minute;

              if (newEndMinutes <= startInMinutes) {
                // 選択された終了時間が開始時間より前/同じ場合は、強制的に開始時間+30分に変更
                int adjustedEndMinutes = startInMinutes + 30;
                slot.endTime = TimeOfDay(
                    hour: (adjustedEndMinutes ~/ 60) % 24,
                    minute: adjustedEndMinutes % 60);
              } else {
                slot.endTime = selectedTime;
              }
            }
          });
        },
        accentColor: Theme.of(context).primaryColor,
        iosStylePicker: true, // より簡素なiOS風インターフェースを使用
        displayHeader: false, // ヘッダー表示をオフに
        hourLabel: "時",
        minuteLabel: "分",
        is24HrFormat: true,
        barrierDismissible: true, // バックグラウンドタップでキャンセル可能に
        okText: "決定",
        cancelText: "キャンセル",
        minuteInterval: TimePickerInterval.FIVE, // 5分単位で選択可能に
        borderRadius: 12,
        elevation: 4,
        themeData: ThemeData(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        dialogInsetPadding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      ),
    );
  }

// よく使う時間枠の選択メソッド
  void _showTimeRangePicker(BuildContext context, ScheduleSlot slot) {
    // よく使う時間枠
    final List<Map<String, dynamic>> presetTimes = [
      {
        'name': '90分授業 (標準)',
        'start': const TimeOfDay(hour: 10, minute: 0),
        'end': const TimeOfDay(hour: 11, minute: 30),
      },
      {
        'name': '午前授業',
        'start': const TimeOfDay(hour: 9, minute: 0),
        'end': const TimeOfDay(hour: 12, minute: 0),
      },
      {
        'name': '午後授業',
        'start': const TimeOfDay(hour: 13, minute: 0),
        'end': const TimeOfDay(hour: 15, minute: 0),
      },
      {
        'name': '放課後授業',
        'start': const TimeOfDay(hour: 16, minute: 0),
        'end': const TimeOfDay(hour: 17, minute: 30),
      },
      {
        'name': '夕方授業',
        'start': const TimeOfDay(hour: 18, minute: 0),
        'end': const TimeOfDay(hour: 19, minute: 30),
      },
      {
        'name': '夜間授業',
        'start': const TimeOfDay(hour: 19, minute: 30),
        'end': const TimeOfDay(hour: 21, minute: 0),
      },
    ];

    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule, color: primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'よく使う時間枠',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: presetTimes.map((preset) {
              return ListTile(
                title: Text(preset['name'] as String),
                subtitle: Text(
                  '${_formatTimeOfDay(preset['start'] as TimeOfDay)} - ${_formatTimeOfDay(preset['end'] as TimeOfDay)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: primaryColor),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  setState(() {
                    slot.startTime = preset['start'] as TimeOfDay;
                    slot.endTime = preset['end'] as TimeOfDay;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '閉じる',
              style:
                  TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // テーマカラーを取得
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 結果メッセージ表示
                  if (_resultMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _isSuccess
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    ),

                  // 教室選択
                  Text('教室',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: primaryColor.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: primaryColor.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    value: _selectedClassroomId,
                    items: _classrooms.map((classroom) {
                      return DropdownMenuItem<String>(
                        value: classroom.classroomId,
                        child: Text(classroom.classroomName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClassroomId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '教室を選択してください';
                      }
                      return null;
                    },
                    // ドロップダウン矢印の色もテーマに合わせる
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    // ドロップダウン背景色を白に
                    dropdownColor: Colors.white,
                  ),
                  const SizedBox(height: 20),

// 日付範囲選択
                  Text('予約期間',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 開始日
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              locale: const Locale('ja', 'JP'),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _startDate = picked;
                                // 終了日が開始日より前の場合、終了日を開始日に合わせる
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate = _startDate;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: primaryColor
                                      .withAlpha((0.5 * 255).toInt())),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('yyyy/MM/dd')
                                    .format(_startDate)),
                                Icon(Icons.calendar_today, color: primaryColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('~'),
                      const SizedBox(width: 16),
                      // 終了日
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate, // 開始日以降のみ選択可能
                              lastDate:
                                  _startDate.add(const Duration(days: 365)),
                              locale: const Locale('ja', 'JP'),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _endDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: primaryColor.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('yyyy/MM/dd').format(_endDate)),
                                Icon(Icons.calendar_today, color: primaryColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 曜日選択セクション
                  Text('曜日スケジュール',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 8),

                  // 曜日タブスクロール
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildDayTab(0, '日曜日', primaryColor, secondaryColor),
                        _buildDayTab(1, '月曜日', primaryColor, secondaryColor),
                        _buildDayTab(2, '火曜日', primaryColor, secondaryColor),
                        _buildDayTab(3, '水曜日', primaryColor, secondaryColor),
                        _buildDayTab(4, '木曜日', primaryColor, secondaryColor),
                        _buildDayTab(5, '金曜日', primaryColor, secondaryColor),
                        _buildDayTab(6, '土曜日', primaryColor, secondaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 選択された曜日の予定一覧
                  ..._buildScheduleSlots(primaryColor, secondaryColor),

                  // 予定追加ボタン
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: OutlinedButton.icon(
                        onPressed: () => _addScheduleSlot(_selectedDayOfWeek),
                        icon: Icon(Icons.add, color: primaryColor),
                        label: Text('予定を追加',
                            style: TextStyle(color: primaryColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Divider(),

                  // 除外日セクション
                  Text('除外日',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 4),
                  const Text('祝日など予約を入れたくない日を指定してください',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),

                  // 除外日リスト
                  if (_excludeDates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text('除外日は指定されていません',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _excludeDates.asMap().entries.map((entry) {
                      final index = entry.key;
                      final date = entry.value;
                      return Chip(
                        label: Text(DateFormat('yyyy/MM/dd').format(date)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeExcludeDate(index),
                        backgroundColor:
                            primaryColor.withAlpha((0.15 * 255).toInt()),
                        side: BorderSide(
                            color: primaryColor.withAlpha((0.3 * 255).toInt())),
                        deleteIconColor: primaryColor,
                      );
                    }).toList(),
                  ),

                  // 除外日追加ボタン
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: OutlinedButton.icon(
                        onPressed: _addExcludeDate,
                        icon: Icon(Icons.calendar_today, color: primaryColor),
                        label: Text('除外日を追加',
                            style: TextStyle(color: primaryColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 送信ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _createPatternSlots,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : const Text('パターン予約を作成',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
  }

// 曜日タブウィジェットを作成
// 曜日タブウィジェットを作成
  Widget _buildDayTab(
      int dayOfWeek, String dayName, Color primaryColor, Color secondaryColor) {
    final isSelected = _selectedDayOfWeek == dayOfWeek;
    final scheduleCount = _daySchedules[dayOfWeek]!.length;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDayOfWeek = dayOfWeek;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.15) : Colors.white,
          border: Border.all(
            color: isSelected ? primaryColor : primaryColor.withOpacity(0.3),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
            if (scheduleCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  scheduleCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// 予定スロットのウィジェットリストを生成
// 予定スロットのウィジェットリストを生成
  List<Widget> _buildScheduleSlots(Color primaryColor, Color secondaryColor) {
    final daySchedules = _daySchedules[_selectedDayOfWeek]!;

    if (daySchedules.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  '${_getDayName(_selectedDayOfWeek)}の予定はありません',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return daySchedules.asMap().entries.map((entry) {
      final index = entry.key;
      final slot = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: primaryColor, width: 4)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // スロットのヘッダー（時間帯と削除ボタン）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_getDayName(_selectedDayOfWeek)}の予定 ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  // 削除ボタンを追加
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _removeScheduleSlot(_selectedDayOfWeek, index),
                    tooltip: 'この予定を削除',
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // 時間帯
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text('時間帯',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor.withOpacity(0.8),
                          )),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showTimeRangePicker(context, slot),
                    icon:
                        Icon(Icons.auto_awesome, size: 16, color: primaryColor),
                    label:
                        Text('よく使う時間枠', style: TextStyle(color: primaryColor)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      side: BorderSide(color: primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 開始時間
                  Expanded(
                    child: InkWell(
                      onTap: () => _showTimePicker(context, slot, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: primaryColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatTimeOfDay(slot.startTime)),
                            Icon(Icons.access_time_filled, color: primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('~'),
                  const SizedBox(width: 16),
                  // 終了時間
                  Expanded(
                    child: InkWell(
                      onTap: () => _showTimePicker(context, slot, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: primaryColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatTimeOfDay(slot.endTime)),
                            Icon(Icons.access_time_filled, color: primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // コース選択
              Row(
                children: [
                  Icon(Icons.school, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text('コース',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor.withOpacity(0.8),
                      )),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: slot.courseId.isNotEmpty
                    ? slot.courseId
                    : (_courses.isNotEmpty ? _courses.first.courseId : null),
                items: _courses.map((course) {
                  return DropdownMenuItem<String>(
                    value: course.courseId,
                    child: Text(course.courseName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      slot.courseId = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'コースを選択してください';
                  }
                  return null;
                },
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: primaryColor),
              ),
              const SizedBox(height: 16),

              // 定員
              Row(
                children: [
                  Icon(Icons.people, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text('定員',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor.withOpacity(0.8),
                      )),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: slot.capacity.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  hintText: '例: 1, 5, 10 など',
                  prefixIcon: Icon(Icons.group, color: primaryColor),
                ),
                onChanged: (value) {
                  final capacity = int.tryParse(value);
                  if (capacity != null) {
                    setState(() {
                      slot.capacity = capacity;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '定員を入力してください';
                  }
                  if (int.tryParse(value) == null) {
                    return '数字を入力してください';
                  }
                  if (int.parse(value) <= 0) {
                    return '1以上の数字を入力してください';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // 曜日名を取得
  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 0:
        return '日曜日';
      case 1:
        return '月曜日';
      case 2:
        return '火曜日';
      case 3:
        return '水曜日';
      case 4:
        return '木曜日';
      case 5:
        return '金曜日';
      case 6:
        return '土曜日';
      default:
        return '';
    }
  }

  // TimeOfDayを文字列にフォーマット
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// 予定スロットクラス（1つの予定）
class ScheduleSlot {
  TimeOfDay startTime;
  TimeOfDay endTime;
  String courseId;
  int capacity;

  ScheduleSlot({
    required this.startTime,
    required this.endTime,
    required this.courseId,
    required this.capacity,
  });
}
