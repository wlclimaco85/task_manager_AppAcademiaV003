// lib/data/customization/grid_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'grid_models.dart';
import 'grid_filters.dart';
import 'grid_list.dart';
import 'grid_theme.dart';
import 'grid_form.dart';
import 'grid_utils.dart';
import 'grid_network.dart';

class GenericMobileGridScreen extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint; // ':id'
  final String deleteEndpoint; // ':id'
  final bool Function(String permission) hasPermission;
  final Future<bool> Function(String permission)? asyncHasPermission;
  final List<FieldConfig> fieldConfigs;

  final String idFieldName;
  final String? dateFieldName;
  final PaginationConfig paginationConfig;

  final void Function(Map<String, dynamic> item, BuildContext context)?
      onItemTap;
  final List<CustomAction> Function()? customActions;

  final bool enableSearch;
  final Map<String, dynamic>? initialFilters;
  final String storageKey;
  final Widget Function(Map<String, dynamic> item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final bool enableDebugMode;
  final bool useUserBannerAppBar;
  final VoidCallback? onUserBannerTapped;
  final VoidCallback? onBannerRefresh;

  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;

  final String? baseUrlForMultipart;
  final Future<Map<String, String>> Function()? authHeadersProvider;

  final List<ServerAction>? serverActions;

  const GenericMobileGridScreen({
    super.key,
    required this.title,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.hasPermission,
    this.asyncHasPermission,
    required this.fieldConfigs,
    this.idFieldName = 'id',
    this.dateFieldName,
    this.paginationConfig = const PaginationConfig(),
    this.onItemTap,
    this.customActions,
    this.enableSearch = true,
    this.initialFilters,
    this.storageKey = 'generic_mobile_grid_settings',
    this.detailScreenBuilder,
    this.extraParams,
    this.enableDebugMode = false,
    this.useUserBannerAppBar = false,
    this.onUserBannerTapped,
    this.onBannerRefresh,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
    this.baseUrlForMultipart,
    this.authHeadersProvider,
    this.serverActions = const [],
  });

  @override
  State<GenericMobileGridScreen> createState() =>
      _GenericMobileGridScreenState();
}

class _GenericMobileGridScreenState extends State<GenericMobileGridScreen> {
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  final Map<String, TextEditingController> _filterControllers = {};
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreItems = true;
  bool _loading = false;
  bool _filtersOpen = false;

  final Map<String, bool> _fieldVisibility = {};
  final Map<String, bool> _permCache = {};
  bool _permsResolved = true;

  Map<String, dynamic>? _editingItem;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    L.i('[GridPage] init "${widget.title}"');
    for (final c in widget.fieldConfigs) {
      _fieldVisibility[c.fieldName] = c.isVisibleByDefault;
      if (c.isFilterable) {
        _filterControllers[c.fieldName] = TextEditingController();
      }
    }

    if (widget.initialFilters != null) {
      widget.initialFilters!.forEach((k, v) {
        if (_filterControllers.containsKey(k)) {
          _filterControllers[k]!.text = v?.toString() ?? '';
        }
      });
    }

    await _loadFieldPreferences();
    _scrollController.addListener(_onScroll);

    await _resolveAsyncPermissions();

