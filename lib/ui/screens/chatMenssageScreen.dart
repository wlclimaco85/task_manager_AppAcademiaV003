import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'dart:typed_data';
import 'package:task_manager_flutter/data/models/chat_model.dart';
import 'package:task_manager_flutter/data/services/chat_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

import 'ticket_form_bottom_sheet.dart';

class ChatMessageScreen extends StatefulWidget {
  final String sector;
  final String userName;
  final String chatId;

  const ChatMessageScreen({
    super.key,
    required this.sector,
    required this.userName,
    required this.chatId,
  });

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  // === PALETA LOCAL (sem novos imports) ===
  static const Color _kPrimaryRed = Color(0xFF93070A);
  static const Color _kGreenDark = Color(0xFF005826);
  static const Color _kGreenLightBubble = Color(0xFFE8F5E9);
  static const Color _kGreenPage = Color(0xFFF1F8F4);

  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  late WebSocketChannel _channel;
  final String _authToken = '${AuthUtility.userInfo?.token}';
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Nome/e-mail do usuário logado
  String get _loggedUserName =>
      AuthUtility.userInfo?.login?.nome ?? widget.userName;
  String get _loggedUserEmail =>
      AuthUtility.userInfo?.login?.email ?? widget.userName;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadInitialMessages();
  }

  void _connectWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(
        ApiLinks.chatStart(widget.userName, widget.sector),
      );

      _channel.stream.listen(
        (message) {
          final messageData = json.decode(message);
          setState(() {
            _messages.add(ChatMessage.fromJson(messageData));
            _scrollToBottom();
          });
        },
        onError: (error) {
          Future.delayed(const Duration(seconds: 3), _connectWebSocket);
        },
        onDone: () {
          _connectWebSocket();
        },
      );
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadInitialMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await ChatCaller().fetchChatsById(context, widget.chatId);
      setState(() {
        _messages = data
            .map((msg) => ChatMessage(
                  sender: msg.sender ?? '',
                  content: msg.text ?? '',
                  type: msg.type ?? 'text',
                  timestamp: msg.uploadDate,
                  empId: msg.empId,
                  codApp: msg.codApp,
                  codUsuOrig: msg.codUsuOrig,
                  codUsuDest: msg.codUsuDest,
                  sector: msg.sector,
                  chatId: msg.chatId,
                  uploadDate: msg.uploadDate,
                  text: msg.text,
                  fileId: msg.fileId,
                  fileName: msg.fileName,
                  fileUrl: msg.fileUrl, // suporte a URL pública se existir
                ))
            .toList();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar mensagens: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final String content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Envie nome e email (sem quebrar o que já funciona)
    _channel.sink.add(json.encode({
      'sender': _loggedUserName, // mantém nome para exibição
      'senderName': _loggedUserName, // redundância segura
      'senderEmail': _loggedUserEmail, // envia e-mail correto p/ backend
      'content': content,
      'sector': widget.sector,
      'type': 'text',
      'timestamp': DateTime.now().toIso8601String(),
      'chatId': widget.chatId,
    }));

    _messageController.clear();
  }

  Future<void> _uploadAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.first;
      Uint8List? fileBytes = file.bytes;

      if (fileBytes == null && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }
      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível ler o arquivo selecionado')),
        );
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.uploadFile),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.name,
      ));

      // Envie e-mail e nome nos campos (e preserva 'user' para compat)
      request.fields['user'] =
          _loggedUserEmail; // muitos backends esperam 'user' como email
      request.fields['userEmail'] = _loggedUserEmail;
      request.fields['userName'] = _loggedUserName;
      request.fields['sector'] = widget.sector;
      request.fields['chatId'] =
          widget.chatId; // importante pro backend vincular

      if (_authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;

        // id e url do arquivo (ajuste as chaves conforme seu backend)
        int? fileId;
        final rawId = jsonResponse['fileId'] ?? jsonResponse['data']?['fileId'];
        if (rawId is int) {
          fileId = rawId;
        } else if (rawId is String) {
          fileId = int.tryParse(rawId);
        }

        // Se o backend já devolver uma URL, use-a; senão, gere via helper
        String? fileUrl = (jsonResponse['fileUrl'] ??
            jsonResponse['data']?['fileUrl']) as String?;
        fileUrl ??= (fileId != null) ? ApiLinks.publicFileUrl(fileId) : null;

        if (fileId != null) {
          _channel.sink.add(json.encode({
            'sender': _loggedUserName, // exibição
            'senderName': _loggedUserName, // redundância segura
            'senderEmail': _loggedUserEmail, // backend
            'content': 'Arquivo: ${file.name}',
            'sector': widget.sector,
            'type': 'file',
            'fileName': file.name,
            'fileId': fileId,
            'fileUrl': fileUrl, // agora a msg carrega o link
            'timestamp': DateTime.now().toIso8601String(),
            'chatId': widget.chatId,
          }));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Upload ok, mas ID do arquivo ausente')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha no upload (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no upload: $e')),
      );
    }
  }

  Future<void> _openOrDownload(int fileId, String fileName,
      {String? fileUrl}) async {
    // 1) se houver URL pública, tentar abrir
    if (fileUrl != null && fileUrl.isNotEmpty) {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    // 2) fallback: baixar e abrir localmente
    await _downloadFile(fileId, fileName, openAfter: true);
  }

  Future<void> _downloadFile(int fileId, String fileName,
      {bool openAfter = false}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiLinks.downloadFile(fileId.toString())),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        if (openAfter) {
          await OpenFilex.open(file.path);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arquivo salvo em: ${file.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao baixar (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar: $e')),
      );
    }
  }

  Future<void> _createTicket() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: TicketFormBottomSheet(sectorDescricao: widget.sector),
        ),
      ),
    );

    // Se criou, “anuncia” no chat
    if (result != null && mounted) {
      try {
        final criado = result; // Chamado retornado
        final id = (criado as dynamic).id;
        _channel.sink.add(json.encode({
          'sender': _loggedUserName, // exibição
          'senderName': _loggedUserName,
          'senderEmail': _loggedUserEmail, // backend
          'content': 'Chamado aberto com sucesso (ID $id)',
          'sector': widget.sector,
          'type': 'ticket',
          'ticketId': id,
          'timestamp': DateTime.now().toIso8601String(),
          'chatId': widget.chatId,
        }));
      } catch (_) {}
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final time = DateTime.tryParse(timestamp);
    if (time == null) return '';
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _channel.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo geral VERDE
      backgroundColor: _kGreenPage,
      appBar: AppBar(
        backgroundColor: _kPrimaryRed,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Setor: ${widget.sector}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(color: _kGreenDark),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _kPrimaryRed, width: 1)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: _kGreenDark),
                  onPressed: _uploadAndSendFile,
                ),
                IconButton(
                  icon: const Icon(Icons.support_agent, color: _kPrimaryRed),
                  onPressed: _createTicket,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: _kGreenPage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: _kPrimaryRed),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: _kPrimaryRed),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            const BorderSide(color: _kPrimaryRed, width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: _kGreenDark),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    // Mantém a semântica original: compara pelo NOME (exibição)
    final isMe = (message.sender == _loggedUserName);

    // Avatar com BORDA VERMELHA
    Widget avatar(String initial) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _kPrimaryRed, width: 2),
        ),
        child: CircleAvatar(
          backgroundColor: _kGreenDark,
          child: Text(
            initial.isNotEmpty ? initial[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Nome para exibir no topo da bolha
    final displayName =
        (message.sender.isNotEmpty ? message.sender : _loggedUserName);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            avatar(displayName),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isMe ? _kGreenDark : _kGreenLightBubble, // VERDES
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _kPrimaryRed, width: 1.5), // BORDA VERMELHA
                boxShadow: [
                  BoxShadow(
                    color: _kPrimaryRed.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOME DENTRO DO BOX (para ambos)
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isMe ? Colors.white : _kGreenDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (message.type == 'text')
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 16,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  if (message.type == 'file')
                    InkWell(
                      onTap: () => _openOrDownload(
                        message.fileId!,
                        message.fileName ?? 'arquivo',
                        fileUrl: message.fileUrl,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: isMe ? Colors.white : _kGreenDark,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              message.fileName ?? 'arquivo',
                              style: TextStyle(
                                color: isMe ? Colors.white : _kGreenDark,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.type == 'ticket')
                    Text(
                      message.content.isNotEmpty
                          ? message.content
                          : '📋 Solicitação de chamado criada',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isMe ? Colors.white : _kGreenDark,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            avatar(displayName),
          ],
        ],
      ),
    );
  }
}
