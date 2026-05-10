import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/database_service.dart';

class AddExpenseForm extends StatefulWidget {
  final DatabaseService db;
  final Expense? expense;

  const AddExpenseForm({super.key, required this.db, this.expense});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String> categories = ['Food', 'Transport', 'Bills', 'Shopping', 'Entertainment', 'Others'];

  late double amount;
  late String category;
  late DateTime date;
  late String note;

  @override
  void initState() {
    super.initState();
    amount = widget.expense?.amount ?? 0.0;
    category = widget.expense?.category ?? categories[0];
    date = widget.expense?.date ?? DateTime.now();
    note = widget.expense?.note ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.expense == null ? 'Add Expense' : 'Edit Expense',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: widget.expense != null ? amount.toString() : '',
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
                onChanged: (val) => setState(() => amount = double.tryParse(val) ?? 0.0),
              ),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => category = val);
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text("Date: ${DateFormat('yyyy-MM-dd').format(date)}"),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              TextFormField(
                initialValue: note,
                decoration: const InputDecoration(labelText: 'Note (Optional)'),
                onChanged: (val) => setState(() => note = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0000FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (widget.expense == null) {
                      await widget.db.addExpense(amount, category, date, note);
                    } else {
                      await widget.db.updateExpense(widget.expense!.id, amount, category, date, note);
                    }
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(widget.expense == null ? 'Save' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
