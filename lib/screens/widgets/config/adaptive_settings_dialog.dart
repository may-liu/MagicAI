import 'package:flutter/material.dart';
import 'package:magicai/screens/widgets/config/config_statement_core.dart';

import 'config_core.dart';
import 'config_item.dart';

import 'package:flutter/foundation.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '跨平台配置组件',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: ElevatedButton(
          child: const Text('打开设置'),
          onPressed:
              () => showSettings(context, [
                SectionHeaderItem(title: '外观设置'),
                ThemeConfigItem(
                  title: '深色模式',
                  icon: Icons.dark_mode_outlined,
                  isDarkMode: false,
                  onThemeChanged: (value) => {},
                ),
                // 添加更多配置项...
              ]),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final List<ConfigItem> items;
  const SettingsPage({super.key, required this.items});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SettingsList(items: items),
    );
  }
}

// 自适应的设置对话框
class AdaptiveSettingsDialog extends StatelessWidget {
  final List<ConfigItem> items;
  const AdaptiveSettingsDialog({super.key, required this.items});
  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktopPlatform(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child:
          isDesktop
              ? _DesktopSettingsPanel(items: items)
              : _MobileSettingsPanel(items: items),
    );
  }

  bool _isDesktopPlatform(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }
}

// 移动端面板
class _MobileSettingsPanel extends StatelessWidget {
  final List<ConfigItem> items;
  const _MobileSettingsPanel({required this.items});
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
          Expanded(child: SettingsStateList(items: items)),
        ],
      ),
    );
  }
}

// 桌面端面板
class _DesktopSettingsPanel extends StatelessWidget {
  final List<ConfigItem> items;
  const _DesktopSettingsPanel({required this.items});
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
          Expanded(child: SettingsStateList(items: items)),
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

// // 核心设置列表组件
// class SettingsList extends StatelessWidget {
//   final List<dynamic> items;
//   final ScrollController? scrollController;
//   const SettingsList({super.key, required this.items, this.scrollController});
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       controller: scrollController,
//       itemCount: items.length,
//       itemBuilder:
//           (context, index) => _SettingsListItem(
//             item: items[index],
//             isDesktop: _isDesktopPlatform(context),
//           ),
//     );
//   }

//   bool _isDesktopPlatform(BuildContext context) {
//     final platform = Theme.of(context).platform;
//     return platform == TargetPlatform.windows ||
//         platform == TargetPlatform.macOS ||
//         platform == TargetPlatform.linux;
//   }
// }

// // 列表项组件
// class _SettingsListItem extends StatelessWidget {
//   final ConfigItem item;
//   final bool isDesktop;
//   const _SettingsListItem({required this.item, required this.isDesktop});
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return MergeSemantics(
//       child: ListTile(
//         leading: _buildLeading(theme),
//         title: Text(item.title),
//         subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
//         trailing: _buildTrailing(theme),
//         // onTap: item.onTap,
//         tileColor: _getTileColor(theme),
//         shape: _getTileShape(),
//       ),
//     );
//   }

//   Widget _buildLeading(ThemeData theme) {
//     return Icon(item.icon, color: item.iconColor ?? theme.colorScheme.primary);
//   }

//   Widget _buildTrailing(ThemeData theme) {
//     if (item is SwitchConfigItem) {
//       final switchItem = item as SwitchConfigItem;
//       return Switch(value: switchItem.value, onChanged: switchItem.onChanged);
//     }
//     return const SizedBox.shrink();
//   }

//   Color? _getTileColor(ThemeData theme) {
//     return isDesktop ? theme.colorScheme.surface : null;
//   }

//   ShapeBorder? _getTileShape() {
//     return isDesktop
//         ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
//         : null;
//   }
// }

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
      builder: (context) => AdaptiveSettingsDialog(items: settingsItems),
    );
  }
}
