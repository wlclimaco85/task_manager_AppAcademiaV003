import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class LicencaScreen extends StatefulWidget {
  const LicencaScreen({super.key});

  @override
  State<LicencaScreen> createState() => _LicencaScreenState();
}

class _LicencaScreenState extends State<LicencaScreen> {
  List<dynamic> _licencas = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    final res = await NetworkCaller().getRequest(ApiLinks.allLicencas);
    if (res.isSuccess) {
      final body = res.body;
      setState(() {
        _licencas = (body is List ? body : (body?['data'] as List? ?? []));
        _loading = false;
      });
    } else {
      setState(() { _erro = 'Erro ao carregar licenças (${res.statusCode})'; _loading = false; });
    }
  }

  Color _statusColor(Map l) {
    if (l['ativo'] == false) return Colors.red;
    final venc = l['dataVencimento'];
    if (venc == null) return Colors.red;
    final dias = DateTime.parse(venc).difference(DateTime.now()).inDays;
    if (dias < 0) return Colors.red;
    if (dias <= 30) return Colors.orange;
    return Colors.green;
  }

  String _statusLabel(Map l) {
    if (l['ativo'] == false) return 'INATIVA';
    final venc = l['dataVencimento'];
    if (venc == null) return 'SEM DATA';
    final dias = DateTime.parse(venc).difference(DateTime.now()).inDays;
    if (dias < 0) return 'VENCIDA';
    if (dias <= 30) return '$dias dias';
    return 'ATIVA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        title: const Text('🔑 Licenças', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFe07b00)))
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
              : _licencas.isEmpty
                  ? const Center(child: Text('Nenhuma licença encontrada.', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _licencas.length,
                        itemBuilder: (ctx, i) {
                          final l = _licencas[i] as Map;
                          final cor = _statusColor(l);
                          final label = _statusLabel(l);
                          return Card(
                            color: const Color(0xFF141414),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: cor.withOpacity(0.4), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: cor.withOpacity(0.15), shape: BoxShape.circle),
                                child: Icon(Icons.verified_user, color: cor, size: 24),
                              ),
                              title: Text(
                                l['nomeApp'] ?? 'App ${l['codApp']}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('App ID: ${l['codApp']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  if (l['dataVencimento'] != null)
                                    Text(
                                      'Vence: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(l['dataVencimento']))}',
                                      style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  if (l['observacao'] != null && l['observacao'].toString().isNotEmpty)
                                    Text(l['observacao'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(label, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _editarLicenca(l),
                                    child: const Icon(Icons.edit, color: Color(0xFFe07b00), size: 20),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _editarLicenca(Map licenca) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditLicencaSheet(
        licenca: licenca,
        onSaved: _carregar,
      ),
    );
  }
}

// ── Modal de edição ───────────────────────────────────────────────────────────
class _EditLicencaSheet extends StatefulWidget {
  final Map licenca;
  final VoidCallback onSaved;
  const _EditLicencaSheet({required this.licenca, required this.onSaved});

  @override
  State<_EditLicencaSheet> createState() => _EditLicencaSheetState();
}

class _EditLicencaSheetState extends State<_EditLicencaSheet> {
  late bool _ativo;
  late DateTime _dataVencimento;
  late TextEditingController _obsCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ativo = widget.licenca['ativo'] ?? true;
    final venc = widget.licenca['dataVencimento'];
    _dataVencimento = venc != null ? DateTime.parse(venc) : DateTime.now().add(const Duration(days: 365));
    _obsCtrl = TextEditingController(text: widget.licenca['observacao'] ?? '');
  }

  @override
  void dispose() { _obsCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataVencimento,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFe07b00)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataVencimento = picked);
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    final id = widget.licenca['id'];
    final body = {
      'ativo': _ativo,
      'dataVencimento': DateFormat('yyyy-MM-dd').format(_dataVencimento),
      'nomeApp': widget.licenca['nomeApp'],
      'observacao': _obsCtrl.text,
    };
    final res = await NetworkCaller().putRequest(
      '${ApiLinks.allLicencas}/$id',
      body,
    );
    setState(() => _saving = false);
    if (res.isSuccess) {
      widget.onSaved();
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Licença atualizada!'), backgroundColor: Colors.green),
      );
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar (${res.statusCode})'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFFe07b00)),
              const SizedBox(width: 8),
              Text(
                'Editar: ${widget.licenca['nomeApp'] ?? 'App ${widget.licenca['codApp']}'}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 24),

          // Ativo toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Licença ativa', style: TextStyle(color: Colors.white)),
              Switch(
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
                activeColor: const Color(0xFFe07b00),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Data de vencimento
          const Text('Data de vencimento', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFFe07b00), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_dataVencimento),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Observação
          const Text('Observação', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _obsCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF222222),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF333333))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF333333))),
              hintText: 'Observação opcional...',
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe07b00),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('💾 Salvar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
