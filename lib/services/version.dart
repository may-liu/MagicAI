import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

final String _checkVersionUrl =
    'https://api.github.com/repos/may-liu/MagicAI/releases/latest';

final String _updateVersionUrl =
    'https://github.com/may-liu/MagicAI/releases/latest';

void main() {
  runApp(MyApp());
}

Future<String> getLatestVersion() async {
  final url = Uri.parse(_checkVersionUrl);
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return json['tag_name'] as String;
  } else {
    throw Exception('Failed to fetch latest version');
  }
}

Future<String> getCurrentVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

bool hasUpdate(String currentVersion, String githubVersion) {
  final current = currentVersion.split('.').map(int.parse).toList();
  final latest =
      githubVersion.replaceAll('v', '').split('.').map(int.parse).toList();
  for (int i = 0; i < 3; i++) {
    if (latest[i] > current[i]) return true;
    if (latest[i] < current[i]) return false;
  }
  return false;
}

void showUpdateDialog(
  BuildContext context,
  String currentVersion,
  String latestVersion,
) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text('新版本可用'),
          content: Text('当前版本：$currentVersion\n最新版本：$latestVersion'),
          actions: [
            TextButton(
              onPressed: () {
                launchUrl(Uri.parse(_updateVersionUrl));
              },
              child: Text('立即更新'),
            ),
          ],
        ),
  );
}

Future<void> checkForUpdates(BuildContext context) async {
  try {
    final currentVersion = await getCurrentVersion();
    final latestVersion = await getLatestVersion();
    if (hasUpdate(currentVersion, latestVersion)) {
      if (context.mounted) {
        showUpdateDialog(context, currentVersion, latestVersion);
      }
    }
  } catch (e) {
    debugPrint('检查更新失败：$e');
  } finally {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '版本更新检测',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UpdateCheckerPage(),
    );
  }
}

class UpdateCheckerPage extends StatefulWidget {
  const UpdateCheckerPage({super.key});

  @override
  State<StatefulWidget> createState() => _UpdateCheckerPageState();
}

class _UpdateCheckerPageState extends State<UpdateCheckerPage> {
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    checkForUpdates(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('版本检测')),
      body: Center(
        child:
            isChecking
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: () {
                    checkForUpdates(context);
                  },
                  child: Text('检查更新'),
                ),
      ),
    );
  }
}
