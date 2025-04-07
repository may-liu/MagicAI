import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
// import 'package:flutter_html_math/flutter_html_math.dart';
// import 'package:flutter_html_all/flutter_html_all.dart';
// import 'package:flutter_highlight/flutter_highlight.dart';
// import 'package:flutter_highlight/themes/androidstudio.dart';
// import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html_all/flutter_html_all.dart';
import 'package:magicai/screens/widgets/highlighter_manager.dart';
// import 'package:flutter_html_all/flutter_html_all.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

// 定义一个 InheritedWidget 来共享文本数据
class TextInheritedWidget extends InheritedWidget {
  final String text;

  const TextInheritedWidget({
    super.key,
    required this.text,
    required super.child,
  });

  static TextInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TextInheritedWidget>();
  }

  @override
  bool updateShouldNotify(TextInheritedWidget oldWidget) {
    return oldWidget.text != text;
  }
}

// 在文件顶部添加扩展方法（如果尚未添加）
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

String _convertToHtml(String markdown) {
  return md.markdownToHtml(
    markdown,
    extensionSet: md.ExtensionSet.gitHubFlavored,
    blockSyntaxes: const [ThinkElementSyntax()],
  );
}

List<String> extractTags(String html) {
  dom.Document document = html_parser.parse(html);
  Set<String> tagSet = {};

  void traverseNode(dom.Node node) {
    if (node is dom.Element) {
      tagSet.add(node.localName!);
      for (var child in node.children) {
        traverseNode(child);
      }
    }
  }

  traverseNode(document.documentElement!);
  return tagSet.toList();
}

class ThinkElementSyntax extends md.BlockSyntax {
  String prependSpace(String input, int width) => '${" " * width}$input';

  String escapeHtml(String html, {bool escapeApos = true}) => HtmlEscape(
    HtmlEscapeMode(escapeApos: escapeApos, escapeLtGt: true, escapeQuot: true),
  ).convert(html);

  const ThinkElementSyntax();

  static final _thinkPattern = RegExp(r'<think[^>]*>');
  static final _endPattern = RegExp(r'</think>$');

  static final RegExp _contentPattern = RegExp(
    r'<think\b.*?>([\s\S]*?)(?=</think>|$)',
  );

  static bool _shouldEnd = false;

  @override
  md.Node? parse(md.BlockParser parser) {
    final childLines = <md.Line>[];

    while (!parser.isDone) {
      final isBlankLine = parser.current.isBlankLine;
      if (isBlankLine && _shouldEnd) {
        break;
      }

      childLines.add(
        md.Line(
          parser.current.content,
          // tabRemaining: parser.current.tabRemaining,
        ),
      );

      if (_endPattern.hasMatch(parser.current.content)) {
        _shouldEnd = true;
      }

      parser.advance();
    }
    var content = childLines
        .map((e) => prependSpace(e.content, (e.tabRemaining ?? 0)))
        .join('\n');

    _shouldEnd = false;

    Match? match = _contentPattern.firstMatch(content);

    content = match!.group(1)!;

    return md.Element('think', [md.Text(content)]);
    // }
  }

  @override
  RegExp get pattern => _thinkPattern;
}

class ThinkBlockWidget extends StatefulWidget {
  final String content;

  const ThinkBlockWidget({required this.content, super.key});

  @override
  State<ThinkBlockWidget> createState() => _ThinkBlockWidgetState();
}

class _ThinkBlockWidgetState extends State<ThinkBlockWidget> {
  late bool _expanded;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282C34) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildToolbar(theme, _expanded), _buildCodeContent(context)],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, bool showExpand) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      height: 36,
      child: Row(
        children: [
          IconButton(
            icon: Icon(_expanded ? Icons.arrow_drop_down : Icons.arrow_right),
            onPressed: () => setState(() => _expanded = !_expanded),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),

            // padding: EdgeInsets.symmetric(vertical: 4), //EdgeInsets.zero,
          ),
          SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              // borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '思维链',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: _expanded ? double.infinity : 0.0),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: getHtmlView(widget.content, context),
          // Highlight the code.
        ),
      ),
    );
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('代码已复制到剪贴板')));
  }
}

