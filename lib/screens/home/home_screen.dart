import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'add_expense_form.dart';
import 'expense_list.dart';
import 'chart_screen.dart';

enum TimeRange { month, week, all }

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> baseCategories = const [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Entertainment',
    'Others',
  ];

  final TextEditingController _searchController = TextEditingController();

  TimeRange selectedRange = TimeRange.month;
  String selectedCategory = 'All';
  String searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters {
    return selectedRange != TimeRange.month || selectedCategory != 'All' || searchQuery.trim().isNotEmpty;
  }

  Future<void> _confirmSignOut(AuthService auth) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut ?? false) {
      await auth.signOut();
    }
  }

  void _showExportPlaceholder() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export CSV'),
        content: const Text('Export is coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openAddExpenseSheet(DatabaseService db, {Expense? expense, String? initialCategory}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddExpenseForm(
          db: db,
          expense: expense,
          initialCategory: initialCategory,
        ),
      ),
    );
  }

  List<String> _buildCategoryFilters(List<Expense> expenses) {
    final categories = <String>{...baseCategories};
    for (final expense in expenses) {
      if (!baseCategories.contains(expense.category)) {
        categories.add(expense.category);
      }
    }
    return ['All', ...categories.toList()..sort()];
  }

  List<Expense> _applyFilters(List<Expense> expenses) {
    final now = DateTime.now();
    List<Expense> filtered = expenses;

    if (selectedRange == TimeRange.month) {
      filtered = filtered
          .where((e) => e.date.month == now.month && e.date.year == now.year)
          .toList();
    } else if (selectedRange == TimeRange.week) {
      final weekAgo = now.subtract(const Duration(days: 7));
      filtered = filtered.where((e) => e.date.isAfter(weekAgo)).toList();
    }

    if (selectedCategory != 'All') {
      filtered = filtered.where((e) => e.category == selectedCategory).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.category.toLowerCase().contains(query) || e.note.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  String _rangeLabel() {
    switch (selectedRange) {
      case TimeRange.week:
        return 'Last 7 Days';
      case TimeRange.all:
        return 'All Time';
      case TimeRange.month:
      default:
        return 'This Month';
    }
  }

  String _yearLabel() {
    final year = DateTime.now().year;
    switch (selectedRange) {
      case TimeRange.month:
      case TimeRange.week:
        return year.toString();
      case TimeRange.all:
      default:
        return 'All Years';
    }
  }

  void _openFilterSheet(List<String> categoryFilters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Text('Filter by category', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: categoryFilters.map((cat) {
                      return RadioListTile<String>(
                        value: cat,
                        groupValue: selectedCategory,
                        title: Text(cat),
                        secondary: cat == 'All'
                            ? null
                            : CircleAvatar(backgroundColor: _categoryColor(cat), radius: 10),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => selectedCategory = value);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _hasActiveFilters ? _resetFilters : null,
                      child: const Text('Clear'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Bills':
        return Colors.red;
      case 'Shopping':
        return Colors.purple;
      case 'Entertainment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMonthDelta(List<Expense> expenses) {
    final totals = _monthTotals(expenses);
    final current = totals['current'] ?? 0;
    final previous = totals['previous'] ?? 0;

    final diff = current - previous;
    final percent = previous == 0 ? 0 : (diff / previous) * 100;
    final isUp = diff >= 0;
    final color = isUp ? Colors.greenAccent : Colors.redAccent;
    final sign = isUp ? '+' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isUp ? Icons.trending_up : Icons.trending_down, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          '$sign${NumberFormat('#,###').format(diff.abs())} (${sign}${percent.toStringAsFixed(1)}%) vs last month',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  Map<String, double> _monthTotals(List<Expense> expenses) {
    final now = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);

    double currentMonthTotal = 0;
    double lastMonthTotal = 0;

    for (var expense in expenses) {
      if (expense.date.isAfter(firstDayOfLastMonth)) {
        if (expense.date.isBefore(firstDayOfCurrentMonth) || expense.date.day == 1) {
          lastMonthTotal += expense.amount;
        } else {
          currentMonthTotal += expense.amount;
        }
      }
    }

    return {
      'current': currentMonthTotal,
      'previous': lastMonthTotal,
    };
  }

  void _resetFilters() {
    setState(() {
      selectedRange = TimeRange.month;
      selectedCategory = 'All';
      searchQuery = '';
      _searchController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();
    final DatabaseService db = DatabaseService(uid: widget.user.uid);
    final size = MediaQuery.of(context).size;
    final headerHeight = (size.height * 0.36).clamp(250.0, 340.0);

    return StreamBuilder<List<Expense>>(
      stream: db.expenses,
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];
        final filteredExpenses = _applyFilters(expenses);
        final totalSpent = filteredExpenses.fold<double>(0, (sum, item) => sum + item.amount);
        final categoryFilters = _buildCategoryFilters(expenses);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Container(
                height: headerHeight,
                width: double.infinity,
                color: const Color(0xFF1A36FF),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                                  onPressed: _showExportPlaceholder,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout, color: Colors.white),
                                  onPressed: () => _confirmSignOut(auth),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "You've Spent",
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  NumberFormat('#,###').format(totalSpent),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _rangeLabel(),
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                              ),
                              Text(
                                _yearLabel(),
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 12),
                  children: [
                    if (selectedRange == TimeRange.month)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildMonthDelta(expenses),
                      ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SegmentedButton<TimeRange>(
                            segments: const [
                              ButtonSegment(value: TimeRange.month, label: Text('Month')),
                              ButtonSegment(value: TimeRange.week, label: Text('7 Days')),
                              ButtonSegment(value: TimeRange.all, label: Text('All')),
                            ],
                            selected: {selectedRange},
                            onSelectionChanged: (value) {
                              setState(() => selectedRange = value.first);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search category or note',
                        ),
                        onChanged: (value) => setState(() => searchQuery = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filters', style: TextStyle(fontWeight: FontWeight.w600)),
                          TextButton.icon(
                            onPressed: () => _openFilterSheet(categoryFilters),
                            icon: const Icon(Icons.tune),
                            label: Text(selectedCategory == 'All' ? 'All' : selectedCategory),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: baseCategories.length - 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = baseCategories[index];
                          return ActionChip(
                            label: Text('+ $category'),
                            onPressed: () => _openAddExpenseSheet(db, initialCategory: category),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpenseList(
                      expenses: filteredExpenses,
                      db: db,
                      onAdd: () => _openAddExpenseSheet(db),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                  ],
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
                      builder: (context) => ChartScreen(expenses: filteredExpenses),
                    ),
                  );
                },
                child: const Icon(Icons.pie_chart),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'add',
                onPressed: () => _openAddExpenseSheet(db),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }
}
