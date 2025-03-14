import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'dart:io' show Platform;
import 'package:magicai/entity/file_node.dart';
import 'package:magicai/screens/chat_detail_main.dart';
import 'package:magicai/screens/chat_list_main.dart';
import 'package:magicai/screens/widgets/config/adaptive_settings_dialog.dart';
import 'package:magicai/screens/widgets/config/config_item.dart';
import 'package:magicai/screens/widgets/highlighter_manager.dart';
import 'package:magicai/services/system_manager.dart';

late FileNode _globalNode;

void main() async {
  // debugPaintLayerBordersEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  await SystemManager.initialize();
  _globalNode = await FileNode.fromDirectory(SystemManager.instance.topicRoot);
  await HighlighterManager.ensureInitialized(true);
  runApp(const MagicAIApp());
}

class MagicAIApp extends StatefulWidget {
  const MagicAIApp({super.key});
  @override
  State<MagicAIApp> createState() => _MagicAIAppState();
}

class _MagicAIAppState extends State<MagicAIApp> {
  bool _isDarkMode = true;
  bool _testvalue = false;
  late List<ConfigItem> settingsItems;

  @override
  void initState() {
    settingsItems = [
      SectionHeaderItem(title: '外观设置'),
      ThemeConfigItem(
        title: '深色模式',
        icon: Icons.dark_mode_outlined,
        isDarkMode: _isDarkMode,
        onThemeChanged: (value) => setState(() => _isDarkMode = value),
      ),
      SectionHeaderItem(title: "模型配置"),
      NavigationConfigItem(
        title: '隐私设置',
        icon: Icons.lock_outline,
        childWidget: AboutDialog.adaptive(),
      ),
      SwitchConfigItem(
        title: "switch 测试",
        icon: Icons.abc,
        value: _testvalue,
        onChanged: (v) => setState(() => _testvalue = v),
      ),
      // 添加更多配置项...
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MagicAI',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AdaptiveHomePage(settingsItems: settingsItems),
    );
  }
}

class AdaptiveHomePage extends StatefulWidget {
  final List<ConfigItem> settingsItems;
  // bool isDarkMode;
  // final ValueChanged<bool> onThemeChanged;

  AdaptiveHomePage({
    super.key,
    required this.settingsItems,
    // required this.isDarkMode,
    // required this.onThemeChanged,
  });

  @override
  State<AdaptiveHomePage> createState() => _AdaptiveHomePageState();
}

class _AdaptiveHomePageState extends State<AdaptiveHomePage> {
  bool get isDesktop {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useDesktopLayout = isDesktop || screenWidth >= 600;

    return useDesktopLayout
        ? DesktopLayout(settingsItems: widget.settingsItems)
        : MobileLayout(settingsItems: widget.settingsItems);
  }
}

class DesktopLayout extends StatefulWidget {
  final List<ConfigItem> settingsItems;

  const DesktopLayout({super.key, required this.settingsItems});
  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  final double _sidebarWidth = 60;
  bool _sidebarVisible = true;
  double _chatListWidth = 300;
  void _toggleSidebar() {
    setState(() => _sidebarVisible = !_sidebarVisible);
  }

  void _updateThemeMode(ThemeMode mode) {}

  void _updateLayout(double delta) {
    double maxWidth = MediaQuery.of(context).size.width - _sidebarWidth;
    setState(() {
      _chatListWidth += delta;
      _chatListWidth = _chatListWidth.clamp(150, maxWidth * 0.85);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_sidebarVisible ? Icons.menu_open : Icons.menu),
          onPressed: _toggleSidebar,
        ),
        title: const Text('MagicAI Desktop'),
      ),
      body: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: _sidebarVisible ? _sidebarWidth : 0,
              child:
                  _sidebarVisible
                      ? SideBar(
                        width: _sidebarWidth,
                        settingsItems: widget.settingsItems,
                      )
                      : const SizedBox.shrink(),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                _updateLayout(details.delta.dx);
              },
              child: const VerticalDivider(width: 4),
            ),
          ),
          SizedBox(
            width: _chatListWidth,
            child: ChatFileList(
              onFileSelected: (String filePath) {
                SystemManager.instance.changeCurrentFile(filePath);
              },
              topicRoot: SystemManager.instance.topicRoot,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                _updateLayout(details.delta.dx);
              },
              child: const VerticalDivider(width: 4),
            ),
          ),
          Expanded(
            flex: 2,
            child: ChatScreen(
              updateThemeMode: (p0) => _updateThemeMode,
              currentThemeMode: ThemeMode.system,
            ),
          ),
        ],
      ),
    );
  }
}

