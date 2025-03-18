// main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magicai/screens/widgets/markdown_html.dart';
import 'package:magicai/screens/widgets/message_menu.dart';
import 'package:magicai/services/abstract_client.dart';

class BlogPost extends StatefulWidget {
  final ChatMessage message;
  final int messageIndex;

  const BlogPost({
    super.key,
    required this.message,
    required this.messageIndex,
  });

  @override
  State<StatefulWidget> createState() => _BlogPostState();
}

class _BlogPostState extends State<BlogPost>
    with AutomaticKeepAliveClientMixin {
  late ChatMessage _message;
  late int _messageIndex;

  @override
  void initState() {
    _message = widget.message;
    _messageIndex = widget.messageIndex;
    super.initState();
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          _message.isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
      child: Icon(
        _message.isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Row(
      children: [
        ...[_buildAvatar(context), const SizedBox(width: 8)],
        Text(
          '| $userName |',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 8),
        Text(
          DateFormat('HH:mm:ss').format(_message.opTime),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget singleChild = HybridMarkdown(
      key: UniqueKey(),
      content: _message.content,
    );

    return Card(
      margin: const EdgeInsets.all(2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, _message.senderId!),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // if (!isUser) _buildAvatar(context),
                Expanded(
                  child: MessageMenu(
                    index: _messageIndex,
                    message: _message,
                    isUser: _message.isUser,
                    child: singleChild,
                    //HybridMarkdown(content: message.content),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
