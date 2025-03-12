// main.dart
import 'package:flutter/material.dart';
import 'package:magicai/screens/widgets/markdown_html.dart';
import 'package:magicai/screens/widgets/message_menu.dart';
import 'package:magicai/services/abstract_client.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final int messageIndex;
  // final bool isForumMode;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.messageIndex,
  });

  Widget _buildHeader(BuildContext context, bool alignLeft) {
    return Row(
      mainAxisAlignment:
          alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (alignLeft) ...[_buildAvatar(context), const SizedBox(width: 8)],
        Text(
          isUser ? '您' : 'AI助手',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (!alignLeft) ...[const SizedBox(width: 8), _buildAvatar(context)],
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context) {
    Widget singleChild = HybridMarkdown(content: message.content);
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.95,
      ),
      decoration: BoxDecoration(
        color:
            isUser
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, !isUser),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: singleChild,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (!isUser) _buildAvatar(context),
          Expanded(
            child: MessageMenu(
              index: messageIndex,
              message: message,
              isUser: isUser,
              child: Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: _buildChatBubble(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
