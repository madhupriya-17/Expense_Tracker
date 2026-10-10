import 'package:flutter/material.dart';
import 'app_data.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const Color _red = Color(0xFFDC2626);

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  String _dayLabel(String key) {
    final parts = key.split('-');
    final d = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final Color muted = t.colorScheme.onSurface.withOpacity(0.55);
    final String today = AppData.todayKey;

    final entries = AppData.history.entries
        .where((e) => e.value.isNotEmpty && e.key != today)
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (AppData.transactions.isNotEmpty) {
      entries.insert(0, MapEntry(today, AppData.transactions));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
      ),
      body: entries.isEmpty
          ? Center(
              child: Text(
                'No previous expenses yet.',
                style: TextStyle(color: muted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final bool isToday = entry.key == today;
                final double total = AppData.expenseSum(entry.value);

                final dayTx = [...entry.value]..sort(
                    (a, b) => (b['time'] as DateTime)
                        .compareTo(a['time'] as DateTime),
                  );

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: t.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: t.dividerColor),
                    boxShadow: t.brightness == Brightness.dark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Theme(
                    data: t.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 18),
                      title: Text(
                        isToday ? 'Today' : _dayLabel(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${dayTx.length} transactions',
                        style: TextStyle(color: muted),
                      ),
                      trailing: Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _red,
                        ),
                      ),
                      children: dayTx.map((tx) {
                        final double amount = tx['amount'] as double;
                        final bool isIncome = amount > 0;

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 18),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tx['color'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tx['icon'] as IconData,
                              color: tx['iconColor'] as Color,
                              size: 20,
                            ),
                          ),
                          title: Text(tx['name'] as String),
                          subtitle: Text(
                            AppData.formatTime(tx['time'] as DateTime),
                            style: TextStyle(color: muted),
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}₹${amount.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isIncome
                                  ? const Color(0xFF16A34A)
                                  : _red,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}