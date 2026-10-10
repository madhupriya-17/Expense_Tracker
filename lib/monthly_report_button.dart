
import 'package:flutter/material.dart';
import 'auth_api.dart';

class MonthlyReportButton extends StatefulWidget {
  const MonthlyReportButton({super.key});

  @override
  State<MonthlyReportButton> createState() =>
      _MonthlyReportButtonState();
}

class _MonthlyReportButtonState extends State<MonthlyReportButton> {
  bool isSending = false;

  Future<void> sendReport() async {
    if (isSending) return;

    setState(() => isSending = true);

    try {
      final result = await AuthApi.sendMonthlyReport();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            result['message']?.toString() ??
                'Monthly report sent successfully!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF0B1B45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF60A5FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                color: Color(0xFF60A5FA),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Monthly Expense Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Receive your monthly income, expenses, balance, '
            'and category summary in your registered email.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSending ? null : sendReport,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.email_rounded),
              label: Text(
                isSending
                    ? 'Sending email...'
                    : 'Send Monthly Report',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