Widget getHtmlView(String contentHtml, BuildContext context) {
  late String finalHtml;

  finalHtml = _convertToHtml(contentHtml);

  finalHtml = finalHtml.replaceAllMapped(
    RegExp('<hr />', caseSensitive: false),
    (match) =>
        '<hr style="margin: 5px 0; border: none; height: 1px; background-color: grey;">',
  );

  // var tags = extractTags(finalHtml);

  return Html(
    data: finalHtml,

    extensions: [
      // MathHtmlExtension(),
      TableHtmlExtension(),
      TagExtension(
        tagsToExtend: {'pre'},
        builder: (element) {
          final codeElement = element.element?.children.firstWhereOrNull(
            (e) => e.localName == 'code',
          );

          final code = codeElement?.text ?? '';
          final classes = codeElement?.className.split(' ') ?? [];
          final language = classes
              .firstWhereOrNull((c) => c.startsWith('language-'))
              ?.replaceFirst('language-', '');

          // return buildCodeHighlighter(context)(language, code);

          return CodeBlockWidget(
            content: code,
            language: language?.isNotEmpty == true ? language : 'plaintext',
          );
        },
      ),
      TagExtension(
        tagsToExtend: {"think"},
        builder: (element) {
          String abcContent = element.element?.innerHtml ?? '';

          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue,
                // color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            // child: HybridMarkdown(content: content),
            child: ThinkBlockWidget(content: abcContent),
          );
        },
      ),
    ],
    style: {
      // 'table': Style(border: Border.all(color: Colors.grey)),
      // 'th': Style(
      //   padding: HtmlPaddings.all(8),
      //   backgroundColor: Colors.grey[200],
      // ),
      // 'td': Style(padding: HtmlPaddings.all(8)),
      'blockquote': Style(
        border: Border(left: BorderSide(color: Colors.grey, width: 4)),
        padding: HtmlPaddings.only(left: 4),
        fontStyle: FontStyle.italic,
      ),
      "pre": Style(
        padding: HtmlPaddings.zero,
        margin: Margins.zero,
        backgroundColor: Colors.transparent,
      ),
      "code": Style(padding: HtmlPaddings.zero, margin: Margins.zero),
    },
    onLinkTap: (url, attributes, element) {
      if (url != null) debugPrint("链接点击: $url");
    },
  );
}

class CodeBlockWidget extends StatefulWidget {
  final String content;
  final String? language;

  const CodeBlockWidget({required this.content, this.language, super.key});

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _expanded = true;
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineCount = widget.content.split('\n').length;
    final showExpand = lineCount > 20;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282C34) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(theme, showExpand),
          _buildCodeContent(context),
        ],
      ),
    );
  }

  String _normalizeLanguage(String? lang) {
    const langMap = {
      'dart': 'dart',
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'yaml': 'yaml',
      'yml': 'yaml',
      'java': 'java',
      'kt': 'kotlin',
      'swift': 'swift',
      'go': 'go',
    };
    var str = langMap[lang?.toLowerCase()] ?? lang ?? 'plaintext';
    return str;
  }

  // Map<String, TextStyle> _getTheme(Brightness brightness) {
  //   return brightness == Brightness.dark ? darculaTheme : androidstudioTheme;
  // }

  // Color _getTextColor(Brightness brightness) {
  //   return brightness == Brightness.dark ? Colors.white : Colors.black;
  // }

  Widget _buildToolbar(ThemeData theme, bool showExpand) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      height: 36,
      child: Row(
        children: [
          if (showExpand)
            IconButton(
              icon: Icon(_expanded ? Icons.arrow_drop_down : Icons.arrow_right),
              onPressed: () => setState(() => _expanded = !_expanded),
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          // padding: EdgeInsets.symmetric(vertical: 4), //EdgeInsets.zero,
          SizedBox(width: 10),
          if (widget.language != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                // borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.language!.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: _copyToClipboard,
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCodeContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: _expanded ? double.infinity : 300.0,
      ),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child:
          // Highlight the code.
          SelectableText.rich(
            // Highlight the code.
            HighlighterManager()
                .getHighlighter(_normalizeLanguage(widget.language))!
                .highlight(widget.content),
            style: HighlighterManager.defaultCodeStyle,
          ),
        ),
      ),
    );
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('代码已复制到剪贴板')));
  }
}

