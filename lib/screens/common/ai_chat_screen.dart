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
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  bool _sending = false;
  bool _loadingHistory = true;
  bool _clearingHistory = false;
  String? _historyError;

  static const _welcomeMessage =
      'Hi! I’m EcoLoop AI Support. Ask me about your account, products, orders, donations, custom services, or ReMaker features.';

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
  Color get _error => _isArtist ? ArtistColors.error : AppColors.error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool showError = false}) async {
    if (mounted) {
      setState(() {
        _loadingHistory = true;
        _historyError = null;
      });
    }

    try {
      final history = await EcoLoopApi.instance.getAiChatHistory();
      final loaded = <_ChatMessage>[];

      for (final item in history) {
        final text = (item['text'] ?? item['message'] ?? '').toString().trim();
        final role = (item['role'] ?? '').toString().trim().toLowerCase();
        if (text.isEmpty ||
            (role != 'user' && role != 'assistant' && role != 'model')) {
          continue;
        }
        loaded.add(_ChatMessage(text: text, isUser: role == 'user'));
      }

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(loaded);
        if (_messages.isEmpty) {
          _messages.add(
            const _ChatMessage(text: _welcomeMessage, isUser: false),
          );
        }
        _loadingHistory = false;
      });
      _scrollToBottom(jump: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
        _historyError = showError ? _errorMessage(error) : null;
        if (_messages.isEmpty) {
          _messages.add(
            const _ChatMessage(text: _welcomeMessage, isUser: false),
          );
        }
      });
    }
  }

  Future<void> _sendMessage([String? suggestedText]) async {
    final message = (suggestedText ?? _controller.text).trim();
    if (message.isEmpty || _sending || _clearingHistory) return;

    if (message.length > 1200) {
      _showSnack('Please keep your message under 1,200 characters.');
      return;
    }

    final priorHistory = _messages
        .where((item) => !item.isError)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed
        .map(
          (item) => <String, String>{
            'role': item.isUser ? 'user' : 'model',
            'text': item.text.length > 1000
                ? item.text.substring(0, 1000)
                : item.text,
          },
        )
        .toList();

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
      _sending = true;
      _controller.clear();
      _historyError = null;
    });
    _scrollToBottom();

    try {
      final result = await EcoLoopApi.instance.chatWithAi(
        message: message,
        history: priorHistory,
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
      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'Sorry, I couldn’t get a response just now. ${_errorMessage(error)}',
            isUser: false,
            isError: true,
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _clearHistory() async {
    if (_clearingHistory || _sending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: Text('Clear chat history?', style: TextStyle(color: _text)),
        content: Text(
          'This permanently clears the saved EcoLoop AI conversation for this account.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Clear history', style: TextStyle(color: _error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _clearingHistory = true);
    try {
      await EcoLoopApi.instance.clearAiChatHistory();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..add(const _ChatMessage(text: _welcomeMessage, isUser: false));
        _historyError = null;
      });
      _showSnack('Chat history cleared.');
      _scrollToBottom(jump: true);
    } catch (error) {
      if (mounted) _showSnack(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _clearingHistory = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is EcoLoopApiException) return error.message;
    return 'Please check your connection and try again.';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final end = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(end);
      } else {
        _scrollController.animateTo(
          end,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
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
        titleSpacing: 0,
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
                  Text(
                    'EcoLoop AI Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
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
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Chat options',
            icon: Icon(Icons.more_vert_rounded, color: _text),
            onSelected: (value) {
              if (value == 'clear') _clearHistory();
              if (value == 'reload') _loadHistory(showError: true);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'reload',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('Reload history'),
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Clear history'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _primary.withValues(alpha: .07),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 17, color: _primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Never share your password, OTP, or payment credentials.',
                    style: TextStyle(fontSize: 11, color: _muted, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          if (_historyError != null)
            Material(
              color: _error.withValues(alpha: .08),
              child: InkWell(
                onTap: () => _loadHistory(showError: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync_problem_rounded, size: 17, color: _error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Could not load saved history. Tap to retry.',
                          style: TextStyle(fontSize: 11, color: _error),
                        ),
                      ),
                      Icon(Icons.refresh_rounded, size: 17, color: _error),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_sending && index == _messages.length) {
                      return _TypingIndicator(
                        primary: _primary,
                        surface: _surface,
                        border: _border,
                        muted: _muted,
                      );
                    }
                    return _MessageBubble(
                      message: _messages[index],
                      isArtist: _isArtist,
                      primary: _primary,
                      surface: _surface,
                      text: _text,
                      border: _border,
                      error: _error,
                    );
                  },
                ),
                if (_loadingHistory)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading saved chat…',
                              style: TextStyle(fontSize: 11, color: _muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_messages.length <= 1 && !_loadingHistory)
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  _suggestion('How can I buy products?'),
                  _suggestion('How can I donate an item?'),
                  _suggestion('How do custom services work?'),
                  _suggestion('How do I reset my password?'),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border, width: .7)),
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
                        hintStyle: TextStyle(fontSize: 13, color: _muted),
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
                          borderSide: BorderSide(color: _primary, width: 1.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: IconButton.filled(
                      onPressed: (_sending || _clearingHistory)
                          ? null
                          : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _primary.withValues(alpha: .4),
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

  Widget _suggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: TextStyle(fontSize: 10.5, color: _primary)),
        backgroundColor: _surface,
        side: BorderSide(color: _border),
        onPressed: _sending ? null : () => _sendMessage(text),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isArtist,
    required this.primary,
    required this.surface,
    required this.text,
    required this.border,
    required this.error,
  });

  final _ChatMessage message;
  final bool isArtist;
  final Color primary;
  final Color surface;
  final Color text;
  final Color border;
  final Color error;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .84,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.isUser ? primary : surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(message.isUser ? 17 : 5),
            bottomRight: Radius.circular(message.isUser ? 5 : 17),
          ),
          border: message.isUser ? null : Border.all(color: border),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? Colors.white
                : message.isError
                ? error
                : text,
            fontSize: 13,
            height: 1.48,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({
    required this.primary,
    required this.surface,
    required this.border,
    required this.muted,
  });

  final Color primary;
  final Color surface;
  final Color border;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            ),
            const SizedBox(width: 9),
            Text(
              'EcoLoop AI is replying…',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
