import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/master_data_provider.dart';
import 'providers/tagihan_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OperasionalApp());
}

class OperasionalApp extends StatelessWidget {
  const OperasionalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => MasterDataProvider()),
        ChangeNotifierProvider(create: (_) => TagihanProvider()),
      ],
      child: MaterialApp(
        title: 'Tagihan Air Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await context.read<AuthProvider>().checkAuth();
    if (mounted) setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop_rounded,
                    size: 60, color: Colors.white),
                SizedBox(height: 16),
                CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
