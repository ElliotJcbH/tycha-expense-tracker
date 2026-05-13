import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/database_service.dart';
import 'add_expense_form.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final DatabaseService db;
  final VoidCallback? onAdd;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ExpenseList({
    super.key,
    required this.expenses,
    required this.db,
    this.onAdd,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 48, color: Color(0xFF1A36FF)),
            const SizedBox(height: 12),
            const Text('No expenses recorded yet.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add your first expense'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: expenses.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Dismissible(
          key: Key(expense.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            await db.deleteExpense(expense.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense deleted')),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1A36FF).withOpacity(0.1),
                child: Icon(_getCategoryIcon(expense.category), color: const Color(0xFF1A36FF)),
              ),
              title: Text(
                expense.category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(expense.date)),
              trailing: Text(
                '-${NumberFormat('#,###.00').format(expense.amount)}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: AddExpenseForm(db: db, expense: expense),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Bills': return Icons.receipt;
      case 'Shopping': return Icons.shopping_bag;
      case 'Entertainment': return Icons.movie;
      default: return Icons.money;
    }
  }
}
