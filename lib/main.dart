import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_data.dart';
import 'spend_orb.dart';
import 'history_screen.dart';
import 'auth_api.dart';
import 'monthly_report_button.dart';
// ============================================================
// COLOURS
// ============================================================

const Color kBlack = Color(0xFF000000);
const Color kBlueTop = Color(0xFF1E3A8A);
const Color kBlueBottom = Color(0xFF0B1B45);
const Color kAccent = Color(0xFF60A5FA);
const Color kGreen = Color(0xFF4ADE80);
const Color kRed = Color(0xFFF87171);
const Color kMuted = Color(0xB3FFFFFF); // white 70%

const LinearGradient kBlueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kBlueTop, kBlueBottom],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.load();
  runApp(const PersonalExpenseTracker());
}

// ============================================================
// HELPERS
// ============================================================

/// Turns "veditha.k@gmail.com" into "Veditha K".
String nameFromEmail(String email) {
  final String local = email.split('@').first;
  final List<String> words = local
      .split(RegExp(r'[._\-0-9]+'))
      .where((w) => w.isNotEmpty)
      .toList();

  if (words.isEmpty) return 'User';

  return words
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

String greetingNow() {
  final int hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning,';
  if (hour < 17) return 'Good Afternoon,';
  return 'Good Evening,';
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              minimumSize: const Size(90, 44),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              AuthApi.accessToken = null;
              await AppData.save();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );
}

void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How to add an expense'),
              SizedBox(height: 5),
              Text(
                'Tap "+ Add expense" or the + button, enter the amount, choose a category, then save.',
                style: TextStyle(color: kMuted),
              ),
              SizedBox(height: 14),
              Text('How to set a budget'),
              SizedBox(height: 5),
              Text(
                'On Home, tap Edit in the Monthly Budget card and save your limit.',
                style: TextStyle(color: kMuted),
              ),
              SizedBox(height: 14),
              Text('How to see past days'),
              SizedBox(height: 5),
              Text(
                'Tap the history icon on Home to view previous days.',
                style: TextStyle(color: kMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

// ============================================================
// THEME
// ============================================================

ThemeData buildTheme() {
  final ThemeData base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
  );

  final TextTheme text = GoogleFonts.outfitTextTheme(base.textTheme)
      .apply(bodyColor: Colors.white, displayColor: Colors.white);

  final OutlineInputBorder inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Colors.white12),
  );

  return base.copyWith(
    scaffoldBackgroundColor: kBlack,
    canvasColor: kBlueBottom,
    cardColor: kBlueBottom,
    dialogBackgroundColor: kBlueBottom,
    dividerColor: Colors.white12,
    textTheme: text,
    colorScheme: const ColorScheme.dark(
      primary: kBlueTop,
      secondary: kAccent,
      surface: kBlack,
      onSurface: Colors.white,
      onPrimary: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBlueTop,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kBlueTop,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBlueBottom,
      hintStyle: const TextStyle(color: Colors.white54),
      labelStyle: const TextStyle(color: kMuted),
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kBlack,
      surfaceTintColor: Colors.transparent,
      indicatorColor: kBlueTop,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white, fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: Colors.white),
      ),
    ),
  );
}

