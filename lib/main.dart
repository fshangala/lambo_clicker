import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'view_models/app_view_model.dart';
import 'views/mobile_home.dart';
import 'views/desktop_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appViewModel = AppViewModel();
  await appViewModel.initialize();
  runApp(LamboClickerApp(appViewModel: appViewModel));
}

class LamboClickerApp extends StatelessWidget {
  const LamboClickerApp({super.key, required this.appViewModel});

  final AppViewModel appViewModel;

  @override
  Widget build(BuildContext context) {
    final isMobile = defaultTargetPlatform == TargetPlatform.android;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppViewModel>(create: (_) => appViewModel),
      ],
      child: MaterialApp(
        title: 'Lambo Clicker',
        theme: AppTheme.light,
        home: isMobile ? const MobileHome() : const DesktopHome(),
      ),
    );
  }
}
