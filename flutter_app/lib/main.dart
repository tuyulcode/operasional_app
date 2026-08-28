import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/master_data_provider.dart';
import 'providers/tagihan_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
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
        // Splash yang nge-handle cek status login (auth) di baliknya,
        // baru navigate ke LoginScreen atau MainShell.
        home: const SplashScreen(),
      ),
    );
  }
}