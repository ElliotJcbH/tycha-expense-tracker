import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/database_service.dart';

class AddExpenseForm extends StatefulWidget {
  final DatabaseService db;
  final Expense? expense;
  final String? initialCategory;

  const AddExpenseForm({super.key, required this.db, this.expense, this.initialCategory});

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
  String customCategory = '';

  @override
  void initState() {
    super.initState();
    amount = widget.expense?.amount ?? 0.0;
    category = widget.expense?.category ?? categories[0];
    date = widget.expense?.date ?? DateTime.now();
    note = widget.expense?.note ?? '';

    if (widget.expense != null && !categories.contains(widget.expense!.category)) {
      category = 'Others';
      customCategory = widget.expense!.category;
    } else if (widget.initialCategory != null) {
      if (categories.contains(widget.initialCategory)) {
        category = widget.initialCategory!;
      } else {
        category = 'Others';
        customCategory = widget.initialCategory!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Text(
                isEditing ? 'Edit Expense' : 'Add Expense',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: isEditing ? amount.toStringAsFixed(2) : '',
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  final parsed = double.tryParse(val ?? '');
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
                onChanged: (val) => setState(() => amount = double.tryParse(val) ?? 0.0),
              ),
              const SizedBox(height: 14),
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
              if (category == 'Others') ...[
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: customCategory,
                  decoration: const InputDecoration(labelText: 'Custom Category'),
                  validator: (val) {
                    if (category != 'Others') return null;
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter a custom category';
                    }
                    return null;
                  },
                  onChanged: (val) => setState(() => customCategory = val),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Text("Date: ${DateFormat('yyyy-MM-dd').format(date)}")),
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
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final resolvedCategory = category == 'Others'
                        ? customCategory.trim()
                        : category;
                    if (resolvedCategory.isEmpty) return;

                    if (widget.expense == null) {
                      await widget.db.addExpense(amount, resolvedCategory, date, note);
                    } else {
                      await widget.db.updateExpense(widget.expense!.id, amount, resolvedCategory, date, note);
                    }
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
              if (isEditing) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete expense?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete ?? false) {
                      await widget.db.deleteExpense(widget.expense!.id);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Expense', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
