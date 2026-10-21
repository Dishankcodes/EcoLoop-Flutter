import 'package:flutter/material.dart';

import '../../app_theme/artist/artist_colors.dart';
import '../../app_theme/user/app_colors.dart';
import '../../services/ecoloop_api.dart';
import '../../shared_preferences_util.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Hi! I’m EcoLoop AI Support. Ask me about your account, products, orders, donations, custom services, or ReMaker features.',
      isUser: false,
    ),
  ];

  bool _sending = false;

  String get _role => Prefs.getString('userRole').trim().toLowerCase();

  bool get _isArtist =>
      _role == 'artist' || _role == 'remaker' || _role == 're_maker';

  Color get _primary => _isArtist ? ArtistColors.primary : AppColors.primary;

  Color get _background =>
      _isArtist ? ArtistColors.background : AppColors.background;

  Color get _surface => _isArtist ? ArtistColors.surface : AppColors.surface;

  Color get _text =>
      _isArtist ? ArtistColors.textPrimary : AppColors.textPrimary;

  Color get _muted =>
      _isArtist ? ArtistColors.textSecondary : AppColors.textSecondary;

  Color get _border =>
      _isArtist ? ArtistColors.border : AppColors.accent.withValues(alpha: .45);

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty || _sending) return;

    if (message.length > 1200) {
      _showError('Please keep your message under 1,200 characters.');
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
      _sending = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final priorHistory = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : <_ChatMessage>[];

      final history = priorHistory
          .take(6)
          .map(
            (item) => <String, String>{
              'role': item.isUser ? 'user' : 'model',
              'text': item.text.length > 1000
                  ? item.text.substring(0, 1000)
                  : item.text,
            },
          )
          .toList();

      final result = await EcoLoopApi.instance.chatWithAi(
        message: message,
        history: history,
      );

      final reply = result['reply']?.toString().trim();

      if (reply == null || reply.isEmpty) {
        throw const EcoLoopApiException(
          'The AI returned an empty response. Please try again.',
        );
      }

      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;

      final detail = error is EcoLoopApiException
          ? error.message
          : 'Please check your connection and try again.';

      setState(() {
        _messages.add(
          _ChatMessage(
            text: 'Sorry, I couldn’t get a response just now. $detail',
            isUser: false,
            isError: true,
          ),
        );
      });

      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: _primary.withValues(alpha: .12),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: _primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EcoLoop AI Support',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Ask us anything about EcoLoop',
                    style: TextStyle(
                      fontSize: 11,
                      color: _muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            color: _primary.withValues(alpha: .07),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: _primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Never share your password, OTP, or payment credentials.',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_sending && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'EcoLoop AI is replying…',
                            style: TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final item = _messages[index];

                return Align(
                  alignment: item.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .82,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: item.isUser ? _primary : _surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(17),
                        topRight: const Radius.circular(17),
                        bottomLeft: Radius.circular(item.isUser ? 17 : 5),
                        bottomRight: Radius.circular(item.isUser ? 5 : 17),
                      ),
                      border: item.isUser ? null : Border.all(color: _border),
                    ),
                    child: Text(
                      item.text,
                      style: TextStyle(
                        color: item.isUser
                            ? Colors.white
                            : item.isError
                            ? (_isArtist ? ArtistColors.error : AppColors.error)
                            : _text,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 1200,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Write your message…',
                        hintStyle: TextStyle(color: _muted, fontSize: 13),
                        counterText: '',
                        filled: true,
                        fillColor: _background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: _primary, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: IconButton.filled(
                      onPressed: _sending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _primary.withValues(
                          alpha: .45,
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 20),
                      tooltip: 'Send message',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}
