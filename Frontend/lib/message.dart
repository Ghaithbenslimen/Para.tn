class Message {
  final bool isUser;
  final String message;
  final DateTime date;
  final List<String>? suggestions;

  Message({
    required this.isUser,
    required this.message,
    required this.date,
    this.suggestions,
  });
}
