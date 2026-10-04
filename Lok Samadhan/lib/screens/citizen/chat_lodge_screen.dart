import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/chat_message.dart';
import '../../models/grievance.dart';
import '../../providers/chat_provider.dart';
import '../../providers/grievance_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confidence_badge.dart';

class ChatLodgeScreen extends StatefulWidget {
  final void Function(String ticketId)? onTrackGrievance;
  final VoidCallback? onNavigateToMyGrievances;

  const ChatLodgeScreen({
    super.key,
    this.onTrackGrievance,
    this.onNavigateToMyGrievances,
  });

  @override
  State<ChatLodgeScreen> createState() => _ChatLodgeScreenState();
}

class _ChatLodgeScreenState extends State<ChatLodgeScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isSpeechListening = false;
  bool _isSpeechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _initSpeech() async {
    try {
      _isSpeechAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isSpeechListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init exception: $e');
    }
  }

  void _toggleSpeechListen() async {
    if (!_isSpeechAvailable) {
      _initSpeech();
    }

    if (_isSpeechListening) {
      await _speech.stop();
      if (mounted) setState(() => _isSpeechListening = false);
    } else {
      if (_isSpeechAvailable) {
        setState(() => _isSpeechListening = true);
        final langProvider = Provider.of<LanguageProvider>(context, listen: false);
        final localeId = LanguageProvider.getSpeechLocale(langProvider.selectedDialect.id);
        await _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _textController.text = val.recognizedWords;
                _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length),
                );
              });
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          localeId: localeId,
          partialResults: true,
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final grievanceProvider = Provider.of<GrievanceProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    chatProvider.sendMessage(
      text,
      grievanceProvider: grievanceProvider,
      locationProvider: locationProvider,
    );

    _textController.clear();
    if (_isSpeechListening) {
      _speech.stop();
      setState(() => _isSpeechListening = false);
    }

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final messages = chatProvider.messages;

    return Column(
      children: [
        // Top AI Header Info & Location Pill
        _buildChatHeader(context, chatProvider, locationProvider),

        // Messages Stream
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: messages.length + (chatProvider.isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length && chatProvider.isTyping) {
                return _buildTypingIndicator();
              }
              final msg = messages[index];
              return _buildMessageItem(context, msg, chatProvider, grievanceProvider, locationProvider);
            },
          ),
        ),

        // Quick Reply Suggestions
        _buildQuickChipsBar(chatProvider, grievanceProvider, locationProvider),

        // Bottom Input Bar
        _buildInputBar(context),
      ],
    );
  }

  Widget _buildChatHeader(
    BuildContext context,
    ChatProvider chatProvider,
    LocationProvider locationProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.saffronPrimary,
            child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lok Samadhan AI Sahayak',
                      style: GoogleFonts.notoSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  locationProvider.isRealGpsAcquired
                      ? 'GPS Active • ${locationProvider.statusMessage}'
                      : '24x7 Multilingual Grievance Bot',
                  style: GoogleFonts.notoSans(
                    fontSize: 10.5,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            tooltip: 'Reset Conversation (नई बातचीत)',
            onPressed: () => chatProvider.resetConversation(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    ChatMessage message,
    ChatProvider chatProvider,
    GrievanceProvider grievanceProvider,
    LocationProvider locationProvider,
  ) {
    final isUser = message.sender == MessageSender.user;
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.navyMedium,
              child: const Icon(Icons.auto_awesome, color: AppColors.saffronLight, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.navyDark : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.notoSans(
                      fontSize: 13.5,
                      height: 1.4,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),

                // Draft Grievance Card
                if (message.draftGrievance != null) ...[
                  const SizedBox(height: 8),
                  _buildDraftGrievanceCard(
                    context,
                    message.draftGrievance!,
                    chatProvider,
                    grievanceProvider,
                    locationProvider,
                  ),
                ],

                // Lodged Grievance Success Card
                if (message.lodgedGrievance != null) ...[
                  const SizedBox(height: 8),
                  _buildLodgedSuccessCard(context, message.lodgedGrievance!),
                ],

                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: GoogleFonts.notoSans(
                    fontSize: 9.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildDraftGrievanceCard(
    BuildContext context,
    DraftGrievance draft,
    ChatProvider chatProvider,
    GrievanceProvider grievanceProvider,
    LocationProvider locationProvider,
  ) {
    final dept = draft.departmentInfo;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dept.color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: dept.color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: dept.color.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(dept.icon, color: dept.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept.nameEn,
                        style: GoogleFonts.notoSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        dept.nameHi,
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navyDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SLA: ${dept.defaultSlaHours}h',
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Problem Title
                Text(
                  'Grievance Summary:',
                  style: GoogleFonts.notoSans(fontSize: 10.5, color: AppColors.textMuted),
                ),
                Text(
                  draft.problemTitle,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Location Pill
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.saffronPrimary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        draft.villageWard,
                        style: GoogleFonts.notoSans(fontSize: 11.5, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Urgency & Confidence Tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: draft.urgency == UrgencyLevel.high
                            ? AppColors.warningRedBg
                            : AppColors.amberOrangeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: draft.urgency == UrgencyLevel.high
                              ? AppColors.warningRed
                              : AppColors.amberOrange,
                        ),
                      ),
                      child: Text(
                        draft.urgency == UrgencyLevel.high ? 'HIGH URGENCY' : 'STANDARD URGENCY',
                        style: GoogleFonts.notoSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: draft.urgency == UrgencyLevel.high
                              ? AppColors.warningRed
                              : AppColors.amberOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConfidenceBadge(
                      score: draft.confidenceScore,
                      isHitlRequired: draft.isHitl,
                      showToCitizen: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Confirm and Cancel Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          chatProvider.sendMessage(
                            'Cancel',
                            grievanceProvider: grievanceProvider,
                            locationProvider: locationProvider,
                          );
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                        label: Text(
                          'Confirm & Lodge',
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          chatProvider.confirmAndLodge(
                            grievanceProvider: grievanceProvider,
                            locationProvider: locationProvider,
                          );
                          Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLodgedSuccessCard(BuildContext context, Grievance grievance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emeraldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emeraldPrimary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppColors.emeraldPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Grievance Registered with GPS',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emeraldPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.emeraldPrimary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ticket ID: ${grievance.id}',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                Text(
                  'SLA: ${grievance.departmentInfo.defaultSlaHours}h',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.saffronPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (widget.onTrackGrievance != null)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.search, size: 14, color: Colors.white),
                    label: Text(
                      'Track Status',
                      style: GoogleFonts.notoSans(fontSize: 11.5, color: Colors.white),
                    ),
                    onPressed: () => widget.onTrackGrievance!(grievance.id),
                  ),
                ),
              if (widget.onTrackGrievance != null && widget.onNavigateToMyGrievances != null)
                const SizedBox(width: 8),
              if (widget.onNavigateToMyGrievances != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 14),
                    label: Text(
                      'My Grievances',
                      style: GoogleFonts.notoSans(fontSize: 11.5),
                    ),
                    onPressed: widget.onNavigateToMyGrievances,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.navyMedium,
            child: const Icon(Icons.auto_awesome, color: AppColors.saffronLight, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.saffronPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Lok Samadhan AI is analyzing intent...',
                  style: GoogleFonts.notoSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChipsBar(
    ChatProvider chatProvider,
    GrievanceProvider grievanceProvider,
    LocationProvider locationProvider,
  ) {
    final lastMsg = chatProvider.messages.isNotEmpty ? chatProvider.messages.last : null;
    final chips = lastMsg?.quickChips ?? const [
      '💧 Drinking Water Handpump',
      '⚡ Transformer Fault',
      '🛣️ Road Potholes',
      '🌾 Ration Issue',
      '🔍 Check Status',
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          return ActionChip(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.cardBorder),
            label: Text(
              chip,
              style: GoogleFonts.notoSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            onPressed: () => _handleSend(chip),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Speech Dictation Button
            IconButton(
              icon: Icon(
                _isSpeechListening ? Icons.mic : Icons.mic_none,
                color: _isSpeechListening ? AppColors.saffronPrimary : AppColors.navyMedium,
              ),
              tooltip: _isSpeechListening ? 'Listening... Tap to stop' : 'Speak complaint via microphone',
              onPressed: _toggleSpeechListen,
            ),

            // Text Input Field
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isSpeechListening
                      ? 'Listening to your voice...'
                      : 'Type complaint in Gujarati (ગુજરાતી), Hindi, English...',
                  hintStyle: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: _isSpeechListening ? AppColors.saffronPrimary : AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceSubtle,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _handleSend,
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
            IconButton(
              icon: const Icon(Icons.send_rounded),
              color: AppColors.saffronPrimary,
              onPressed: () => _handleSend(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}
