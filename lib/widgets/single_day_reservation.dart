import 'package:flutter/material.dart';
import 'package:educo_yoyaku/models/classroom.dart';
import 'package:educo_yoyaku/models/course.dart';
import 'package:educo_yoyaku/repositories/classroom_repository.dart';
import 'package:educo_yoyaku/repositories/course_repository.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as custom_picker;

class SingleDayReservation extends StatefulWidget {
  const SingleDayReservation({super.key});

  @override
  State<SingleDayReservation> createState() => _SingleDayReservationState();
}

class _SingleDayReservationState extends State<SingleDayReservation> {
  final ClassroomRepository _classroomRepository = ClassroomRepository();
  final CourseRepository _courseRepository = CourseRepository();

  // フォームのキー
  final _formKey = GlobalKey<FormState>();

  // 選択された教室とコース
  String? _selectedClassroomId;
  String? _selectedCourseId;

  // 日付と時間
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 1));

  // コースID (保持しておく)
  final TextEditingController _courseIdController = TextEditingController();

  // 定員
  final TextEditingController _capacityController = TextEditingController();

  // 教室リストとコースリスト
  List<Classroom> _classrooms = [];
  List<Course> _courses = [];

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
        if (_courses.isNotEmpty) {
          _selectedCourseId = _courses.first.courseId;
          _courseIdController.text = _courses.first.courseId;
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

  // APIでスロットを作成
  Future<void> _createSlot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _resultMessage = null;
    });

    try {
      // リクエストデータの作成
      final Map<String, dynamic> requestData = {
        'classroomId': _selectedClassroomId,
        'slotData': {
          'courseId': _selectedCourseId,
          'startDateTime': _startDateTime.toIso8601String(),
          'endDateTime': _endDateTime.toIso8601String(),
          'capacity': int.parse(_capacityController.text),
        },
      };

      // APIリクエスト送信
      final response = await http.post(
        Uri.parse(
            'https://k1abrrebtl.execute-api.ap-northeast-1.amazonaws.com/slots'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _resultMessage = 'スロットが正常に作成されました！';
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

  @override
  Widget build(BuildContext context) {
    // テーマカラーを取得
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

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
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    dropdownColor: Colors.white,
                  ),
                  const SizedBox(height: 20),

                  // コース選択
                  Text('コース',
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
                    value: _selectedCourseId,
                    items: _courses.map((course) {
                      return DropdownMenuItem<String>(
                        value: course.courseId,
                        child: Text(course.courseName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCourseId = value;
                        _courseIdController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'コースを選択してください';
                      }
                      return null;
                    },
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    dropdownColor: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  // 開始日時
                  Text('開始日時',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      // 開始日時のDatePicker
                      custom_picker.DatePicker.showDateTimePicker(
                        context,
                        showTitleActions: true,
                        minTime: DateTime.now(),
                        maxTime: DateTime.now().add(const Duration(days: 365)),
                        onConfirm: (date) {
                          setState(() {
                            _startDateTime = date;

                            // 終了時間が開始時間と同じ日付でない場合、または開始時間より前の場合は調整
                            final endOfDay = DateTime(
                                date.year, date.month, date.day, 23, 59);

                            // 終了時間を開始時間の1.5時間後に設定（同じ日の範囲内で）
                            final newEndTime =
                                date.add(const Duration(minutes: 90));

                            // 新しい終了時間が同じ日の範囲内かチェック
                            if (newEndTime.day != date.day) {
                              // 日付が変わる場合は23:59に設定
                              _endDateTime = endOfDay;
                            } else {
                              // 同じ日の範囲内ならそのまま設定
                              _endDateTime = newEndTime;
                            }
                          });
                        },
                        currentTime: _startDateTime,
                        locale: custom_picker.LocaleType.jp,
                        theme: custom_picker.DatePickerTheme(
                          backgroundColor: Colors.white,
                          itemStyle: const TextStyle(color: Colors.black87),
                          doneStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          cancelStyle: const TextStyle(color: Colors.white),
                          headerColor: primaryColor,
                          containerHeight: 210.0,
                        ),
                      );
                    },
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
                          Text(DateFormat('yyyy/MM/dd HH:mm')
                              .format(_startDateTime)),
                          Icon(Icons.calendar_today, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 終了日時
                  Text('終了日時',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
// 終了日時のDatePicker設定を変更
                      custom_picker.DatePicker.showDateTimePicker(
                        context,
                        showTitleActions: true,
                        // 同じ日の範囲内のみ許可（開始時間から24時間未満かつ同じ日付）
                        minTime:
                            _startDateTime.add(const Duration(minutes: 30)),
                        maxTime: DateTime(_startDateTime.year,
                            _startDateTime.month, _startDateTime.day, 23, 59),
                        onConfirm: (date) {
                          setState(() {
                            _endDateTime = date;
                          });
                        },
                        currentTime: _endDateTime.isAfter(DateTime(
                                _startDateTime.year,
                                _startDateTime.month,
                                _startDateTime.day,
                                23,
                                59))
                            ? DateTime(
                                _startDateTime.year,
                                _startDateTime.month,
                                _startDateTime.day,
                                _startDateTime.hour + 1,
                                _startDateTime.minute)
                            : _endDateTime,
                        locale: custom_picker.LocaleType.jp,
                        theme: custom_picker.DatePickerTheme(
                          backgroundColor: Colors.white,
                          itemStyle: const TextStyle(color: Colors.black87),
                          doneStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          cancelStyle: const TextStyle(color: Colors.white),
                          headerColor: primaryColor,
                          containerHeight: 210.0,
                        ),
                      );
                    },
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
                          Text(DateFormat('yyyy/MM/dd HH:mm')
                              .format(_endDateTime)),
                          Icon(Icons.calendar_today, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 定員
                  Text('定員',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _capacityController,
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
                  const SizedBox(height: 30),

                  // 送信ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _createSlot,
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
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('予約スロットを作成',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
