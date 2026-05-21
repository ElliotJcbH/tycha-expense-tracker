import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../models/expense.dart';

enum ChartView { breakdown, monthly, daily, categories, stacked }

class ChartScreen extends StatefulWidget {
  final List<Expense> expenses;

  const ChartScreen({super.key, required this.expenses});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  ChartView selectedView = ChartView.breakdown;
  final Set<String> _hiddenStackedCategories = {};

  @override
  Widget build(BuildContext context) {
    final total = widget.expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    String title;
    switch (selectedView) {
      case ChartView.monthly:
        title = 'Monthly Trend';
        break;
      case ChartView.daily:
        title = 'Daily Trend';
        break;
      case ChartView.categories:
        title = 'Top Categories';
        break;
      case ChartView.stacked:
        title = 'Category Mix';
        break;
      case ChartView.breakdown:
      default:
        title = 'Expense Breakdown';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChartChoice('Breakdown', ChartView.breakdown),
                  _buildChartChoice('Monthly', ChartView.monthly),
                  _buildChartChoice('Daily', ChartView.daily),
                  _buildChartChoice('Categories', ChartView.categories),
                  _buildChartChoice('Stacked', ChartView.stacked),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total: ${NumberFormat('#,###.00').format(total)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.expenses.isEmpty
                  ? const Center(child: Text('No data to display'))
                  : selectedView == ChartView.breakdown
                      ? _buildBreakdownChart()
                      : selectedView == ChartView.monthly
                          ? _buildMonthlyChart()
                          : selectedView == ChartView.daily
                              ? _buildDailyChart()
                              : selectedView == ChartView.categories
                                  ? _buildCategoryChart()
                                  : _buildStackedChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartChoice(String label, ChartView value) {
    final isSelected = selectedView == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        checkmarkColor: Colors.white,
        selected: isSelected,
        onSelected: (_) => setState(() => selectedView = value),
      ),
    );
  }

  Widget _buildBreakdownChart() {
    final Map<String, double> dataMap = {};
    for (var expense in widget.expenses) {
      dataMap.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final List<PieChartSectionData> sections = dataMap.entries.map((entry) {
      return PieChartSectionData(
        color: _getColor(entry.key),
        value: entry.value,
        title: entry.value.toStringAsFixed(0),
        radius: 90,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 60,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (event, response) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dataMap.keys.map((key) {
            return Chip(
              avatar: CircleAvatar(backgroundColor: _getColor(key)),
              label: Text(key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      return DateTime(now.year, now.month - (5 - index), 1);
    });

    final totalsByMonth = <String, double>{};
    for (final expense in widget.expenses) {
      final key = '${expense.date.year}-${expense.date.month}';
      totalsByMonth.update(key, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }

    final totals = months.map((month) {
      final key = '${month.year}-${month.month}';
      return totalsByMonth[key] ?? 0.0;
    }).toList();

    final maxY = totals.isEmpty ? 0.0 : max(10.0, totals.reduce(max) * 1.2);

    final groups = List.generate(totals.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totals[index],
            color: const Color(0xFF1A36FF),
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
        showingTooltipIndicators: const [0],
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = DateFormat('MMM').format(months[group.x.toInt()]);
              return BarTooltipItem(
                '$month\n${NumberFormat('#,###.00').format(rod.toY)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) return const SizedBox.shrink();
                return Text(DateFormat('MMM').format(months[index]));
              },
            ),
          ),
        ),
        barGroups: groups,
      ),
    );
  }

  Widget _buildDailyChart() {
    final now = DateTime.now();
    final days = List.generate(14, (index) {
      final day = now.subtract(Duration(days: 13 - index));
      return DateTime(day.year, day.month, day.day);
    });

    final totalsByDay = <String, double>{};
    for (final expense in widget.expenses) {
      final dayKey = DateTime(expense.date.year, expense.date.month, expense.date.day).toIso8601String();
      totalsByDay.update(dayKey, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final key = days[i].toIso8601String();
      final value = totalsByDay[key] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    final maxY = spots.isEmpty ? 0.0 : max(10.0, spots.map((e) => e.y).reduce(max) * 1.2);

    final lineBar = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: const Color(0xFF1A36FF),
      barWidth: 3,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: const Color(0xFF1A36FF).withValues(alpha: 0.15),
      ),
    );

    final showingIndicators = List.generate(spots.length, (index) {
      return ShowingTooltipIndicators([
        LineBarSpot(lineBar, 0, spots[index]),
      ]);
    });

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final date = DateFormat('MM/dd').format(days[spot.x.toInt()]);
                return LineTooltipItem(
                  '$date\n${NumberFormat('#,###.00').format(spot.y)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox.shrink();
                return Text(DateFormat('MM/dd').format(days[index]));
              },
            ),
          ),
        ),
        showingTooltipIndicators: showingIndicators,
        lineBarsData: [lineBar],
      ),
    );
  }

  Widget _buildCategoryChart() {
    final totals = <String, double>{};
    for (final expense in widget.expenses) {
      totals.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(6).toList();
    final maxY = topEntries.isEmpty ? 0.0 : max(10.0, topEntries.first.value * 1.2);

    final groups = List.generate(topEntries.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: topEntries[index].value,
            color: _getColor(topEntries[index].key),
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
        showingTooltipIndicators: const [0],
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = topEntries[group.x.toInt()].key;
              return BarTooltipItem(
                '$label\n${NumberFormat('#,###.00').format(rod.toY)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= topEntries.length) return const SizedBox.shrink();
                final label = topEntries[index].key;
                return Text(label.length > 6 ? '${label.substring(0, 6)}…' : label);
              },
            ),
          ),
        ),
        barGroups: groups,
      ),
    );
  }

  Widget _buildStackedChart() {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      return DateTime(now.year, now.month - (5 - index), 1);
    });

    final topCategories = _topCategories(widget.expenses, limit: 4);
    final displayCategories = [...topCategories, 'Other'];

    final totalsByMonth = <String, Map<String, double>>{};
    for (final expense in widget.expenses) {
      final key = '${expense.date.year}-${expense.date.month}';
      totalsByMonth.putIfAbsent(key, () => {});
      final isTop = topCategories.contains(expense.category);
      final categoryKey = isTop ? expense.category : 'Other';
      totalsByMonth[key]!.update(
        categoryKey,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final groups = <BarChartGroupData>[];
    double maxTotal = 0;

    for (var i = 0; i < months.length; i++) {
      final monthKey = '${months[i].year}-${months[i].month}';
      final monthTotals = totalsByMonth[monthKey] ?? {};

      double runningTotal = 0;
      final stacks = <BarChartRodStackItem>[];
      for (final category in displayCategories) {
        if (_hiddenStackedCategories.contains(category)) continue;
        final value = monthTotals[category] ?? 0;
        if (value <= 0) continue;
        final fromY = runningTotal;
        runningTotal += value;
        stacks.add(BarChartRodStackItem(
          fromY,
          runningTotal,
          category == 'Other' ? Colors.grey : _getColor(category),
        ));
      }

      if (runningTotal > maxTotal) maxTotal = runningTotal;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: runningTotal,
              rodStackItems: stacks,
              width: 18,
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF1A36FF),
            ),
          ],
          showingTooltipIndicators: const [0],
        ),
      );
    }

    final maxY = max(10.0, maxTotal * 1.2);

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: false,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = DateFormat('MMM').format(months[group.x.toInt()]);
                    return BarTooltipItem(
                      '$month\n${NumberFormat('#,###.00').format(rod.toY)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= months.length) return const SizedBox.shrink();
                      return Text(DateFormat('MMM').format(months[index]));
                    },
                  ),
                ),
              ),
              barGroups: groups,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_hiddenStackedCategories.isNotEmpty)
          TextButton(
            onPressed: () => setState(() => _hiddenStackedCategories.clear()),
            child: const Text('Show all categories'),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayCategories.map((category) {
            final color = category == 'Other' ? Colors.grey : _getColor(category);
            return FilterChip(
              avatar: CircleAvatar(backgroundColor: color),
              label: Text(category),
              selected: !_hiddenStackedCategories.contains(category),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _hiddenStackedCategories.remove(category);
                  } else {
                    _hiddenStackedCategories.add(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  List<String> _topCategories(List<Expense> expenses, {int limit = 4}) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
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
