import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/alert_model.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/alert_caller.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart'; // ★ adicionado para aplicar o tema
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/dados_pessoais_edit_screen.dart'; // ★ novo
import 'package:task_manager_flutter/ui/screens/empresa_edit_screen.dart'; // ★ novo
import 'package:task_manager_flutter/ui/screens/parceiro_edit_screen.dart'; // ★ novo

// AppBar customizado (apenas cabeçalho)
class UserBannerAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onTapped;
  final String? screenTitle;
  final VoidCallback? onRefresh;
  final bool? isLoading;
  final VoidCallback? onEmpresaTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onFilterToggle;
  final bool? showFilterButton;
  final VoidCallback? onExportToExcel;

  const UserBannerAppBar({
    super.key,
    this.onTapped,
    this.screenTitle,
    this.onRefresh,
    this.isLoading,
    this.onEmpresaTap,
    this.onUserTap,
    this.onFilterToggle,
    this.showFilterButton = true,
    this.onExportToExcel,
  });

  @override
  _UserBannerAppBarState createState() => _UserBannerAppBarState();

  @override
  Size get preferredSize {
    // Ajusta a altura baseada no showFilterButton
    const baseHeight = kToolbarHeight;
    final filterBarHeight = (showFilterButton == true) ? 52.0 : 0.0;
    return Size.fromHeight(baseHeight + filterBarHeight);
  }
}

