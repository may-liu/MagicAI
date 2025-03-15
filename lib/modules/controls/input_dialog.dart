import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<String?> showInputPrompt({
  required BuildContext context,
  String title = "输入名称",
  String placeholder = "请输入名称...",
}) async {
  final textController = TextEditingController();

  return await showDialog(
    context: context,
    builder:
        (context) =>
            Platform.isIOS
                ? CupertinoAlertDialog(
                  title: Text(title),
                  content: CupertinoTextField(
                    controller: textController,
                    placeholder: placeholder,
                    keyboardType: TextInputType.name,
                  ),
                  actions: <Widget>[
                    CupertinoDialogAction(
                      child: const Text('取消'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('确认'),
                      onPressed: () {
                        Navigator.pop(context, textController.text);
                      },
                    ),
                  ],
                )
                : AlertDialog(
                  title: Text(title),
                  content: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.name,
                  ),
                  actions: [
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      child: const Text('确认'),
                      onPressed: () {
                        Navigator.pop(context, textController.text);
                      },
                    ),
                  ],
                ),
  );
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '输入示例',
      theme: ThemeData.light(), // 使用系统默认主题
      darkTheme: ThemeData.dark(),
      home: InputExamplePage(),
    );
  }
}

class InputExamplePage extends StatefulWidget {
  const InputExamplePage({super.key});

  @override
  State<StatefulWidget> createState() => _InputExamplePageState();
}

class _InputExamplePageState extends State<InputExamplePage> {
  String userInput = "未输入";

  Future<void> _showInputDialog() async {
    final result = await showInputPrompt(
      context: context,
      title: "请输入您的名称",
      placeholder: "例如：张三",
    );

    if (result != null) {
      setState(() {
        userInput = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("输入框示例")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _showInputDialog, child: Text("点击输入名称")),
            SizedBox(height: 20),
            Text(
              "当前输入值：$userInput",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
