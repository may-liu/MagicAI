import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

// Example code.
const _code = '''class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syntax Highlight Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}''';

const _serverpodYaml = '''
class: Customer
table: customer
fields:
  name: String
  orders: List<Order>?, relation
''';

const _json = '{"name":"John", "age":30, "car":null}';

late final Highlighter _dartLightHighlighter;
late final Highlighter _dartDarkHighlighter;
late final Highlighter _serverpodProtocolLightYamlHighlighter;
late final Highlighter _serverpodProtocolDarkYamlHighlighter;
late final Highlighter _jsonLightHighlighter;
late final Highlighter _jsonDarkHighlighter;

class HighlighterManager {
  // 单例实例
  static final HighlighterManager _instance = HighlighterManager._internal();

  // static TextStyle _codeStyle = GoogleFonts.jetBrainsMono(
  //   fontSize: 14,
  //   height: 1.3,
  // );
  static final TextStyle defaultCodeStyle = GoogleFonts.sourceCodePro(
    fontSize: 14,
    height: 1.3,
  );

  final Map<String, Highlighter> _keyEntityMap = {};
  late var _hlTheme;

  HighlighterManager._internal();

  Highlighter? getHighlighter(String language) {
    return _keyEntityMap.containsKey(language)
        ? _keyEntityMap[language]
        : _keyEntityMap['json'];
  }

  Future<void> initialize(bool isDark) async {
    _hlTheme =
        isDark
            ? await HighlighterTheme.loadDarkTheme()
            : await HighlighterTheme.loadLightTheme();

    await Highlighter.initialize(['json', 'dart', 'yaml']);

    String jsonString = await rootBundle.loadString('assets/languages/python');

    Highlighter.addLanguage("python", jsonString);

    jsonString = await rootBundle.loadString('assets/languages/bash');

    Highlighter.addLanguage("bash", jsonString);

    // await Highlighter.initialize(['../../../assets/languages/python']);

    _keyEntityMap['json'] = Highlighter(language: 'json', theme: _hlTheme);
    _keyEntityMap['dart'] = Highlighter(language: 'dart', theme: _hlTheme);
    _keyEntityMap['python'] = Highlighter(language: 'python', theme: _hlTheme);
    _keyEntityMap['yaml'] = Highlighter(language: 'yaml', theme: _hlTheme);
    _keyEntityMap['bash'] = Highlighter(language: 'bash', theme: _hlTheme);
  }

  static Future<void> ensureInitialized(bool isDark) async {
    await HighlighterManager().initialize(isDark);
  }

  // 工厂方法返回单例实例
  factory HighlighterManager() {
    return _instance;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the highlighter.
  await Highlighter.initialize([
    'dart',
    'yaml',
    'sql',
    'serverpod_protocol',
    'json',
  ]);

  // Load the default light theme and create a highlighter.
  var lightTheme = await HighlighterTheme.loadLightTheme();
  _dartLightHighlighter = Highlighter(language: 'dart', theme: lightTheme);
  _serverpodProtocolLightYamlHighlighter = Highlighter(
    language: 'serverpod_protocol',
    theme: lightTheme,
  );
  _jsonLightHighlighter = Highlighter(language: 'json', theme: lightTheme);

  // Load the default dark theme and create a highlighter.
  var darkTheme = await HighlighterTheme.loadDarkTheme();
  _dartDarkHighlighter = Highlighter(language: 'dart', theme: darkTheme);
  _serverpodProtocolDarkYamlHighlighter = Highlighter(
    language: 'serverpod_protocol',
    theme: darkTheme,
  );
  _jsonDarkHighlighter = Highlighter(language: 'json', theme: darkTheme);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syntax Highlight Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SelectableText.rich(
              // Highlight the code.
              _dartLightHighlighter.highlight(_code),
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.3),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: SelectableText.rich(
              // Highlight the code.
              _dartDarkHighlighter.highlight(_code),
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.3),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SelectableText.rich(
              // Highlight the code.
              _serverpodProtocolLightYamlHighlighter.highlight(_serverpodYaml),
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.3),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: SelectableText.rich(
              // Highlight the code.
              _serverpodProtocolDarkYamlHighlighter.highlight(_serverpodYaml),
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.3),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SelectableText.rich(
              // Highlight the code.
              _jsonLightHighlighter.highlight(_json),
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.3),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: SelectableText.rich(
              // Highlight the code.
              _jsonDarkHighlighter.highlight(_json),
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
