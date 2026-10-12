import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import the dotenv package
import 'package:intl/intl.dart';
import 'message.dart'; // Import the Message class

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> messages = []; // Use the Message class
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  bool _isTyping = false;

  // Define our color palette
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFFE8F5E9);
  final Color userBubbleColor = const Color(0xFF66BB6A);
  final Color botBubbleColor = Colors.white;
  final Color backgroundColor = const Color(0xFFF5F9F5);

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addBotMessage(
        "Hello! I'm SkinCoach, your personal skincare assistant. How can I help you today?");

    // Add some suggestions
    Future.delayed(const Duration(milliseconds: 500), () {
      _addSuggestions();
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      messages.add(Message(
        isUser: false,
        message: text,
        date: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addSuggestions() {
    setState(() {
      messages.add(Message(
        isUser: false,
        message: "You can ask me about:",
        date: DateTime.now(),
        suggestions: [
          "Acne treatments",
          "Skincare routine for dry skin",
          "Best ingredients for anti-aging",
          "How to treat sunburn"
        ],
      ));
    });
    _scrollToBottom();
  }

  Future<void> talkWithGemini(String userInput) async {
    setState(() {
      _isTyping = true;
    });

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    // Add context to guide the model (focus on skincare)
    final String context =
        "You are a skincare expert called SkinCoach. Provide detailed and accurate advice about skincare routines, products, and treatments. If the question is unrelated to skincare, politely decline to answer and suggest asking a skincare-related question instead. Keep your responses concise and easy to understand. Always suggest follow-up questions or related topics the user might be interested in.";

    // Combine context with user input
    final String fullPrompt = "$context\n\nUser: $userInput";

    final content = Content.text(fullPrompt);

    try {
      final response = await model.generateContent([content]);
      final botResponse = response.text ?? "No response from Gemini.";

      setState(() {
        _isTyping = false;
        messages.add(Message(
          isUser: false,
          message: botResponse,
          date: DateTime.now(),
        ));
      });

      // Add suggestions after response
      if (userInput.toLowerCase().contains('acne')) {
        _addSuggestionsAfterDelay([
          "How to prevent acne scars?",
          "Best cleansers for acne",
          "Diet and acne connection"
        ]);
      } else if (userInput.toLowerCase().contains('routine')) {
        _addSuggestionsAfterDelay([
          "Morning skincare routine",
          "Night skincare routine",
          "Skincare routine for sensitive skin"
        ]);
      } else if (userInput.toLowerCase().contains('ingredient')) {
        _addSuggestionsAfterDelay([
          "Benefits of hyaluronic acid",
          "Is retinol safe?",
          "Best vitamin C serums"
        ]);
      } else {
        _addSuggestionsAfterDelay([
          "Skincare for my skin type",
          "How to layer products",
          "Seasonal skincare tips"
        ]);
      }
    } catch (e, stacktrace) {
      print("Error occurred: $e");
      print("Stacktrace: $stacktrace");
      setState(() {
        _isTyping = false;
        messages.add(Message(
          isUser: false,
          message: 'Sorry, something went wrong. Please try again.',
          date: DateTime.now(),
        ));
      });
    }
  }

  void _addSuggestionsAfterDelay(List<String> suggestions) {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        messages.add(Message(
          isUser: false,
          message: "You might also want to know:",
          date: DateTime.now(),
          suggestions: suggestions,
        ));
      });
      _scrollToBottom();
    });
  }

  void _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    _controller.clear();

    // Add user message to the chat
    setState(() {
      messages.add(Message(
        isUser: true,
        message: userInput,
        date: DateTime.now(),
      ));
    });

    _scrollToBottom();

    // Get bot response
    await talkWithGemini(userInput);
  }

  void _handleSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    _sendMessage();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
                border: Border.all(color: primaryGreen, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/3d-rendered-photos-women-futuristic-portrait_1148167-14177.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SkinCoach',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'AI Skincare Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryGreen,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, color: primaryGreen, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgroundchat.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.85),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Column(
          children: [
            // Add space for AppBar
            SizedBox(
                height: AppBar().preferredSize.height +
                    MediaQuery.of(context).padding.top),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return ChatBubble(
                    isUser: message.isUser,
                    message: message.message,
                    date: message.date,
                    userImagePath: 'assets/ghaithpicture.jpg',
                    botImagePath:
                        'assets/3d-rendered-photos-women-futuristic-portrait_1148167-14177.webp',
                    suggestions: message.suggestions,
                    onSuggestionTap: _handleSuggestionTap,
                    primaryColor: primaryGreen,
                    userBubbleColor: userBubbleColor,
                    botBubbleColor: botBubbleColor,
                  );
                },
              ),
            ),

            // Typing indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 8),
                child: Row(
                  children: [
                    _buildTypingIndicator(),
                    const SizedBox(width: 8),
                    Text(
                      'SkinCoach is typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

            // Message input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            hintText: 'Ask about skincare...',
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey[400],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 600 + (index * 200)),
                curve: Curves.easeInOut,
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Enhanced ChatBubble widget
class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String message;
  final DateTime date;
  final String userImagePath;
  final String botImagePath;
  final List<String>? suggestions;
  final Function(String)? onSuggestionTap;
  final Color primaryColor;
  final Color userBubbleColor;
  final Color botBubbleColor;

  const ChatBubble({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
    required this.userImagePath,
    required this.botImagePath,
    this.suggestions,
    this.onSuggestionTap,
    required this.primaryColor,
    required this.userBubbleColor,
    required this.botBubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(botImagePath),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? userBubbleColor : botBubbleColor,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(5),
                      bottomRight: isUser
                          ? const Radius.circular(5)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 16,
                          color: isUser ? Colors.white : Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white70 : Colors.black54,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                // Suggestion chips
                if (!isUser && suggestions != null && suggestions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions!.map((suggestion) {
                        return GestureDetector(
                          onTap: () => onSuggestionTap?.call(suggestion),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: primaryColor.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(userImagePath),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}
