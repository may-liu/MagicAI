import 'package:flutter/material.dart';
import 'package:magicai/screens/widgets/config/config_core.dart';
import 'package:magicai/screens/widgets/config/config_item.dart';

void main() => runApp(const SettingsApp());

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});
  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  bool _isDarkMode = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(Brightness.light),
      darkTheme: _buildThemeData(Brightness.dark),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SettingsPageExample(
        isDarkMode: _isDarkMode,
        onThemeChanged: (value) => setState(() => _isDarkMode = value),
      ),
    );
  }

  ThemeData _buildThemeData(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
    );
  }
}

class SettingsPageExample extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  const SettingsPageExample({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPageExample> createState() => _SettingsPageExampleState();
}

class _SettingsPageExampleState extends State<SettingsPageExample> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final items = [
      SectionHeaderItem(title: '外观设置'),
      ThemeConfigItem(
        title: '深色模式',
        icon: Icons.dark_mode_outlined,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),

      SectionHeaderItem(title: '通知设置'),
      SwitchConfigItem(
        title: '启用通知',
        icon: Icons.notifications_active_outlined,
        value: _notificationsEnabled,
        onChanged: (v) => setState(() => _notificationsEnabled = v),
      ),

      SectionHeaderItem(title: '账户设置'),
      NavigationConfigItem(
        title: '隐私设置',
        icon: Icons.lock_outline,
        onTap: () => _navigateToPrivacy(context), // 传递正确的context
      ),

      InputConfigItem(
        title: '邮箱',
        icon: Icons.email,
        value: 'user@example.com',
        onChanged: (v) => print('Email changed: $v'),
        validator: (value) {
          if (value?.isEmpty ?? true) return '必填字段';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
            return '邮箱格式不正确';
          }
          return null;
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: false,
        elevation: 0.5,
      ),
      body: SettingsList(items: items),
    );
  }

  void _navigateToPrivacy(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PrivacySettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _buildIOSSlideTransition(animation, secondaryAnimation, child);
          // if (isIOS) {
          //   return _buildIOSSlideTransition(
          //     animation,
          //     secondaryAnimation,
          //     child,
          //   );
          // } else {
          //   return _buildAndroidFadeTransition(animation, child);
          // }
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildIOSSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.0),
          end: Offset.zero,
        ).animate(secondaryAnimation),
        child: child,
      ),
    );
  }

  Widget _buildAndroidFadeTransition(
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私设置')),
      body: SettingsList(
        items: [
          SwitchConfigItem(
            title: '已读回执',
            icon: Icons.check_circle_outline,
            value: true,
            onChanged: (v) {},
          ),
          InfoConfigItem(title: '最后在线', icon: Icons.access_time, value: '所有人'),
        ],
      ),
    );
  }
}
