import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';

class ChamadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ChamadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenericMobileGridScreen<Chamado>(
        title: "Gerenciamento de Chamados",
        fetchEndpoint: ApiLinks.allChamados,
        createEndpoint: ApiLinks.createChamado,
        updateEndpoint: ApiLinks.updateChamado(":id"),
        deleteEndpoint: ApiLinks.deleteChamado(":id"),
        fromJson: (json) => Chamado.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        hasPermission: hasPermission,
        fieldConfigs: Chamado.fieldConfigs,
        idFieldName: 'id',
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10,
          availableRowsPerPage: [10, 25, 50],
        ),
        enableSearch: true,
        customActions: () => [
          CustomAction<Chamado>(
            icon: Icons.assignment_turned_in,
            label: 'Fechar Chamado',
            onPressed: (context, item) {
              _showCloseChamadoDialog(context, [item]);
            },
          ),
        ],
      ),
    );
  }

  void _showCloseChamadoDialog(
      BuildContext context, List<Chamado> selectedItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fechar Chamados'),
        content: Text('Deseja fechar ${selectedItems.length} chamado(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementar lógica de fechamento
              _fecharChamados(selectedItems);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chamados fechados com sucesso!')),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _fecharChamados(List<Chamado> chamados) {
    // Implementar a lógica de fechamento dos chamados
    for (var chamado in chamados) {
      // Lógica para fechar cada chamado
      print('Fechando chamado: ${chamado.id}');
    }
  }
}
