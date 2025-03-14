import 'package:flutter/material.dart';

import 'config_statement_core.dart';
import 'config_item.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '跨平台配置组件',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

// 修改 HomePage 类定义
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDarkMode = false; // 新增状态变量

  void _handleThemeChange(bool newValue) {
    setState(() {
      _isDarkMode = newValue; // 更新本地状态
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: ElevatedButton(
          onPressed:
              () => showSettings(context, [
                ThemeConfigItem(
                  // 正确绑定回调和状态
                  title: '深色模式',
                  icon: Icons.dark_mode_outlined,
                  isDarkMode: _isDarkMode, // ← 绑定到本地变量
                  onThemeChanged: _handleThemeChange, // ← 使用有效方法
                ),
              ]),
          child: const Text('打开设置'),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final List<ConfigItem> items;
  const SettingsPage({super.key, required this.items});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<ConfigItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SettingsStateList(items: _items),
    );
  }
}

// 自适应的设置对话框
class AdaptiveSettingsDialog extends StatefulWidget {
  final List<ConfigItem> items;
  const AdaptiveSettingsDialog({super.key, required this.items});

  @override
  State<StatefulWidget> createState() => _AdaptiveSettingsDialogState();
}

class _AdaptiveSettingsDialogState extends State<AdaptiveSettingsDialog> {
  bool _isDesktopPlatform(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktopPlatform(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child:
          isDesktop
              ? _DesktopSettingsPanel(items: widget.items)
              : _MobileSettingsPanel(items: widget.items),
    );
  }
}

// 移动端面板
class _MobileSettingsPanel extends StatefulWidget {
  final List<ConfigItem> items;
  const _MobileSettingsPanel({required this.items});

  @override
  State<StatefulWidget> createState() => __MobileSettingsPanelState();
}

class __MobileSettingsPanelState extends State<_MobileSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        children: [
          AppBar(
            title: const Text('设置'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(child: SettingsStateList(items: widget.items)),
        ],
      ),
    );
  }
}

// 桌面端面板
class _DesktopSettingsPanel extends StatefulWidget {
  final List<ConfigItem> items;
  const _DesktopSettingsPanel({required this.items});

  @override
  State<StatefulWidget> createState() => __DesktopSettingsPanelState();
}

class __DesktopSettingsPanelState extends State<_DesktopSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 600,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kElevationToShadow[6],
      ),
      child: Column(
        children: [
          _buildTitleBar(context),
          Expanded(child: SettingsStateList(items: widget.items)),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text('系统设置', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

void showSettings(BuildContext context, List<ConfigItem> settingsItems) {
  if (Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.android) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(items: settingsItems),
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveSettingsDialog(items: settingsItems);
          },
        );
      },
      // (context) => AdaptiveSettingsDialog(items: settingsItems),
    );
  }
}