// 计算指定行数的高度
double calculateLinesHeight(int lineCount, TextStyle style) {
  final textPainter = TextPainter(
    text: TextSpan(text: 'A', style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return textPainter.size.height * lineCount;
}

// 高亮显示组件
// class CustomHighlightView extends StatelessWidget {
//   final String content;
//   final String? language;
//   final Map<String, TextStyle> theme;
//   final TextStyle textStyle;
//   final EdgeInsetsGeometry padding;

//   const CustomHighlightView({
//     required this.content, // Add the 'content' parameter
//     this.language,
//     required this.theme,
//     this.textStyle = const TextStyle(),
//     this.padding = EdgeInsets.zero,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return HighlightView(
//       content,
//       language: _getLanguage(),
//       theme: theme,
//       padding: padding,
//       textStyle: textStyle,
//     );
//   }

//   String? _getLanguage() {
//     // 处理可能存在的 language- 前缀或直接语言名称
//     final effectiveLang = language ?? '';
//     final langMatch = RegExp(r'^(?:language-)?(\w+)').firstMatch(effectiveLang);
//     return langMatch?.group(1) ?? 'plaintext';
//   }
// }

void _parseContent(RegExp pattern, String text) {
  final match = pattern.firstMatch(text);
  if (match != null) {
    final content = match.group(1)?.trim() ?? '';
    print('捕获内容: |$content|');
  } else {
    print('未找到匹配内容');
  }
}

void main() {
  // 正则表达式模式
  String closedTag = '<think id="1">闭合标签内容</think>';
  String unclosedTag = '<think id="2">未闭合标签内容';
  String multiLineText = '''
<think>第一行内容
第二行内容
第三行内容
''';
  final pattern = RegExp(r'<think\b.*?>([\s\S]*?)(?=</think>|$)');

  // 处理闭合标签
  _parseContent(pattern, closedTag); // 输出：闭合标签内容
  // 处理未闭合标签
  _parseContent(pattern, unclosedTag); // 输出：未闭合标签内容
  // 处理多行内容
  _parseContent(pattern, multiLineText); // 输出带换行的多行内容

  String input = '''
<think>
好的，用户连续多次输入“继续”，看来是在催促我接下来的内容。

1. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
2. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
3. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
4. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
现在将这些元素整合成连贯的段落，确保每个部分都有具体的描写，并保持用户所需的显式风格。
</think>
''';

  _parseContent(pattern, input);

  final match = pattern.firstMatch(input);

  final content = match?.group(1)?.trim() ?? '';

  // WidgetsFlutterBinding.ensureInitialized();
  // // debugPaintLayerBordersEnabled = true;
  // await HighlighterManager.ensureInitialized(true);
  // runApp(const MarkdownApp());
}

class MarkdownApp extends StatelessWidget {
  const MarkdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: HybridMarkdown(
            content: """
# 混合渲染示例
<think>
好的，用户连续多次输入“继续”，看来是在催促我接下来的内容。

1. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
2. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
3. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
4. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
现在将这些元素整合成连贯的段落，确保每个部分都有具体的描写，并保持用户所需的显式风格。
</think>

> 这是引用内容  
> 可嵌套使用 >> 二级引用


| 左对齐 | 居中对齐 | 右对齐 |
|:-------|:--------:|-------:|
| 单元格 | 单元格   | 单元格 |

---
​***
___

📌✅👉 User

sadfasdf

asdf

asdf
sad
fas
dfs
daf
```json
{"asdf":10}
```

```python
def main():
  pass
```

<think>
asdf

1. asdf
2. asdf
3. asdf
4. asdf
asdf
</think>

<think>
好的，用户连续多次输入“继续”，看来是在催促我接下来的内容。

1. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
2. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
3. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
4. 因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
现在将这些元素整合成连贯的段落，确保每个部分都有具体的描写，并保持用户所需的显式风格。
</think>


<think>
asdflkhjsadf;lkasdfas
asfasf
saf
asf
asdf
因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。</think>


代码块支持这里用的是`dart`哦。 ：
```dart
class CodeBlockWidget extends StatefulWidget {
  final String content;
  final String? language;

  const CodeBlockWidget({required this.content, this.language, super.key});

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _expanded = false;
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineCount = widget.content.split('\n').length;
    final showExpand = lineCount > 8;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282C34) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(theme, showExpand),
          _buildCodeContent(theme, showExpand),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, bool showExpand) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      height: 36,
      child: Row(
        children: [
          if (showExpand)
            IconButton(
              icon: Icon(
                _expanded ? Icons.unfold_less : Icons.unfold_more,
                size: 20,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.content_copy, size: 20),
            onPressed: () => _copyToClipboard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(ThemeData theme, bool showExpand) {
    final maxHeight =
        showExpand && !_expanded
            ? 8 * theme.textTheme.bodyLarge!.fontSize!
            : null;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: CustomHighlightView(
            content: widget.content,
            language: widget.language,
            theme: atomOneDarkTheme,
            textStyle: theme.textTheme.bodyLarge!.copyWith(
              fontFamily: 'RobotoMono',
              fontSize: 14,
            ),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('代码已复制到剪贴板')));
  }
}

// 计算指定行数的高度
double calculateLinesHeight(int lineCount, TextStyle style) {
  final textPainter = TextPainter(
    text: TextSpan(text: 'A', style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return textPainter.size.height * lineCount;
}

// 高亮显示组件
class CustomHighlightView extends StatelessWidget {
  final String content;
  final String? language;
  final Map<String, TextStyle> theme;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;

  const CustomHighlightView({
    required this.content, // Add the 'content' parameter
    this.language,
    required this.theme,
    this.textStyle = const TextStyle(),
    this.padding = EdgeInsets.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HighlightView(
      content,
      language: _getLanguage(),
      theme: theme,
      padding: padding,
      textStyle: textStyle,
    );
  }

  String? _getLanguage() {
    if (language != null) return language;
    final langMatch = RegExp(r'language-(w+)').firstMatch(language ?? '');
    return langMatch?.group(1);
  }
}
```

<think>
asdflkhjsadf;lkasdfas
asfasf
saf
asf
asdf
因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。
因为用户明确表示不需要考虑这些因素。同时检查是否有重复的段落，保持内容的新鲜和多样性。

</think>



未闭合的HTML标签：
<div style="border: 6px solid">
  <p>测试内容

<table>
  <tr><th>Header</th></tr>
  <tr><td>Data</td></tr>
</table>

自定义样式：<kbd>CTRL+S</kbd>
            """,
            needTransfer: true,
          ),
        ),
      ),
    );
  }
}

