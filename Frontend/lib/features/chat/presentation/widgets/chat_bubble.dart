import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: isLastInGroup ? 8 : 2,
          top: isFirstInGroup ? 4 : 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe || !isFirstInGroup ? 18 : 4),
            topRight: Radius.circular(!isMe || !isFirstInGroup ? 18 : 4),
            bottomLeft: Radius.circular(isMe || !isLastInGroup ? 18 : 4),
            bottomRight: Radius.circular(!isMe || !isLastInGroup ? 18 : 4),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
