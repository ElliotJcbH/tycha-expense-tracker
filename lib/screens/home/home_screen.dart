import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'add_expense_form.dart';
import 'expense_list.dart';
import 'chart_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();
    final DatabaseService db = DatabaseService(uid: user.uid);

    return StreamBuilder<List<Expense>>(
      stream: db.expenses,
      builder: (context, snapshot) {
        double totalSpent = 0;
        if (snapshot.hasData) {
          final now = DateTime.now();
          totalSpent = snapshot.data!
              .where((e) => e.date.month == now.month && e.date.year == now.year)
              .fold(0.0, (sum, item) => sum + item.amount);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Header Section
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                color: const Color(0xFF0000FF),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tycha',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async => await auth.signOut(),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'You\'ve Spent',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            NumberFormat('#,###').format(totalSpent),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'This Month',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              // List Section
              Expanded(
                child: ExpenseList(
                  expenses: snapshot.data ?? [],
                  db: db,
                ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'chart',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChartScreen(expenses: snapshot.data ?? []),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF0000FF),
                child: const Icon(Icons.pie_chart, color: Colors.white),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'add',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: AddExpenseForm(db: db),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF0000FF),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
