import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/security_matrix.dart';
import 'package:task_manager_flutter/ui/screens/sem_acesso_screen.dart';
import 'package:task_manager_flutter/ui/screens/chamado_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/chatMessageListScreen.dart';
import 'package:task_manager_flutter/ui/screens/comunicado_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_bancaria_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_pagar_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_receber_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_screen.dart';
import 'package:task_manager_flutter/ui/screens/documento_screen.dart';
import 'package:task_manager_flutter/ui/screens/file_upload_screen.dart';
import 'package:task_manager_flutter/ui/screens/parceiro_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/ponto_screen.dart';
import 'package:task_manager_flutter/ui/screens/system_test_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;

  List<Widget> _buildScreens(SecurityMatrix sec) {
    return [
      if (sec.canView(AppScreen.calendario)) const CalendarScreen(),
      if (sec.canView(AppScreen.chat))
        AuthUtility.userInfo?.login?.email != null
            ? ChatListScreen(userName: AuthUtility.userInfo?.login?.email ?? '')
            : const ChatListScreen(userName: 'Usuário'),
      if (sec.canView(AppScreen.comunicados)) const ComunicadoScreen(),
      if (sec.canView(AppScreen.chamados))
        ChamadoGridScreen(
          hasPermission: (action) => switch (action) {
            'insert' => sec.canInsert(AppScreen.chamados),
            'update' => sec.canUpdate(AppScreen.chamados),
            'delete' => sec.canDelete(AppScreen.chamados),
            _ => sec.canView(AppScreen.chamados),
          },
        ),
      if (sec.canView(AppScreen.ged)) const FileManagerScreen(),
      Container(), // slot do botão "Mais"
    ];
  }

  List<BottomNavigationBarItem> _buildNavItems(SecurityMatrix sec) {
    return [
      if (sec.canView(AppScreen.calendario))
        const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: "Calendario"),
      if (sec.canView(AppScreen.chat))
        const BottomNavigationBarItem(
            icon: Icon(Icons.chat), label: "Chat"),
      if (sec.canView(AppScreen.comunicados))
        const BottomNavigationBarItem(
            icon: Icon(Icons.campaign), label: "Comunicados"),
      if (sec.canView(AppScreen.chamados))
        const BottomNavigationBarItem(
            icon: Icon(Icons.support_agent), label: "Solicitações"),
      if (sec.canView(AppScreen.ged))
        const BottomNavigationBarItem(
            icon: Icon(Icons.folder_open), label: "GED"),
      const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz), label: "Mais"),
    ];
  }

  void onMenuOptionSelected(String option, SecurityMatrix sec) {
    Navigator.pop(context); // fecha o dialog primeiro
    switch (option) {
      case "Contas Pagar":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaPagarGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.contasPagar),
                'update' => sec.canUpdate(AppScreen.contasPagar),
                'delete' => sec.canDelete(AppScreen.contasPagar),
                _ => sec.canView(AppScreen.contasPagar),
              },
            ),
          ),
        );
        break;
      case "Contas Receber":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaReceberGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.contasReceber),
                'update' => sec.canUpdate(AppScreen.contasReceber),
                'delete' => sec.canDelete(AppScreen.contasReceber),
                _ => sec.canView(AppScreen.contasReceber),
              },
            ),
          ),
        );
        break;
      case "Parceiros":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParceiroGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.parceiros),
                'update' => sec.canUpdate(AppScreen.parceiros),
                'delete' => sec.canDelete(AppScreen.parceiros),
                _ => sec.canView(AppScreen.parceiros),
              },
            ),
          ),
        );
        break;
      case "Dashboard":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
        break;
      case "Contas Bancarias":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaBancariaGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.contasBancarias),
                'update' => sec.canUpdate(AppScreen.contasBancarias),
                'delete' => sec.canDelete(AppScreen.contasBancarias),
                _ => sec.canView(AppScreen.contasBancarias),
              },
            ),
          ),
        );
        break;
      case "Bater Ponto":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PontoScreen()),
        );
        break;
      case "Testes":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SystemTestScreen()),
        );
        break;
      case "Sair":
        Navigator.pop(context);
        break;
      case "Voltar":
        Navigator.pop(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sec = SecurityMatrix.current();
    final screens = _buildScreens(sec);
    final navItems = _buildNavItems(sec);

    // garante que o índice não ultrapasse o tamanho da lista
    final safeIndex = selectedIndex.clamp(0, screens.length - 1);

    // BottomNavigationBar exige no mínimo 2 itens; se o perfil não tem acesso
    // redireciona para a tela de sem acesso.
    if (navItems.length < 2) {
      return const SemAcessoScreen();
    }

    return Scaffold(
      body: screens[safeIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CustomColors().getLightGreenBackground(),
          border: Border(
            top: BorderSide(
                color: CustomColors().getDarkGreenBorder(), width: 2),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: CustomColors().getLightGreenBackground(),
          currentIndex: safeIndex,
          unselectedItemColor: Colors.grey,
          unselectedLabelStyle: const TextStyle(color: Colors.grey),
          selectedItemColor: Colors.green,
          showSelectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (int index) {
            if (index == navItems.length - 1) {
              _showMenuOptions(context, sec);
            } else {
              setState(() => selectedIndex = index);
            }
          },
          items: navItems,
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context, SecurityMatrix sec) {
    // monta apenas os itens que o perfil pode ver
    final menuItems = <Widget>[
      if (sec.canView(AppScreen.contasPagar))
        _menuItem(Icons.payments, "Contas Pagar", sec),
      if (sec.canView(AppScreen.contasReceber))
        _menuItem(Icons.account_balance_wallet, "Contas Receber", sec),
      if (sec.canView(AppScreen.parceiros))
        _menuItem(Icons.people, "Parceiros", sec),
      if (sec.canView(AppScreen.dashboard))
        _menuItem(Icons.bar_chart, "Dashboard", sec),
      if (sec.canView(AppScreen.contasBancarias))
        _menuItem(Icons.text_increase_rounded, "Contas Bancarias", sec),
      if (sec.canView(AppScreen.ponto))
        _menuItem(Icons.access_alarm_rounded, "Bater Ponto", sec),
      _menuItem(Icons.science_outlined, "Testes", sec),
      _menuItem(Icons.exit_to_app, "Sair", sec),
      _menuItem(Icons.arrow_back, "Voltar", sec),
    ];

    showGeneralDialog(
      barrierLabel: "Menu",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      context: context,
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: CustomColors().getLightGreenBackground(),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Mais Opções",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CustomColors().getDarkGreenBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: CustomColors().getDarkGreenBorder(),
                      thickness: 1.2,
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.85,
                      children: menuItems,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(
            parent: anim,
            curve: Curves.fastOutSlowIn,
          )),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String title, SecurityMatrix sec) {
    return GestureDetector(
      onTap: () => onMenuOptionSelected(title, sec),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CustomColors().getDarkGreenBorder().withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: CustomColors().getDarkGreenBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CustomColors().getDarkGreenBorder(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