class _UserBannerAppBarState extends State<UserBannerAppBar> {
  int unreadAlerts = 0;
  List<Alert> notifications = [];
  OverlayEntry? notificationOverlay;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPeriodicFetch();
  }

  void _startPeriodicFetch() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      fetchAlerts();
    });
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      if (AuthUtility.userInfo?.data?.id != null &&
          AuthUtility.userInfo!.data!.id! > 0) {
        final List<Alert> alertData =
            await AlertCaller().fetchItensAVenda(context);
        setState(() {
          notifications = alertData;
          unreadAlerts = notifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    await AlertCaller().markNotificationAsRead(id);
    setState(() {
      notifications.removeWhere((n) => n.id == id);
      unreadAlerts = notifications.length;
    });
  }

  void deleteNotification(int id) {
    setState(() {
      notifications.removeWhere((n) => n.id == id);
      unreadAlerts = notifications.length;
    });
  }

  void deleteAllNotifications() {
    setState(() {
      notifications.clear();
      unreadAlerts = 0;
    });
  }

  void showNotificationDropdown(BuildContext context) {
    if (notificationOverlay != null) {
      notificationOverlay!.remove();
      notificationOverlay = null;
      return;
    }

    final overlay = Overlay.of(context);

    notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: kToolbarHeight + ((widget.showFilterButton == true) ? 68 : 16),
        right: 8,
        child: Material(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 320,
            height: 400,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GridColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Notificações",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: GridColors.error),
                      onPressed: () {
                        notificationOverlay?.remove();
                        notificationOverlay = null;
                      },
                    ),
                  ],
                ),
                const Divider(height: 1, color: GridColors.divider),
                ListTile(
                  leading:
                      const Icon(Icons.delete_sweep, color: GridColors.error),
                  title: const Text("Limpar Todas",
                      style: TextStyle(
                          color: GridColors.error,
                          fontWeight: FontWeight.w500)),
                  onTap: deleteAllNotifications,
                ),
                const Divider(height: 1, color: GridColors.divider),
                Expanded(
                  child: notifications.isNotEmpty
                      ? ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            return ListTile(
                              leading: const Icon(Icons.notifications,
                                  color: GridColors.primary),
                              title: Text(n.texto,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.clear,
                                    color: GridColors.error),
                                onPressed: () => deleteNotification(n.id),
                              ),
                              onTap: () => markNotificationAsRead(n.id),
                            );
                          },
                        )
                      : const Center(child: Text("Nenhuma notificação")),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(notificationOverlay!);
  }

  void _handleLogout() {
    AuthUtility.clearUserInfo();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Uint8List _getUserAvatar() {
    final base64String = AuthUtility.userInfo?.data?.codDadosPessoal?.photo;
    if (base64String != null && base64String.trim().isNotEmpty) {
      try {
        final UriData? data =
            Uri.parse("data:image/png;base64,$base64String").data;
        if (data != null) return data.contentAsBytes();
      } catch (_) {}
    }
    return Uint8List(0);
  }

  /// ★ NOVO: helpers para editar logo/usuário
  bool get _hasParceiro => (AuthUtility.userInfo?.login?.parceiro?.id ?? 0) > 0;
  bool get _hasEmpresa => (AuthUtility.userInfo?.login?.empresa?.id ?? 0) > 0;

  /// Retorna a imagem da logo do Parceiro ou Empresa como bytes (Uint8List)
  Uint8List _empresaOuParceiroLogo() {
    final parceiro = AuthUtility.userInfo?.login?.parceiro;
    final empresa = AuthUtility.userInfo?.login?.empresa;

    final fileAttachment = _hasParceiro
        ? parceiro?.fileAttachment
        : _hasEmpresa
            ? empresa?.fileAttachment
            : null;

    if (fileAttachment?.fileData != null &&
        fileAttachment!.fileData!.isNotEmpty) {
      try {
        if (fileAttachment.fileData is String) {
          return base64.decode(fileAttachment.fileData as String);
        } else if (fileAttachment.fileData is List<int>) {
          return Uint8List.fromList(fileAttachment.fileData as List<int>);
        }
      } catch (e) {
        debugPrint('Erro ao decodificar logo: $e');
      }
    }

    return Uint8List(0);
  }

  Uint8List _getImageFromBase64(String? base64String) {
    if (base64String != null && base64String.trim().isNotEmpty) {
      try {
        final UriData? data =
            Uri.parse("data:image/png;base64,$base64String").data;
        if (data != null) return data.contentAsBytes();
      } catch (_) {}
    }
    return Uint8List(0);
  }

// Helpers para logo/edição
  bool get _hasParceiros =>
      (AuthUtility.userInfo?.login?.parceiro?.id ?? 0) > 0;
  bool get _hasEmpresas => (AuthUtility.userInfo?.login?.empresa?.id ?? 0) > 0;

  void _openEmpresaOrParceiroEdit() {
    final parceiro = AuthUtility.userInfo?.login?.parceiro;
    final empresa = AuthUtility.userInfo?.login?.empresa;

    if (_hasParceiros && parceiro != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ParceiroEditScreen(initialData: parceiro.toJson()),
        ),
      );
      return;
    }

    if (_hasEmpresas && empresa != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmpresaEditScreen(initialData: empresa.toJson()),
        ),
      );
    }
  }

  void _openDadosPessoaisEdit() {
    final dados = AuthUtility.userInfo?.data?.codDadosPessoal;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DadosPessoaisEditScreen(
          initialData: dados?.toJson() ?? {},
        ),
      ),
    );
  }
  // ★ FIM NOVO

  String _getCompanyName() {
    return AuthUtility.userInfo?.login?.empresa?.nome ?? "Empresa";
  }

  @override
  void dispose() {
    notificationOverlay?.remove();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthUtility.userInfo?.data?.id != null &&
        AuthUtility.userInfo!.data!.id! > 0;

    final logoBytes = _empresaOuParceiroLogo(); // ★ novo uso da logo

    return AppBar(
      backgroundColor: GridColors.primary,
      title: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 120,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LOGO (empresa ou parceiro)
            GestureDetector(
              onTap: _openEmpresaOrParceiroEdit, // ★ novo clique
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: logoBytes.isNotEmpty
                    ? ClipOval(
                        child: Image.memory(
                          logoBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.business,
                        color: Colors.white), // fallback padrão
              ),
            ),

            if (isLoggedIn) ...[
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FOTO DO USUÁRIO
                    GestureDetector(
                      onTap: _openDadosPessoaisEdit, // ★ novo clique
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: _getUserAvatar().isNotEmpty
                            ? ClipOval(
                                child: Image.memory(
                                  _getUserAvatar(),
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: GridColors.primary,
                                      size: 16,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: GridColors.primary,
                                size: 16,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _openDadosPessoaisEdit, // ★ nome também abre
                            child: Text(
                              AuthUtility
                                      .userInfo?.data?.codDadosPessoal?.nome ??
                                  "Usuário",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: GridColors.textPrimary,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          Text(
                            _getCompanyName(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: GridColors.textPrimary,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ] else ...[
              Flexible(
                child: Text(
                  widget.screenTitle ?? "Comunicados",
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (isLoggedIn) ...[
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                iconSize: 20,
                icon: const Icon(Icons.notifications,
                    color: GridColors.textPrimary),
                onPressed: () => showNotificationDropdown(context),
              ),
              if (unreadAlerts > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      unreadAlerts > 9 ? '9+' : '$unreadAlerts',
                      style: const TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            iconSize: 20,
            icon: const Icon(Icons.logout, color: GridColors.textPrimary),
            onPressed: _handleLogout,
            tooltip: 'Sair',
          ),
        ]
      ],
      bottom: (widget.showFilterButton == true)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: FilterActionBar(
                onRefresh: widget.onRefresh,
                isLoading: widget.isLoading,
                onFilterToggle: widget.onFilterToggle,
                onExportToExcel: widget.onExportToExcel,
              ),
            )
          : null,
    );
  }
}

// Nova barra de ações secundária
class FilterActionBar extends StatelessWidget {
  final VoidCallback? onRefresh;
  final bool? isLoading;
  final VoidCallback? onFilterToggle;
  final VoidCallback? onExportToExcel; // 👈 novo

  const FilterActionBar({
    super.key,
    this.onRefresh,
    this.isLoading,
    this.onFilterToggle,
    this.onExportToExcel, // 👈 novo
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: GridColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (onRefresh != null)
            IconButton(
              iconSize: 28,
              icon: isLoading ?? false
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(GridColors.primary),
                      ),
                    )
                  : const Icon(Icons.refresh, color: GridColors.primary),
              onPressed: isLoading ?? false ? null : onRefresh,
              tooltip: 'Recarregar dados',
            ),
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.view_column, color: GridColors.primary),
            onPressed: () {
              // ação configurar colunas
            },
            tooltip: 'Configurar campos visíveis',
          ),
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.filter_list, color: GridColors.primary),
            onPressed: onFilterToggle,
            tooltip: 'Mostrar/ocultar filtros',
          ),
          if (onExportToExcel != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                tooltip: 'Exportar para Excel',
                onPressed: onExportToExcel,
                splashRadius: 22,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                      const Color(0xFF93070A)), // 🔴 vermelho principal
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  overlayColor: WidgetStateProperty.all(Colors.white24),
                  shape: WidgetStateProperty.all(const CircleBorder()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
