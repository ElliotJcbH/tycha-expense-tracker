import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  // collection reference
  CollectionReference get expenseCollection {
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('expenses');
  }

  // add expense
  Future<void> addExpense(double amount, String category, DateTime date, String note) async {
    await expenseCollection.add({
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'note': note,
    });
  }

  // update expense
  Future<void> updateExpense(String id, double amount, String category, DateTime date, String note) async {
    await expenseCollection.doc(id).update({
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'note': note,
    });
  }

  // delete expense
  Future<void> deleteExpense(String id) async {
    await expenseCollection.doc(id).delete();
  }

  // get expenses stream
  Stream<List<Expense>> get expenses {
    return expenseCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromFirestore(doc);
      }).toList();
    });
  }
}