class PersonalExpenseTracker extends StatelessWidget {
  const PersonalExpenseTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expense Tracker',
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: kBlueGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white12),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: kBlueGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: kBlueGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Personal Expense',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Tracker',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Manage your money. Build your future.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 50),
              const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;

  Future<void> login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showSnack(context, 'Please enter your email and password.');
      return;
    }

    if (!email.contains('@')) {
      showSnack(context, 'Please enter a valid email.');
      return;
    }

    try {
      final result = await AuthApi.login(
        email: email,
        password: password,
      );

      if (AuthApi.accessToken == null || AuthApi.accessToken!.isEmpty) {
        throw Exception('Backend did not return an access token.');
      }

      if (!mounted) return;

      AppData.userEmail = email;
      final user = result['user'];
      if (user is Map && user['name'] != null) {
        AppData.userName = user['name'].toString();
      } else {
        AppData.userName = nameFromEmail(email);
      }

      await AppData.save();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      showSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: kBlueGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to continue managing your expenses.',
                    style: TextStyle(color: kMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 35),
                  const Text('Email',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Password',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showSnack(
                          context, 'Password reset will be available later.'),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: login,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(color: kMuted)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER SCREEN
// ============================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> createAccount() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showSnack(context, 'Please fill all the fields.');
      return;
    }

    if (!email.contains('@')) {
      showSnack(context, 'Please enter a valid email.');
      return;
    }

    if (password.length < 8) {
      showSnack(context, 'Password must contain at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      showSnack(context, 'Passwords do not match.');
      return;
    }

    try {
      await AuthApi.register(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;
      AppData.userName = name;
      AppData.userEmail = email;
      await AppData.save();

      if (!mounted) return;
      showSnack(context, 'Account created successfully! Please log in.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your account and start tracking your money.',
                  style: TextStyle(color: kMuted),
                ),
                const SizedBox(height: 30),
                const Text('Full Name',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Email',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Password',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Confirm Password',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() =>
                          obscureConfirmPassword = !obscureConfirmPassword),
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: createAccount,
                  child: const Text('Create Account'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: TextStyle(color: kMuted)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME SCREEN (top bar + drawer + tabs)
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  void goTo(int index) => setState(() => selectedIndex = index);

  Future<void> openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result == true) setState(() {});
  }

  void showBudgetDialog() {
    final TextEditingController controller = TextEditingController(
      text: AppData.monthlyBudget.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Monthly Budget',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              hintText: 'Enter monthly limit',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
              onPressed: () {
                final double? value =
                    double.tryParse(controller.text.trim());

                if (value == null || value <= 0) {
                  showSnack(context, 'Enter a valid budget amount');
                  return;
                }

                setState(() => AppData.monthlyBudget = value);
                AppData.save();
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------
  // TOP BAR (matches the Savingy layout)
  // ----------------------------------------------------------

  PreferredSizeWidget buildTopBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: kBlueGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.savings_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'SAVINGY',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ElevatedButton.icon(
            onPressed: openAddTransaction,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add expense'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Language dropdown
        PopupMenuButton<String>(
          tooltip: 'Language',
          onSelected: (_) {},
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'en', child: Text('English')),
          ],
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate_rounded, size: 18),
                SizedBox(width: 6),
                Text('English', style: TextStyle(fontSize: 13)),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),

        IconButton(
          tooltip: 'Theme',
          icon: const Icon(Icons.dark_mode_outlined),
          onPressed: () =>
              showSnack(context, 'The app uses a dark theme.'),
        ),
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.help_outline),
          onPressed: () => showHelpDialog(context),
        ),

        // More menu
        PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (value) {
            if (value == 'profile') goTo(4);
            if (value == 'logout') showLogoutDialog(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'profile', child: Text('Profile')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ----------------------------------------------------------
  // DRAWER (opened by the ☰ icon)
  // ----------------------------------------------------------

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: selected ? kAccent : Colors.white),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? kAccent : Colors.white,
        ),
      ),
      selected: selected,
      onTap: onTap,
    );
  }

  Widget buildDrawer() {
    final String initial =
        AppData.userName.isNotEmpty ? AppData.userName[0].toUpperCase() : 'U';

    return Drawer(
      backgroundColor: kBlueBottom,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      gradient: kBlueGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppData.userName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          AppData.userEmail,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            _drawerItem(
              icon: Icons.home_rounded,
              title: 'Home',
              selected: selectedIndex == 0,
              onTap: () {
                Navigator.pop(context);
                goTo(0);
              },
            ),
            _drawerItem(
              icon: Icons.bar_chart_rounded,
              title: 'Analytics',
              selected: selectedIndex == 1,
              onTap: () {
                Navigator.pop(context);
                goTo(1);
              },
            ),
            _drawerItem(
              icon: Icons.add_circle_outline,
              title: 'Add expense',
              onTap: () {
                Navigator.pop(context);
                openAddTransaction();
              },
            ),
            _drawerItem(
              icon: Icons.history_rounded,
              title: 'Expense history',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ).then((_) => setState(() {}));
              },
            ),
            _drawerItem(
              icon: Icons.category_outlined,
              title: 'Categories',
              selected: selectedIndex == 3,
              onTap: () {
                Navigator.pop(context);
                goTo(3);
              },
            ),
            _drawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              selected: selectedIndex == 4,
              onTap: () {
                Navigator.pop(context);
                goTo(4);
              },
            ),
            _drawerItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                showHelpDialog(context);
              },
            ),
            const Spacer(),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: kRed),
              title: const Text(
                'Logout',
                style: TextStyle(color: kRed, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HOME TAB CONTENT
  // ----------------------------------------------------------

  Widget summaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget budgetCard() {
    final double budget = AppData.monthlyBudget;
    final double spent = AppData.monthExpenses;
    final double left = AppData.leftToSpend;

    double progress = budget > 0 ? spent / budget : 0;
    if (progress > 1) progress = 1;

    return AppCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Budget',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: showBudgetDialog, child: const Text('Edit')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${budget.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              const Text('monthly limit', style: TextStyle(color: kMuted)),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              color: left < 0 ? kRed : kAccent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent: ₹${spent.toStringAsFixed(0)}',
                  style: const TextStyle(color: kMuted, fontSize: 13),
                ),
              ),
              Text(
                left >= 0
                    ? 'Left: ₹${left.toStringAsFixed(0)}'
                    : 'Over: ₹${left.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  color: left >= 0 ? kGreen : kRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget emptyTransactions() {
    return const AppCard(
      padding: EdgeInsets.all(30),
      radius: 18,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 45, color: kMuted),
          SizedBox(height: 12),
          Text('No transactions today', style: TextStyle(color: kMuted)),
          SizedBox(height: 5),
          Text(
            'Tap + to add your first transaction.',
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget transactionTile(Map<String, dynamic> transaction) {
    final double amount = transaction['amount'] as double;
    final bool isIncome = amount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        radius: 17,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: transaction['color'],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(transaction['icon'], color: transaction['iconColor']),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction['date'],
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}₹${amount.abs().toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isIncome ? kGreen : kRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting uses the name entered on Register or derived at Login
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greetingNow(),
                        style:
                            const TextStyle(fontSize: 14, color: kMuted)),
                    const SizedBox(height: 3),
                    Text(
                      '${AppData.userName} 👋',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              _SquareIconButton(
                icon: Icons.history_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ).then((_) => setState(() {}));
                },
              ),
              const SizedBox(width: 10),
              _SquareIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => showSnack(context, 'No new notifications.'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SpendOrbCard(
            spentToday: AppData.totalExpenses,
            dailyAllowance: AppData.dailyAllowance,
            recentExpenses: AppData.transactions
                .where((t) => (t['amount'] as double) < 0)
                .toList(),
          ),

          const SizedBox(height: 20),
          budgetCard(),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: summaryCard(
                  title: 'Income',
                  amount: '₹${AppData.totalIncome.toStringAsFixed(0)}',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: kGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: summaryCard(
                  title: 'Expenses',
                  amount: '₹${AppData.totalExpenses.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward_rounded,
                  iconColor: kRed,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ).then((_) => setState(() {}));
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (AppData.transactions.isEmpty)
            emptyTransactions()
          else
            ...AppData.transactions.map(transactionTile),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppData.checkNewDay();

    final List<Widget> pages = [
      buildHomePage(),
      const AnalyticsScreen(),
      const SizedBox(),
      const CategoriesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: buildTopBar(),
      drawer: buildDrawer(),
      body: SafeArea(top: false, child: pages[selectedIndex]),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              onPressed: openAddTransaction,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            openAddTransaction();
            return;
          }
          goTo(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD TRANSACTION SCREEN
// ============================================================

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isExpense = true;
  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.restaurant_rounded,
      'color': Color(0xFFFFE4EA), 'iconColor': Color(0xFFE94B72)},
    {'name': 'Transport', 'icon': Icons.directions_bus_rounded,
      'color': Color(0xFFE5F1FF), 'iconColor': Color(0xFF3D82D8)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFFFF1D9), 'iconColor': Color(0xFFE99A2B)},
    {'name': 'Bills', 'icon': Icons.receipt_long_rounded,
      'color': Color(0xFFEDE6FF), 'iconColor': Color(0xFF7654BE)},
    {'name': 'Health', 'icon': Icons.favorite_rounded,
      'color': Color(0xFFFFE4E4), 'iconColor': Color(0xFFE34D4D)},
    {'name': 'Entertainment', 'icon': Icons.movie_rounded,
      'color': Color(0xFFE7E4FF), 'iconColor': Color(0xFF6755C9)},
    {'name': 'Education', 'icon': Icons.school_rounded,
      'color': Color(0xFFE2F5FF), 'iconColor': Color(0xFF3189B8)},
    {'name': 'Travel', 'icon': Icons.flight_rounded,
      'color': Color(0xFFE4F7EF), 'iconColor': Color(0xFF2AA968)},
    {'name': 'Others', 'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFEDEDED), 'iconColor': Color(0xFF666666)},
  ];

  String formattedDate() {
    return '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  Future<void> addTransaction() async {
    final String text = amountController.text.trim();

    if (text.isEmpty) {
      showSnack(context, 'Please enter an amount');
      return;
    }

    final double? amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      showSnack(context, 'Please enter a valid amount');
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime when = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
    );

    AppData.addTransaction(
      name: selectedCategory,
      amount: isExpense ? -amount : amount,
      time: when,
    );

    await AppData.save();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _typeChip(
      String label, bool selected, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : kMuted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                padding: const EdgeInsets.all(5),
                radius: 15,
                child: Row(
                  children: [
                    _typeChip('Expense', isExpense, kBlueTop,
                        () => setState(() => isExpense = true)),
                    _typeChip('Income', !isExpense, const Color(0xFF16A34A),
                        () => setState(() => isExpense = false)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text('Amount',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 22),

              const Text('Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                radius: 16,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    dropdownColor: kBlueBottom,
                    style: const TextStyle(color: Colors.white),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'],
                        child: Row(
                          children: [
                            Icon(category['icon'],
                                color: category['iconColor'], size: 22),
                            const SizedBox(width: 12),
                            Text(category['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCategory = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 22),

              const Text('Date',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: selectDate,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 17),
                  radius: 16,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: kAccent),
                      const SizedBox(width: 12),
                      Text(formattedDate(),
                          style: const TextStyle(fontSize: 15)),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration:
                    const InputDecoration(hintText: 'Add a note (optional)'),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: addTransaction,
                child: Text(isExpense ? 'Add Expense' : 'Add Income'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ANALYTICS SCREEN
// ============================================================

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double budget = AppData.monthlyBudget;
    final double spent = AppData.monthExpenses;

    double progress = budget > 0 ? spent / budget : 0;
    if (progress > 1) progress = 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Understand where your money goes.',
              style: TextStyle(color: kMuted)),
          const SizedBox(height: 25),

          AppCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Month',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 20,
                            backgroundColor: Colors.white12,
                            color: kAccent,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${spent.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const Text('Spent',
                                style: TextStyle(color: kMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Budget', style: TextStyle(color: kMuted)),
                    Text('₹${budget.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Left to Spend',
                        style: TextStyle(color: kMuted)),
                    Text(
                      '₹${AppData.leftToSpend.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppData.leftToSpend >= 0 ? kGreen : kRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
          const Text('Top Categories',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),

          _analyticsTile('Shopping', '₹1,200',
              Icons.shopping_bag_rounded, const Color(0xFFE99A2B)),
          _analyticsTile('Food', '₹950',
              Icons.restaurant_rounded, const Color(0xFFE94B72)),
          _analyticsTile('Transport', '₹720',
              Icons.directions_bus_rounded, const Color(0xFF3D82D8)),
          _analyticsTile('Entertainment', '₹650',
              Icons.movie_rounded, const Color(0xFF6755C9)),
        ],
      ),
    );
  }

  Widget _analyticsTile(
      String title, String amount, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(15),
        radius: 16,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORIES SCREEN
// ============================================================

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFE94B72)},
    {'name': 'Transport', 'icon': Icons.directions_bus_rounded, 'color': Color(0xFF3D82D8)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFFE99A2B)},
    {'name': 'Bills', 'icon': Icons.receipt_long_rounded, 'color': Color(0xFF7654BE)},
    {'name': 'Health', 'icon': Icons.favorite_rounded, 'color': Color(0xFFE34D4D)},
    {'name': 'Entertainment', 'icon': Icons.movie_rounded, 'color': Color(0xFF6755C9)},
    {'name': 'Education', 'icon': Icons.school_rounded, 'color': Color(0xFF3189B8)},
    {'name': 'Travel', 'icon': Icons.flight_rounded, 'color': Color(0xFF2AA968)},
    {'name': 'Others', 'icon': Icons.more_horiz_rounded, 'color': Color(0xFF999999)},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Categories',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Choose a category for your transactions.',
              style: TextStyle(color: kMuted)),
          const SizedBox(height: 25),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return AppCard(
                padding: const EdgeInsets.all(8),
                radius: 18,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(category['icon'],
                          color: category['color'], size: 25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      category['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE SCREEN
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void showEditProfile() {
    final nameController = TextEditingController(text: AppData.userName);
    final emailController = TextEditingController(text: AppData.userEmail);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty) {
                  showSnack(context, 'Please fill all fields.');
                  return;
                }
                setState(() {
                  AppData.userName = nameController.text.trim();
                  AppData.userEmail = emailController.text.trim();
                });
                Navigator.pop(dialogContext);
                showSnack(context, 'Profile updated successfully!');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showNotifications() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool enabled = AppData.notificationsEnabled;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Notifications'),
              content: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expense reminders'),
                subtitle: const Text('Receive notification reminders.',
                    style: TextStyle(color: kMuted)),
                value: enabled,
                onChanged: (value) {
                  setDialogState(() => enabled = value);
                  AppData.notificationsEnabled = value;
                  setState(() {});
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showInfoDialog(String title, Widget content) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showChangePassword() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
              onPressed: () {
                if (oldController.text.isEmpty ||
                    newController.text.isEmpty ||
                    confirmController.text.isEmpty) {
                  showSnack(context, 'Please fill all fields.');
                  return;
                }
                if (newController.text != confirmController.text) {
                  showSnack(context, 'New passwords do not match.');
                  return;
                }
                Navigator.pop(dialogContext);
                showSnack(context, 'Password changed successfully!');
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  Widget profileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        radius: 16,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: iconColor ?? kAccent),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: trailing ??
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: kMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              gradient: kBlueGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                size: 48, color: Colors.white),
          ),
          const SizedBox(height: 15),
          Text(
            AppData.userName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(AppData.userEmail, style: const TextStyle(color: kMuted)),
          const SizedBox(height: 30),

          profileOption(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: showEditProfile,
          ),
          profileOption(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: showNotifications,
            trailing: Icon(
              AppData.notificationsEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: AppData.notificationsEnabled ? kAccent : kMuted,
            ),
          ),
          profileOption(
            icon: Icons.lock_outline,
            title: 'Privacy & Security',
            onTap: () => showInfoDialog(
              'Privacy & Security',
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Your personal expense data is saved on this device only.'),
                  SizedBox(height: 14),
                  Text(
                      'Backend and secure database storage will be connected in the next stage of the project.'),
                  SizedBox(height: 14),
                  Text('Never share your password with anyone.'),
                ],
              ),
            ),
          ),
          profileOption(
            icon: Icons.password_rounded,
            title: 'Change Password',
            onTap: showChangePassword,
          ),
          profileOption(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => showHelpDialog(context),
          ),

          const SizedBox(height: 12),

          const MonthlyReportButton(),

          const SizedBox(height: 20),

          profileOption(
            icon: Icons.logout_rounded,
            title: 'Logout',
            iconColor: kRed,
            onTap: () => showLogoutDialog(context),
          ),
        ],
      ),
    );
  }
}