    await _loadItems(reset: true);
  }

  Future<void> _resolveAsyncPermissions() async {
    _permCache
        .addAll({'create': true, 'edit': true, 'delete': true, 'view': true});
/*    final f = widget.asyncHasPermission;
    if (f == null) {
      _permCache
          .addAll({'create': true, 'edit': true, 'delete': true, 'view': true});
      for (final a in widget.serverActions ?? []) {
        if ((a.requiredPermission ?? '').isNotEmpty) {
          _permCache[a.requiredPermission!] = true;
        }
      }
      setState(() => _permsResolved = true);
      return;
    }
    final needs = <String>{'create', 'edit', 'delete', 'view'};
    final also = widget.serverActions
            ?.map((a) => a.requiredPermission)
            .whereType<String>() ??
        const Iterable<String>.empty();
    needs.addAll(also);
    for (final p in needs) {
      try {
        final result = await f(p);
        _permCache[p] = result == true;
      } catch (_) {
        _permCache[p] = true;
      }
    }
    setState(() => _permsResolved = true); */
    setState(() => _permsResolved = true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _filterControllers.values) {
      c.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';
      for (final c in widget.fieldConfigs) {
        final saved = prefs.getBool('$key${c.fieldName}');
        if (saved != null) _fieldVisibility[c.fieldName] = saved;
      }
    } catch (e) {
      L.w('[GridPage] load prefs fail: $e');
    }
  }

  Future<void> _saveFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';
      for (final c in widget.fieldConfigs) {
        await prefs.setBool(
          '$key${c.fieldName}',
          _fieldVisibility[c.fieldName] ?? c.isVisibleByDefault,
        );
      }
    } catch (e) {
      L.w('[GridPage] save prefs fail: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (_hasMoreItems && !_loading) _loadMore();
    }
  }

  Future<void> _loadMore() async => _loadItems(reset: false);

  Future<void> _loadItems({bool reset = true}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _hasMoreItems = true;
        _loading = true;
      });
      L.d('[GridPage] loadItems reset');
    } else {
      setState(() => _loading = true);
    }

    try {
      final url = _buildUrl(reset ? 0 : _currentPage);
      L.d('[GridPage] GET $url');
      final resp = await getJson(url);
      if (resp.statusCode == 200 && resp.body != null) {
        final body = resp.body ?? {};
        final list = extractAnyList(body['data'] ?? body['dados'] ?? body);
        final total = (body['totalElements'] ??
                body['total'] ??
                (body['data'] is Map ? body['data']['totalElements'] : null) ??
                (body['dados'] is Map
                    ? body['dados']['totalElements']
                    : null)) as int? ??
            list.length;

        setState(() {
          if (reset) {
            _items
              ..clear()
              ..addAll(list);
          } else {
            _items.addAll(list);
          }
          _filtered = List.from(_items);
          _totalItems = total;
          _hasMoreItems = _items.length < _totalItems;
          _currentPage++;
        });
      } else {
        _snack('Erro ao carregar: ${resp.statusCode}');
      }
    } catch (e, st) {
      L.e('[GridPage] loadItems error: $e', st);
      _snack('Erro ao carregar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _buildUrl(int page) {
    String url = '${widget.fetchEndpoint}?page=$page&size=$_itemsPerPage';
    if (_searchController.text.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(_searchController.text)}';
    }
    for (final c in widget.fieldConfigs.where((x) => x.isFilterable)) {
      final v = _filterControllers[c.fieldName]?.text;
      if (v != null && v.isNotEmpty) {
        url += '&${c.fieldName}=${Uri.encodeComponent(v)}';
      }
    }
    if (widget.extraParams != null) {
      widget.extraParams!.forEach((k, v) {
        url += '&$k=${Uri.encodeComponent(v.toString())}';
      });
    }
    return url;
  }

  void _applyFilters() => _loadItems(reset: true);

  void _clearFilters() {
    for (final c in _filterControllers.values) {
      c.clear();
    }
    _searchController.clear();
    _applyFilters();
  }

  Future<void> _deleteItem(String id) async {
    try {
      L.d('[GridPage] DELETE ${widget.deleteEndpoint.replaceFirst(':id', id)}');
      final resp =
          await deleteJson(widget.deleteEndpoint.replaceFirst(':id', id));
      if (resp.isSuccess) {
        _snack('Item excluído!');
        await _loadItems(reset: true);
      } else {
        _snack('Erro ao excluir: ${resp.statusCode}');
      }
    } catch (e) {
      _snack('Erro ao excluir: $e');
    }
  }

  Future<void> _runServerAction(
      ServerAction action, Map<String, dynamic>? item) async {
    final msg = action.confirmMessage?.trim().isNotEmpty == true
        ? action.confirmMessage!
        : 'Deseja realmente executar "${action.label}"?';
    final ok = await _confirm(
        title: action.label, message: msg, confirmText: 'Executar');
    if (ok != true) return;

    try {
      final endpoint = item == null
          ? action.endpoint
          : action.endpoint.replaceFirst(
              ':id', getNestedValue(item, widget.idFieldName).toString());

      final resp = await runServerAction(action.method, endpoint);
      if (resp.isSuccess) {
        _snack('Ação "${action.label}" executada com sucesso!');
        await _loadItems(reset: true);
      } else {
        _snack('Falha em "${action.label}": ${resp.statusCode}');
      }
    } catch (e) {
      _snack('Erro ao executar ação: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          if (_filtersOpen)
            GridFilters(
              enableSearch: widget.enableSearch,
              filterControllers: _filterControllers,
              searchController: _searchController,
              fieldConfigs: widget.fieldConfigs,
              onApply: _applyFilters,
              onClear: _clearFilters,
              onClose: () => setState(() => _filtersOpen = false),
            ),
          if ((widget.serverActions?.isNotEmpty ?? false))
            _buildServerActionsBar(context),
          Expanded(
            child: GridListScreen(
              title: widget.title,
              fetchEndpoint: widget.fetchEndpoint,
              createEndpoint: widget.createEndpoint,
              updateEndpoint: widget.updateEndpoint,
              deleteEndpoint: widget.deleteEndpoint,
              hasPermission: widget.hasPermission,
              asyncHasPermission: widget.asyncHasPermission,
              fieldConfigs: widget.fieldConfigs,
              idFieldName: widget.idFieldName,
              onItemTap: widget.onItemTap,
              customActions: widget.customActions,
              enableSearch: widget.enableSearch,
              initialFilters: widget.initialFilters,
              storageKey: widget.storageKey,
              detailScreenBuilder: widget.detailScreenBuilder,
              extraParams: widget.extraParams,
              enableDebugMode: widget.enableDebugMode,
              useUserBannerAppBar: widget.useUserBannerAppBar,
              onUserBannerTapped: widget.onUserBannerTapped,
              onBannerRefresh: widget.onBannerRefresh,
              additionalFormData: widget.additionalFormData,
              dynamicAdditionalFormData: widget.dynamicAdditionalFormData,
              baseUrlForMultipart: widget.baseUrlForMultipart,
              authHeadersProvider: widget.authHeadersProvider,
              serverActions: widget.serverActions,
            ),
          ),
        ],
      ),
    );
  }

  bool _can(String perm) {
    /*
    // 🔹 Se já resolvemos as permissões assíncronas
    if (_createdResolved) {
      // 🔹 Retorna a permissão do cache se existir
      if (_asyncPermCache.containsKey(perm)) {
        return _asyncPermCache[perm] ?? true; // default TRUE
      }
      // 🔹 Se não existir, assume TRUE por padrão
      return true;
    }

    // 🔹 fallback para permissão síncrona
    try {
      return widget.hasPermission(perm);
    } catch (_) {
      // 🔹 fallback total — retorna TRUE
      return true;
  } */
    // "TODO QUANDO APLICAR REGRAS DE PERMISSÃO";
    return true;
  }

  Widget? _buildFab() {
    final canCreate = _can('create');
    if (!canCreate) return null;

    return FloatingActionButton(
      onPressed: () async {
        final ok = await _confirm(
          title: 'Novo registro',
          message: 'Deseja abrir o formulário para adicionar um novo item?',
          confirmText: 'Abrir',
        );
        if (ok == true) {
          L.d('[GridPage] abrir form de criação');
          _openForm();
        }
      },
      backgroundColor: GridColors.primary,
      foregroundColor: GridColors.textPrimary,
      tooltip: 'Adicionar',
      child: const Icon(Icons.add),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppBar(
      title: Text(widget.title,
          style: tt.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary)),
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 3,
      actions: [
        IconButton(
          onPressed: _loading ? null : () => _loadItems(reset: true),
          icon: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(cs.onPrimary)),
                )
              : const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: _showFieldSettings,
          icon: const Icon(Icons.view_column),
          tooltip: 'Configurar campos',
        ),
        IconButton(
          onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtros',
        ),
      ],
    );
  }

  Widget _buildServerActionsBar(BuildContext context) {
    final actions = widget.serverActions ?? const <ServerAction>[];
    if (actions.isEmpty) return const SizedBox.shrink();

    final visible = actions.where((a) {
      final perm = a.requiredPermission;
      if (perm == null || perm.isEmpty) return true;
      return _can(perm);
    }).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: visible.map((a) {
          return ElevatedButton.icon(
            icon: Icon(a.icon ?? Icons.play_arrow),
            label: Text(a.label),
            onPressed: () => _runServerAction(a, null),
          );
        }).toList(),
      ),
    );
  }

  void _showFieldSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Campos visíveis'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: widget.fieldConfigs.map((c) {
                return CheckboxListTile(
                  title: Text(c.label),
                  value: _fieldVisibility[c.fieldName] ?? c.isVisibleByDefault,
                  onChanged: c.isFixed
                      ? null
                      : (v) {
                          setSt(() {
                            _fieldVisibility[c.fieldName] = v ?? false;
                          });
                        },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                await _saveFieldPreferences();
                if (mounted) setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _openForm({Map<String, dynamic>? editingItem}) async {
    _editingItem = editingItem;
    L.d('[GridPage] open form (editing=${editingItem != null})');
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: GridColors.primary.withOpacity(0.7),
      builder: (ctx) => GridFormDialog(
        titleNew: 'Adicionar',
        titleEdit: 'Editar',
        fieldConfigs: widget.fieldConfigs,
        createEndpoint: widget.createEndpoint,
        updateEndpoint: widget.updateEndpoint,
        authHeadersProvider: widget.authHeadersProvider,
        baseUrlForMultipart: widget.baseUrlForMultipart,
        additionalFormData: widget.additionalFormData,
        dynamicAdditionalFormData: widget.dynamicAdditionalFormData,
        editingItem: editingItem,
        idFieldName: widget.idFieldName,
      ),
    );

    if (saved == true) {
      L.d('[GridPage] form saved, reloading list');
      await _loadItems(reset: true);
    }
  }

  Future<bool?> _confirm(
      {required String title,
      required String message,
      String confirmText = 'Confirmar'}) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText)),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: GridColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
