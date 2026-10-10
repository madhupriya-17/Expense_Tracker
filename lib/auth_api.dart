
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static String? accessToken;

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _post('/auth/login', {
      'email': email,
      'password': password,
    });

    accessToken = result['access_token'] as String?;
    return result;
  }

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  // ADD EXPENSE OR INCOME
  static Future<Map<String, dynamic>> addExpense({
    required String title,
    required double amount,
    required String type,
    required String category,
    required DateTime transactionDate,
  }) async {
    return _post(
      '/expenses',
      {
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'transaction_date': transactionDate.toIso8601String(),
      },
      authenticated: true,
    );
  }

  // GET TRANSACTIONS
  static Future<List<dynamic>> getExpenses() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/expenses'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(data, 'Could not load transactions'),
      );
    }

    if (data is! List) {
      throw Exception('Unexpected transactions response.');
    }

    return data;
  }

  // DELETE TRANSACTION
  static Future<void> deleteExpense(int expenseId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/expenses/$expenseId'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final data = _decodeResponse(response);
      throw Exception(
        _errorMessage(data, 'Could not delete transaction'),
      );
    }
  }

  // GET MONTHLY BUDGET
  static Future<Map<String, dynamic>> getBudget() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/budget'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(data, 'Could not get budget'),
      );
    }

    if (data is! Map) {
      throw Exception('Unexpected budget response.');
    }

    return Map<String, dynamic>.from(data);
  }

  // UPDATE MONTHLY BUDGET
  static Future<Map<String, dynamic>> updateBudget(
    double monthlyBudget,
  ) async {
    return _put('/budget', {
      'monthly_budget': monthlyBudget,
    });
  }

  // SEND MONTHLY REPORT EMAIL
  static Future<Map<String, dynamic>> sendMonthlyReport({
    int? month,
    int? year,
  }) async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception(
        'Please log in using your backend account first.',
      );
    }

    final now = DateTime.now();
    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;

    if (selectedMonth < 1 || selectedMonth > 12) {
      throw Exception('Month must be between 1 and 12.');
    }

    if (selectedYear < 2000 || selectedYear > 2100) {
      throw Exception('Please enter a valid year.');
    }

    final uri = Uri.parse(
      '$baseUrl/reports/monthly-email',
    ).replace(
      queryParameters: {
        'month': selectedMonth.toString(),
        'year': selectedYear.toString(),
      },
    );

    final response = await http
        .post(
          uri,
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 30));

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is! Map) {
        throw Exception('Unexpected report response.');
      }

      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      _errorMessage(data, 'Could not send monthly report'),
    );
  }

  // AUTHENTICATION HEADERS
  static Map<String, String> _authHeaders() {
    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception('Please log in again.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  // POST REQUEST
  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: authenticated
              ? _authHeaders()
              : {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_errorMessage(data, 'Request failed'));
    }

    if (data is! Map) {
      throw Exception('Unexpected response from server.');
    }

    return Map<String, dynamic>.from(data);
  }

  // PUT REQUEST
  static Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: _authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_errorMessage(data, 'Request failed'));
    }

    if (data is! Map) {
      throw Exception('Unexpected response from server.');
    }

    return Map<String, dynamic>.from(data);
  }

  // DECODE SERVER RESPONSE
  static dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      return <String, dynamic>{
        'detail': 'The server returned an unreadable response.',
      };
    }
  }

  // FRIENDLY ERROR MESSAGE
  static String _errorMessage(
    dynamic data,
    String fallback,
  ) {
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }

    return fallback;
  }
}
