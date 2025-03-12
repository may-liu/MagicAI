// main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magicai/screens/widgets/markdown_html.dart';
import 'package:magicai/screens/widgets/message_menu.dart';
import 'package:magicai/services/abstract_client.dart';

class BlogPost extends StatelessWidget {
  final ChatMessage message;
  final int messageIndex;

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          message.isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
      child: Icon(
        message.isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isUser) {
    return Row(
      children: [
        ...[_buildAvatar(context), const SizedBox(width: 8)],
        Text(
          isUser ? '您' : 'AI助手',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 8),
        Text(
          DateFormat('HH:mm:ss').format(message.timestamp),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  const BlogPost({
    super.key,
    required this.message,
    required this.messageIndex,
  });

  @override
  Widget build(BuildContext context) {
    Widget singleChild = HybridMarkdown(content: message.content);

    return Card(
      margin: const EdgeInsets.all(2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, message.isUser),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // if (!isUser) _buildAvatar(context),
                Expanded(
                  child: MessageMenu(
                    index: messageIndex,
                    message: message,
                    isUser: message.isUser,
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
}
