class ChatMessage {
  final String sender;
  final String content;
  final String type;
  final int? fileId;
  final String? fileName;
  final String? timestamp;
  final String? fileUrl; // <- novo

  // Novos campos do payload
  final int? empId;
  final int? codApp;
  final int? codUsuOrig;
  final int? codUsuDest;
  final String? sector;
  final String? chatId;
  final String? uploadDate;
  final String? text;

  ChatMessage({
    required this.sender,
    required this.content,
    required this.type,
    this.fileId,
    this.fileName,
    this.timestamp,
    this.empId,
    this.codApp,
    this.codUsuOrig,
    this.codUsuDest,
    this.sector,
    this.chatId,
    this.uploadDate,
    this.text,
    this.fileUrl,
  });

  // Construtor a partir de JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      fileId: json['fileId'],
      fileName: json['fileName'],
      timestamp: json['timestamp'],
      empId: json['empId'],
      codApp: json['codApp'],
      codUsuOrig: json['codUsuOrig'],
      codUsuDest: json['codUsuDest'],
      sector: json['sector'],
      chatId: json['chatId'],
      uploadDate: json['uploadDate'],
      text: json['text'],
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sender'] = sender;
    data['content'] = content;
    data['type'] = type;
    data['fileId'] = fileId;
    data['fileName'] = fileName;
    data['timestamp'] = timestamp;

    // Novos campos
    data['empId'] = empId;
    data['codApp'] = codApp;
    data['codUsuOrig'] = codUsuOrig;
    data['codUsuDest'] = codUsuDest;
    data['sector'] = sector;
    data['chatId'] = chatId;
    data['uploadDate'] = uploadDate;
    data['text'] = text;

    return data;
  }

  // Converter lista de JSON em lista de ChatMessage
  static List<ChatMessage> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class ChatMessageModel {
  String? status;
  String? token;
  List<ChatMessage>? messages;

  ChatMessageModel({this.status, this.token, this.messages});

  ChatMessageModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    messages = json['data'] != null
        ? ChatMessage.fromJsonList(json['data']['dados'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (messages != null) {
      data['data'] = {
        'messages': messages!.map((msg) => msg.toJson()).toList(),
      };
    }
    return data;
  }
}
