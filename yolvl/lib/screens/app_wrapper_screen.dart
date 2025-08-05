import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/daily_login_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/daily_login_dialog.dart';
import 'main_navigation_screen.dart';

/// App wrapper screen that integrates daily login system with main app
/// 
/// This wrapper screen handles the daily login flow and shows the daily login
/// dialog when appropriate, then displays the main navigation screen.
class AppWrapperScreen extends StatefulWidget {
  const AppWrapperScreen({super.key});

  @override
  State<AppWrapperScreen> createState() => _AppWrapperScreenState();
}

class _AppWrapperScreenState extends State<AppWrapperScreen>
    with WidgetsBindingObserver {
  bool _hasShownDailyLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyLogin();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Check for daily login when app comes to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkDailyLogin();
        }
      });
    }
  }

  Future<void> _checkDailyLogin() async {
    if (_hasShownDailyLogin) return;

    final dailyLoginProvider = context.read<DailyLoginProvider>();
    final userProvider = context.read<UserProvider>();

    // Ensure providers are initialized
    if (!dailyLoginProvider.canLoginToday || userProvider.currentUser == null) {
      return;
    }

    _hasShownDailyLogin = true;

    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      await _showDailyLoginDialog();
    }
  }

  Future<void> _showDailyLoginDialog() async {
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DailyLoginDialog(showOnStartup: true),
      );
    } catch (e) {
      debugPrint('Error showing daily login dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DailyLoginProvider, UserProvider>(
      builder: (context, dailyLoginProvider, userProvider, child) {
        // Show main navigation screen
        return const MainNavigationScreen();
      },
    );
  }
}