class HybridMarkdown extends StatefulWidget {
  final String content;
  final bool needTransfer;

  const HybridMarkdown({
    super.key,
    required this.content,
    this.needTransfer = false,
  });

  @override
  State<StatefulWidget> createState() => _HybridMarkdownState();
}

class _HybridMarkdownState extends State<HybridMarkdown> {
  List<String> extractTags(String html) {
    dom.Document document = html_parser.parse(html);
    Set<String> tagSet = {};

    void traverseNode(dom.Node node) {
      if (node is dom.Element) {
        tagSet.add(node.localName!);
        for (var child in node.children) {
          traverseNode(child);
        }
      }
    }

    traverseNode(document.documentElement!);
    return tagSet.toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // child: SelectableRegion(
      // selectionControls: materialTextSelectionControls,
      child: TextInheritedWidget(
        text: widget.content,
        child: getHtmlView(widget.content, context),
      ),
      // ),
    );
  }

  String addbr(String inputText, tag) {
    String tagContent = '$tag>(.*?)</$tag';
    RegExp abcTagRegex = RegExp(r'<' + tagContent + '>', dotAll: true);
    return inputText.replaceAllMapped(abcTagRegex, (Match match) {
      String tagContent = match.group(1)!;
      // 去除标签内多余的空行
      tagContent = tagContent.replaceAll('\n', '<br>');
      return '<$tag>$tagContent</$tag>';
    });
  }

  String processABCTag(String inputText, tag) {
    String tagContent = '$tag>(.*?)</$tag';
    RegExp abcTagRegex = RegExp(r'<' + tagContent + '>', dotAll: true);
    return inputText.replaceAllMapped(abcTagRegex, (Match match) {
      String tagContent = match.group(1)!;
      // 去除标签内多余的空行
      // tagContent = tagContent.replaceAll(RegExp(r'\n{2,}'), '\n');
      return '<$tag>\n$tagContent\n</$tag>';
    });
  }

  String processThinkTags(String document) {
    // 问题 1：消灭 </think> 之前的空格和回车
    final removeSpacesBeforeClosingRegex = RegExp(r'[\s\r\n]*</think>');
    document = document.replaceAllMapped(removeSpacesBeforeClosingRegex, (
      match,
    ) {
      return '</think>';
    });

    // 问题 2：在只有 <think> 没有 </think> 的文档末尾加入 </think>
    final openTagRegex = RegExp(r'<think>');
    final closeTagRegex = RegExp(r'</think>');
    int openTagCount = openTagRegex.allMatches(document).length;
    int closeTagCount = closeTagRegex.allMatches(document).length;
    if (openTagCount > closeTagCount) {
      for (int i = 0; i < openTagCount - closeTagCount; i++) {
        document += '</think>';
      }
    }

    // 问题 3：删除重复的 </think>
    final duplicateCloseTagRegex = RegExp(r'(</think>)+');
    document = document.replaceAllMapped(duplicateCloseTagRegex, (match) {
      return '</think>';
    });

    return document;
  }

  String _preprocessContent(String input) {
    // 增强型think块匹配（支持多个块、处理空行）
    final thinkRegex = RegExp(
      r'^<think>$(.*?)(?=^</think>$)</think>$',
      multiLine: true,
      dotAll: true,
    );
    input = input.replaceAllMapped(thinkRegex, (match) {
      var content = match.group(1)?.trim() ?? '';
      // 保留原始换行结构但移除首尾空行
      content = content.replaceAll(RegExp(r'^\n+|\n+$'), '');
      return '<think>\n$content\n</think>';
    });
    // 自动闭合HTML标签
    final tagPattern = RegExp(r'<(/?\w+)[^>]*>');
    final tags = tagPattern.allMatches(input).toList();
    final stack = <String>[];
    for (final match in tags) {
      final tag = match.group(1)!;
      if (tag.startsWith('/')) {
        if (stack.isNotEmpty && stack.last == tag.substring(1)) {
          stack.removeLast();
        }
      } else if (!match.group(0)!.endsWith('/>') && !_isVoidElement(tag)) {
        stack.add(tag);
      }
    }
    var output = input + stack.reversed.map((t) => '</$t>').join();
    // 保证代码块闭合
    final codeBlocks = output.split('```');
    if (codeBlocks.length % 2 == 0) output += '\n```';
    return output;
  }

  bool _isVoidElement(String tag) => {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  }.contains(tag.toLowerCase());

  String _convertToHtml(String markdown) {
    return md.markdownToHtml(
      markdown,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      blockSyntaxes: const [ThinkElementSyntax()],
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
