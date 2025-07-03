import 'package:educo_yoyaku/widgets/single_day_reservation.dart';
import 'package:educo_yoyaku/widgets/multiple_days_reservation.dart';
import 'package:flutter/material.dart';

class MakeReservationScreen extends StatefulWidget {
  const MakeReservationScreen({super.key});

  @override
  State<MakeReservationScreen> createState() => _MakeReservationScreenState();
}

class _MakeReservationScreenState extends State<MakeReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // テーマカラーを取得
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('予約枠作成'),
        bottom: TabBar(
          controller: _tabController,
          // タブ選択インジケーターのカスタマイズ
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          // ラベルのスタイル
          labelColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          dividerColor: Theme.of(context).appBarTheme.foregroundColor,
          // 非選択時のラベルスタイル
          unselectedLabelColor: Colors.white70,
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: '単発予約'),
            Tab(text: '定期予約'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 単発予約のタブコンテンツ
          _buildSingleReservationTab(),

          // 定期予約のタブコンテンツ
          _buildRecurringReservationTab(),
        ],
      ),
    );
  }

  // 単発予約のタブコンテンツ
  Widget _buildSingleReservationTab() {
    return const SingleDayReservation();
  }

  // 定期予約のタブコンテンツ
  Widget _buildRecurringReservationTab() {
    return const MultipleDaysReservation();
  }
}
