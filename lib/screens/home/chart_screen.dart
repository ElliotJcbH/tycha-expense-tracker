import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/expense.dart';

class ChartScreen extends StatelessWidget {
  final List<Expense> expenses;

  const ChartScreen({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> dataMap = {};
    for (var expense in expenses) {
      dataMap.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final List<PieChartSectionData> sections = dataMap.entries.map((entry) {
      return PieChartSectionData(
        color: _getColor(entry.key),
        value: entry.value,
        title: '${entry.key}\n${entry.value.toStringAsFixed(0)}',
        radius: 100,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Breakdown'),
        backgroundColor: const Color(0xFF0000FF),
        foregroundColor: Colors.white,
      ),
      body: sections.isEmpty
          ? const Center(child: Text('No data to display'))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
    );
  }

  Color _getColor(String category) {
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
}
