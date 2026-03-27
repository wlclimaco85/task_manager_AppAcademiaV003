import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/ui/screens/chatMenssageScreen.dart';
import 'package:task_manager_flutter/data/services/chat_caller.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

class ChatListScreen extends StatefulWidget {
  final String userName;

  const ChatListScreen({super.key, required this.userName});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class Chat {
  final String chatId;
  final String sector;
  final String lastMessage;
  final DateTime timestamp;
  final String status;

  Chat({
    required this.chatId,
    required this.sector,
    required this.lastMessage,
    required this.timestamp,
    required this.status,
  });
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> _chats = [];
  bool _isLoading = false;
  final List<String> _availableSectors = [
    'Financeiro',
    'Departamento Pessoal',
    'Fiscal'
  ];
  List<Map<String, dynamic>> _setores = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadSetores(), _loadChats()]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSetores() async {
    try {
      final itens = await Chamado.loadSetores();
      setState(() {
        _setores = itens;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GridColors.error,
          content: Text('Erro ao carregar setores: $e'),
        ),
      );
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ChatCaller().fetchChats(context);
      setState(() {
        _chats = data
            .map((msg) => Chat(
                  chatId: msg.chatId ?? '0',
                  sector: msg.sector ?? 'Setor Desconhecido',
                  lastMessage: msg.text ?? 'Sem mensagem',
                  timestamp:
                      DateTime.tryParse(msg.uploadDate ?? '') ?? DateTime.now(),
                  status: 'Ativo',
                ))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GridColors.error,
          content: Text('Erro ao carregar chats: $e'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startNewChat(String sector) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatMessageScreen(
          sector: sector,
          userName: widget.userName,
          chatId: '0',
        ),
      ),
    );
  }

  void _showSectorSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: GridColors.card,
          title: const Text(
            'Selecionar Setor',
            style: TextStyle(color: GridColors.primary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _setores.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Nenhum setor encontrado.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _setores.length,
                    itemBuilder: (BuildContext context, int index) {
                      final sector = _setores[index]['label'] as String;
                      return ListTile(
                        title: Text(sector),
                        onTap: () {
                          Navigator.pop(context);
                          _startNewChat(sector);
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  void _showChatActions(BuildContext context, Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading:
                    const Icon(Icons.visibility, color: GridColors.secondary),
                title: const Text('Visualizar Chat'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatMessageScreen(
                        sector: chat.sector,
                        userName: widget.userName,
                        chatId: chat.chatId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.check_circle, color: GridColors.success),
                title: const Text('Finalizar Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizeChat(chat);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: GridColors.error),
                title: const Text('Excluir Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteChat(chat);
                },
              ),
              const ListTile(
                leading: Icon(Icons.cancel, color: GridColors.divider),
                title: Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _finalizeChat(Chat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GridColors.card,
        title: const Text('Finalizar Chat',
            style: TextStyle(color: GridColors.primary)),
        content: Text('Deseja finalizar o chat com ${chat.sector}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: GridColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _chats = _chats.map((c) {
                  if (c.sector == chat.sector) {
                    return Chat(
                      chatId: c.chatId,
                      sector: c.sector,
                      lastMessage: c.lastMessage,
                      timestamp: c.timestamp,
                      status: 'Finalizado',
                    );
                  }
                  return c;
                }).toList();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: GridColors.success,
                  content: Text('Chat finalizado com sucesso'),
                ),
              );
            },
            child: const Text('Confirmar',
                style: TextStyle(color: GridColors.primary)),
          ),
        ],
      ),
    );
  }

  void _deleteChat(Chat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GridColors.card,
        title: const Text('Excluir Chat',
            style: TextStyle(color: GridColors.primary)),
        content: Text('Deseja excluir o chat com ${chat.sector}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: GridColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _chats.removeWhere((c) => c.sector == chat.sector);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: GridColors.success,
                  content: Text('Chat excluído com sucesso'),
                ),
              );
            },
            child: const Text('Excluir',
                style: TextStyle(color: GridColors.error)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ativo':
        return GridColors.success;
      case 'Finalizado':
        return GridColors.secondary;
      case 'Pendente':
        return GridColors.warning;
      default:
        return GridColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.green[900], // Fundo verde escuro
      appBar: UserBannerAppBar(
        screenTitle: 'Meus Chats',
        onRefresh: _bootstrap,
        isLoading: _isLoading,
        showFilterButton: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: GridColors.secondary))
          : _chats.isEmpty
              ? const Center(
                  child: Text('Nenhum chat iniciado'),
                )
              : ListView.separated(
                  itemCount: _chats.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: GridColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Fundo claro dos boxes
                        border: Border.all(
                          color: Colors.red, // Borda vermelha
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(
                          chat.sector,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(chat.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(chat.status),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    chat.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getStatusColor(chat.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(chat.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert,
                                  color: GridColors.secondary),
                              onPressed: () => _showChatActions(context, chat),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatMessageScreen(
                                sector: chat.sector,
                                userName: widget.userName,
                                chatId: chat.chatId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Fundo claro
          border: Border.all(color: Colors.red, width: 2), // Borda vermelha
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showSectorSelectionDialog,
          tooltip: 'Novo Chat',
          backgroundColor: Colors.white,
          foregroundColor: Colors.red, // Ícone vermelho
          elevation: 0,
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }
}