class StatelessDesktopLayout extends StatelessWidget {
  final List<ConfigItem> settingsItems;
  const StatelessDesktopLayout({super.key, required this.settingsItems});

  void _updateThemeMode(ThemeMode mode) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideBar(width: 72, settingsItems: settingsItems),
          const VerticalDivider(width: 4),
          Expanded(
            child: ChatFileList(
              onFileSelected: (String filePath) {},
              topicRoot: SystemManager.instance.topicRoot,
            ),
          ),
          const VerticalDivider(width: 4),
          Expanded(
            flex: 2,
            child: ChatScreen(
              updateThemeMode: (p0) => _updateThemeMode,
              currentThemeMode: ThemeMode.system,
            ),
          ),
        ],
      ),
    );
  }
}

class MobileLayout extends StatefulWidget {
  final List<ConfigItem> settingsItems;
  const MobileLayout({super.key, required this.settingsItems});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Chat? _selectedChat;

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SideBar(width: 280, settingsItems: widget.settingsItems),
      ),
      body: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) {
              if (settings.name == '/chat') {
                return Scaffold(
                  body: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! > 200) {
                        _navigatorKey.currentState!.pop();
                      }
                    },
                    child: ChatDetail(
                      chat: _selectedChat,
                      onBack: () => _navigatorKey.currentState!.pop(),
                    ),
                  ),
                );
              }
              return Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _openDrawer,
                  ),
                  title: const Text('Chats'),
                ),
                body: ChatFileList(
                  onFileSelected: (String filePath) {},
                  topicRoot: SystemManager.instance.topicRoot,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SideBar extends StatelessWidget {
  final List<ConfigItem> settingsItems;
  final double width;

  const SideBar({super.key, required this.width, required this.settingsItems});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          IconButton(icon: const Icon(Icons.message), onPressed: () {}),
          IconButton(icon: const Icon(Icons.contacts), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showSettings(context, settingsItems);
            },
          ),
        ],
      ),
    );
  }
}

class ChatDetail extends StatelessWidget {
  final Chat? chat;
  final VoidCallback? onBack;

  const ChatDetail({super.key, this.chat, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(chat?.name ?? 'Select a chat'),
      ),
      body:
          chat == null
              ? const Center(child: Text('Select a chat to start'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: chat!.messages.length,
                      itemBuilder: (context, index) {
                        final message = chat!.messages[index];
                        return ChatMessageWidget(message: message);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final Message message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              message.isMe
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.content),
      ),
    );
  }
}

// Data models
class Chat {
  final String name;
  final String lastMessage;
  final String time;
  final List<Message> messages;

  Chat({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.messages,
  });
}

class Message {
  final String content;
  final DateTime time;
  final bool isMe;

  Message({required this.content, required this.time, required this.isMe});
}

// Demo data
final demoChats = [
  Chat(
    name: 'John Doe',
    lastMessage: 'Hello there!',
    time: '10:30',
    messages: [
      Message(content: 'Hello there!', time: DateTime.now(), isMe: false),
      Message(content: 'Hi! How are you?', time: DateTime.now(), isMe: true),
    ],
  ),
  Chat(
    name: 'Alice Smith',
    lastMessage: 'See you tomorrow',
    time: '09:45',
    messages: [
      Message(content: 'Meeting at 3pm', time: DateTime.now(), isMe: false),
      Message(content: 'Got it, thanks!', time: DateTime.now(), isMe: true),
    ],
  ),
];
