import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return Expense(
      id: doc.id,
      amount: (data?['amount'] ?? 0.0).toDouble(),
      category: data?['category'] ?? 'Others',
      date: (data?['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data?['note'] ?? '',
    );
  }
}
