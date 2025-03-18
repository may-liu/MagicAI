import 'package:flutter/material.dart';

import 'config_item.dart';
import 'config_statement_core.dart';

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
  const HomePage({super.key});

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
              () => showAdaptiveDialog(context, [
                ThemeConfigItem(
                  // 正确绑定回调和状态
                  title: '深色模式',
                  icon: Icons.dark_mode_outlined,
                  isDarkMode: _isDarkMode, // ← 绑定到本地变量
                  onThemeChanged: _handleThemeChange, // ← 使用有效方法
                ),
                NavigationConfigItem(
                  title: "title",
                  icon: Icons.ac_unit,
                  childWidget: AdaptiveSettingsDialog(
                    items: [
                      NavigationConfigItem(
                        title: "title",
                        icon: Icons.ac_unit,
                        childWidget: AdaptiveSettingsDialog(items: []),
                      ),
                    ],
                  ),
                ),
              ]),
          child: const Text('打开设置'),
        ),
      ),
    );
  }
}

// 核心弹窗组件
class AdaptiveSettingsDialog extends StatelessWidget {
  final List<ConfigItem> items;

  const AdaptiveSettingsDialog({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isDesktop =
            constraints.maxWidth > 600 ||
            [
              TargetPlatform.windows,
              TargetPlatform.macOS,
              TargetPlatform.linux,
            ].contains(Theme.of(context).platform);

        return isDesktop
            ? _DesktopLayout(items: items)
            : _MobileLayout(items: items);
      },
    );
  }
}

// 桌面布局（带导航抽屉）
class _DesktopLayout extends StatelessWidget {
  final List<ConfigItem> items;

  const _DesktopLayout({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 导航抽屉
        // Container(
        //   width: 240,
        //   decoration: BoxDecoration(
        //     border: Border(right: BorderSide(color: Colors.grey.shade300)),
        //   ),
        //   child: ListView.builder(
        //     itemCount: items.length,
        //     itemBuilder:
        //         (_, index) => ListTile(
        //           title: Text(items[index].title),
        //           onTap: () => _navigateToDetail(context, items[index]),
        //         ),
        //   ),
        // ),

        // 主内容区域（嵌套导航器）
        Expanded(
          child: Navigator(
            onGenerateRoute:
                (_) => MaterialPageRoute(
                  builder:
                      (_) => //_MainContent(item: items.first),
                      //   Container(
                      // width: 600,
                      // height: 600,
                      // decoration: BoxDecoration(
                      //   color: Theme.of(context).colorScheme.surface,
                      //   borderRadius: BorderRadius.circular(12),
                      //   boxShadow: kElevationToShadow[6],
                      // ),
                      WillPopScope(
                        onWillPop: () async {
                          if (!Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(); // 关闭整个Dialog
                          }
                          return true;
                        },
                        child:
                        // Scaffold(
                        //   appBar: CustomAppBar(),
                        //   body:
                        Column(
                          children: [
                            _buildTitleBar(context),
                            Expanded(child: SettingsStateList(items: items)),
                          ],
                        ),
                        // ),
                      ),
                ),
          ),
        ),
      ],
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

  void _navigateToDetail(BuildContext context, ConfigItem item) {
    Navigator.of(
      context,
    ).push(_SlideRightRoute(child: _MainContent(item: item)));
  }
}

// 移动端全屏布局
class _MobileLayout extends StatelessWidget {
  final List<ConfigItem> items;

  const _MobileLayout({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder:
          (_, index) => ListTile(
            title: Text(items[index].title),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _MainContent(item: items[index]),
                  ),
                ),
          ),
    );
  }
}

// 内容页组件
class _MainContent extends StatelessWidget {
  final ConfigItem item;

  const _MainContent({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// 自定义右侧滑入路由
class _SlideRightRoute extends PageRouteBuilder {
  final Widget child;

  _SlideRightRoute({required this.child})
    : super(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      );
}

// 统一弹窗调用方法
void showAdaptiveDialog(BuildContext context, List<ConfigItem> items) {
  final isDesktop = [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ].contains(Theme.of(context).platform);

  if (isDesktop) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: SizedBox(
              width: 800,
              height: 600,
              child: AdaptiveSettingsDialog(items: items),
            ),
          ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: const Text('设置')),
              body: AdaptiveSettingsDialog(items: items),
            ),
      ),
    );
  }
}

// // 使用示例
// class DemoPage extends StatelessWidget {
//   final List<ConfigItem> demoItems = [
//     ThemeConfigItem(
//       // 正确绑定回调和状态
//       title: '深色模式',
//       icon: Icons.dark_mode_outlined,
//       isDarkMode: _isDarkMode, // ← 绑定到本地变量
//       onThemeChanged: _handleThemeChange, // ← 使用有效方法
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('主界面')),
//       body: Center(
//         child: ElevatedButton(
//           child: const Text('打开设置'),
//           onPressed: () => showAdaptiveDialog(context, demoItems),
//         ),
//       ),
//     );
//   }
// }
