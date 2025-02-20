import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educo_yoyaku/models/reservation.dart';

class ReservationRepository {
  final _firestore = FirebaseFirestore.instance;

  // 単一予約取得
  Future<Reservation?> getReservation(String reservationId) async {
    final doc =
        await _firestore.collection('reservations').doc(reservationId).get();
    if (!doc.exists) return null;
    return Reservation.fromFirestore(doc);
  }

  // 全予約取得
  Future<List<Reservation>> getAllReservations() async {
    final snapshot = await _firestore.collection('reservations').get();
    return snapshot.docs.map((doc) => Reservation.fromFirestore(doc)).toList();
  }

  // 日付で予約取得
  Future<List<Reservation>> getReservationsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay =
        startOfDay.add(Duration(hours: 23, minutes: 59, seconds: 59));

    final snapshot = await _firestore
        .collection('reservations')
        .where('startDateTime',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('startDateTime', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();

    return snapshot.docs.map((doc) => Reservation.fromFirestore(doc)).toList();
  }

  // リアルタイム監視
  Stream<List<Reservation>> watchReservations() {
    return _firestore.collection('reservations').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Reservation.fromFirestore(doc))
          .toList();
    });
  }

  // 予約追加/更新
  Future<void> saveReservation(Reservation reservation) async {
    await _firestore
        .collection('reservations')
        .doc(reservation.reservationId)
        .set(reservation.toFirestore());
  }

  // 予約削除
  Future<void> deleteReservation(String reservationId) async {
    await _firestore.collection('reservations').doc(reservationId).delete();
  }
}
