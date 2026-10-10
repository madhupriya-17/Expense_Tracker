import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_api.dart';

class AppData {
  // User info (frontend only for now)
  static String userName = 'Veditha';
  static String userEmail = 'veditha@example.com';
  static bool notificationsEnabled = true;
  static bool darkMode = false;
  static final ValueNotifier<bool> darkModeNotifier =
      ValueNotifier<bool>(false);

  // Monthly budget
  static double monthlyBudget = 10000;

  // Today's transactions. Starts empty every new day.
  static List<Map<String, dynamic>> transactions = [];

  // Previous days: 'yyyy-MM-dd' -> that day's transactions
  static Map<String, List<Map<String, dynamic>>> history = {};

  static String _currentDay = '';

  static final Map<String, Map<String, dynamic>> _styles = {
    'Food': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFFFE4EA),
      'iconColor': Color(0xFFE94B72)
    },
    'Transport': {
      'icon': Icons.directions_bus_rounded,
      'color': Color(0xFFE5F1FF),
      'iconColor': Color(0xFF3D82D8)
    },
    'Shopping': {
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFFFF1D9),
      'iconColor': Color(0xFFE99A2B)
    },
    'Bills': {
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFFEDE6FF),
      'iconColor': Color(0xFF7654BE)
    },
    'Health': {
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFFFE4E4),
      'iconColor': Color(0xFFE34D4D)
    },
    'Entertainment': {
      'icon': Icons.movie_rounded,
      'color': Color(0xFFE7E4FF),
      'iconColor': Color(0xFF6755C9)
    },
    'Education': {
      'icon': Icons.school_rounded,
      'color': Color(0xFFE2F5FF),
      'iconColor': Color(0xFF3189B8)
    },
    'Travel': {
      'icon': Icons.flight_rounded,
      'color': Color(0xFFE4F7EF),
      'iconColor': Color(0xFF2AA968)
    },
    'Salary': {
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFFE1F7EA),
      'iconColor': Color(0xFF2AA968)
    },
    'Others': {
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFEDEDED),
      'iconColor': Color(0xFF666666)
    },
  };

  // ----------------------------------------------------------
  // DATE HELPERS
  // ----------------------------------------------------------

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String dayKey(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String get todayKey => dayKey(DateTime.now());

  static String formatTime(DateTime t) {
    final int h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${_two(h)}:${_two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  static String timeLabel(DateTime t) {
    if (dayKey(t) == todayKey) return 'Today, ${formatTime(t)}';
    return '${_two(t.day)}/${_two(t.month)}, ${formatTime(t)}';
  }

  // ----------------------------------------------------------
  // BUILD / SERIALIZE TRANSACTIONS
  // ----------------------------------------------------------

  static Map<String, dynamic> _make(String name, double amount, DateTime time) {
    final style = _styles[name] ?? _styles['Others']!;
    return {
      'name': name,
      'amount': amount,
      'time': time,
      'date': timeLabel(time),
      'icon': style['icon'],
      'color': style['color'],
      'iconColor': style['iconColor'],
    };
  }

  static Map<String, dynamic> _toJson(Map<String, dynamic> t) => {
        'name': t['name'],
        'amount': t['amount'],
        'time': (t['time'] as DateTime).toIso8601String(),
      };

  static Map<String, dynamic> _fromJson(Map<String, dynamic> j) => _make(
        j['name'] as String,
        (j['amount'] as num).toDouble(),
        DateTime.parse(j['time'] as String),
      );

  static List<Map<String, dynamic>> _decodeList(dynamic raw) => (raw as List)
      .map((e) => _fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  // ----------------------------------------------------------
  // LOAD / SAVE / DAILY RESET
  // ----------------------------------------------------------

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      monthlyBudget = prefs.getDouble('budget') ?? monthlyBudget;

      final String? historyRaw = prefs.getString('history');
      if (historyRaw != null) {
        final Map<String, dynamic> decoded = jsonDecode(historyRaw);
        history = decoded.map((day, list) => MapEntry(day, _decodeList(list)));
      }

      _currentDay = prefs.getString('today_key') ?? todayKey;
      transactions =
          _decodeList(jsonDecode(prefs.getString('today_list') ?? '[]'));
    } catch (e) {
      // Saved data was unreadable. Start fresh instead of crashing.
      debugPrint('AppData.load failed: $e');
      history = {};
      transactions = [];
      _currentDay = todayKey;
    }

    checkNewDay();
  }

  /// If the day has changed, moves the previous day's spending into
  /// history and starts today at zero. Returns true if a reset happened.
  static bool checkNewDay() {
    if (_currentDay == todayKey) return false;

    if (transactions.isNotEmpty) {
      history[_currentDay] = [...transactions, ...?history[_currentDay]];
    }

    transactions = [];
    _currentDay = todayKey;
    save();
    return true;
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget', monthlyBudget);
    await prefs.setString('today_key', _currentDay);
    await prefs.setString(
      'today_list',
      jsonEncode(transactions.map(_toJson).toList()),
    );
    await prefs.setString(
      'history',
      jsonEncode(history.map(
        (day, list) => MapEntry(day, list.map(_toJson).toList()),
      )),
    );
  }

  // ----------------------------------------------------------
  // ADD TRANSACTION
  // ----------------------------------------------------------

  static void addTransaction({
    required String name,
    required double amount,
    required DateTime time,
  }) {
    checkNewDay();

    final tx = _make(name, amount, time);
    final key = dayKey(time);

    if (key == todayKey) {
      transactions.insert(0, tx);
    } else {
      history[key] = [tx, ...?history[key]];
    }
  }

  // ----------------------------------------------------------
  // TOTALS
  // ----------------------------------------------------------

  static double expenseSum(Iterable<Map<String, dynamic>> list) {
    double total = 0;
    for (final t in list) {
      final double a = t['amount'] as double;
      if (a < 0) total += a.abs();
    }
    return total;
  }

  static double incomeSum(Iterable<Map<String, dynamic>> list) {
    double total = 0;
    for (final t in list) {
      final double a = t['amount'] as double;
      if (a > 0) total += a;
    }
    return total;
  }

  // Today only
  static double get totalExpenses => expenseSum(transactions);
  static double get totalIncome => incomeSum(transactions);
  static double get balance => totalIncome - totalExpenses;

  // Whole current month (today + earlier days this month)
  static double get monthExpenses {
    final String prefix = todayKey.substring(0, 7);
    double total = totalExpenses;
    history.forEach((day, list) {
      if (day.startsWith(prefix)) total += expenseSum(list);
    });
    return total;
  }

  static double get leftToSpend => monthlyBudget - monthExpenses;

  static double get dailyAllowance {
    final now = DateTime.now();
    return monthlyBudget / DateUtils.getDaysInMonth(now.year, now.month);
  }
}