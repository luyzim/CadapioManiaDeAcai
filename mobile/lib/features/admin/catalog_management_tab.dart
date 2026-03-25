import 'package:flutter/material.dart';

import '../../core/models/admin_models.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/api_client.dart';
import '../../core/utils/display_utils.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/remote_image.dart';

class CatalogManagementTab extends StatefulWidget {
  const CatalogManagementTab({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<CatalogManagementTab> createState() => _CatalogManagementTabState();
}

class _CatalogManagementTabState extends State<CatalogManagementTab> {
  final AdminService _adminService = AdminService();
  final GlobalKey<FormState> _categoryFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _itemFormKey = GlobalKey<FormState>();

  final TextEditingController _categoryNameController =
      TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemShortDescriptionController =
      TextEditingController();
  final TextEditingController _itemIngredientsController =
      TextEditingController();
  final TextEditingController _itemImageUrlController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();

  List<AdminCategory> _categories = const <AdminCategory>[];
  List<AdminMenuItem> _items = const <AdminMenuItem>[];

  bool _isLoading = true;
  bool _isSavingCategory = false;
  bool _isSavingItem = false;

  String? _loadError;
  String? _categoryError;
  String? _itemError;

  int? _editingCategoryId;
  int? _editingItemId;
  int? _selectedCategoryId;
  bool _itemActive = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant CatalogManagementTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _loadCatalog();
    }
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _itemNameController.dispose();
    _itemShortDescriptionController.dispose();
    _itemIngredientsController.dispose();
    _itemImageUrlController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _adminService.fetchCategories(widget.token),
        _adminService.fetchItems(widget.token),
      ]);

      if (!mounted) {
        return;
      }

      _categories = List<AdminCategory>.from(results[0] as List<AdminCategory>);
      _items = List<AdminMenuItem>.from(results[1] as List<AdminMenuItem>);
      _syncSelectedCategory();

      setState(() {
        _isLoading = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = 'Nao foi possivel carregar o catalogo.';
        _isLoading = false;
      });
    }
  }

  void _syncSelectedCategory() {
    if (_categories.isEmpty) {
      _selectedCategoryId = null;
      return;
    }

    final bool hasSelectedCategory = _categories.any(
      (AdminCategory category) => category.id == _selectedCategoryId,
    );

    if (!hasSelectedCategory) {
      _selectedCategoryId = _categories.first.id;
    }
  }

  void _resetCategoryForm() {
    _editingCategoryId = null;
    _categoryNameController.clear();
    _categoryError = null;
  }

  void _resetItemForm() {
    _editingItemId = null;
    _itemNameController.clear();
    _itemShortDescriptionController.clear();
    _itemIngredientsController.clear();
    _itemImageUrlController.clear();
    _itemPriceController.clear();
    _itemActive = true;
    _itemError = null;
    _syncSelectedCategory();
  }

  void _startEditingCategory(AdminCategory category) {
    setState(() {
      _editingCategoryId = category.id;
      _categoryNameController.text = category.name;
      _categoryError = null;
    });
  }

  void _startEditingItem(AdminMenuItem item) {
    setState(() {
      _editingItemId = item.id;
      _selectedCategoryId = item.categoryId;
      _itemNameController.text = item.name;
      _itemShortDescriptionController.text = item.shortDescription ?? '';
      _itemIngredientsController.text = item.ingredients ?? '';
      _itemImageUrlController.text = item.imageUrl ?? '';
      _itemPriceController.text = _formatPriceInput(item.priceCents);
      _itemActive = item.active;
      _itemError = null;
    });
  }

  Future<void> _submitCategory() async {
    if (!_categoryFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSavingCategory = true;
      _categoryError = null;
    });

    try {
      if (_editingCategoryId == null) {
        await _adminService.createCategory(
          token: widget.token,
          name: _categoryNameController.text.trim(),
        );
      } else {
        await _adminService.updateCategory(
          token: widget.token,
          categoryId: _editingCategoryId!,
          name: _categoryNameController.text.trim(),
        );
      }

      if (!mounted) {
        return;
      }

      _resetCategoryForm();
      await _loadCatalog();
      _showSnackBar('Categoria salva com sucesso.');
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _categoryError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _categoryError = 'Nao foi possivel salvar a categoria.');
    } finally {
      if (mounted) {
        setState(() => _isSavingCategory = false);
      }
    }
  }

  Future<void> _deleteCategory(AdminCategory category) async {
    final int linkedItems = _items
        .where((AdminMenuItem item) => item.categoryId == category.id)
        .length;

    final bool confirmed = await _showDeleteConfirmation(
      title: 'Excluir categoria',
      message: linkedItems == 0
          ? 'A categoria "${category.name}" sera removida.'
          : 'A categoria "${category.name}" possui $linkedItems item(ns) e a exclusao remove esses registros tambem.',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _adminService.deleteCategory(
        token: widget.token,
        categoryId: category.id,
      );

      if (!mounted) {
        return;
      }

      if (_editingCategoryId == category.id) {
        _resetCategoryForm();
      }
      if (_selectedCategoryId == category.id) {
        _selectedCategoryId = null;
      }
      await _loadCatalog();
      _showSnackBar('Categoria excluida com sucesso.');
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Nao foi possivel excluir a categoria.', isError: true);
    }
  }

  Future<void> _submitItem() async {
    if (!_itemFormKey.currentState!.validate()) {
      return;
    }

    final int? categoryId = _selectedCategoryId;
    final int? priceCents = _parsePriceCents(_itemPriceController.text);

    if (categoryId == null) {
      setState(() => _itemError = 'Selecione uma categoria para o item.');
      return;
    }

    if (priceCents == null) {
      setState(() => _itemError = 'Informe um preco valido.');
      return;
    }

    setState(() {
      _isSavingItem = true;
      _itemError = null;
    });

    try {
      if (_editingItemId == null) {
        await _adminService.createItem(
          token: widget.token,
          categoryId: categoryId,
          name: _itemNameController.text.trim(),
          priceCents: priceCents,
          shortDescription: _normalizedOrNull(
            _itemShortDescriptionController.text,
          ),
          ingredients: _normalizedOrNull(_itemIngredientsController.text),
          imageUrl: _normalizedOrNull(_itemImageUrlController.text),
          active: _itemActive,
        );
      } else {
        await _adminService.updateItem(
          token: widget.token,
          itemId: _editingItemId!,
          categoryId: categoryId,
          name: _itemNameController.text.trim(),
          priceCents: priceCents,
          shortDescription: _normalizedOrNull(
            _itemShortDescriptionController.text,
          ),
          ingredients: _normalizedOrNull(_itemIngredientsController.text),
          imageUrl: _normalizedOrNull(_itemImageUrlController.text),
          active: _itemActive,
        );
      }

      if (!mounted) {
        return;
      }

      _resetItemForm();
      await _loadCatalog();
      _showSnackBar('Item salvo com sucesso.');
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _itemError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _itemError = 'Nao foi possivel salvar o item.');
    } finally {
      if (mounted) {
        setState(() => _isSavingItem = false);
      }
    }
  }

  Future<void> _deleteItem(AdminMenuItem item) async {
    final bool confirmed = await _showDeleteConfirmation(
      title: 'Excluir item',
      message: 'O item "${item.name}" sera removido do cardapio.',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _adminService.deleteItem(
        token: widget.token,
        itemId: item.id,
      );

      if (!mounted) {
        return;
      }

      if (_editingItemId == item.id) {
        _resetItemForm();
      }
      await _loadCatalog();
      _showSnackBar('Item excluido com sucesso.');
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Nao foi possivel excluir o item.', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmation({
    required String title,
    required String message,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14091F),
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFF7F1D1D) : null,
      ),
    );
  }

  String? _validateRequired(String? value, String message) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _validatePrice(String? value) {
    final String raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Informe o preco do item.';
    }

    if (_parsePriceCents(raw) == null) {
      return 'Informe um preco valido. Ex: 19,90';
    }

    return null;
  }

  String? _normalizedOrNull(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  int? _parsePriceCents(String rawValue) {
    final String cleaned =
        rawValue.replaceAll(RegExp(r'[^0-9,\.]'), '').trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final int decimalSeparatorIndex = _lastSeparatorIndex(cleaned);
    if (decimalSeparatorIndex == -1) {
      final int? units = int.tryParse(cleaned);
      return units == null ? null : units * 100;
    }

    final String integerPart = cleaned
        .substring(0, decimalSeparatorIndex)
        .replaceAll(RegExp(r'[,.]'), '');
    String decimalPart = cleaned
        .substring(decimalSeparatorIndex + 1)
        .replaceAll(RegExp(r'[,.]'), '');

    if (decimalPart.isEmpty) {
      decimalPart = '00';
    } else if (decimalPart.length == 1) {
      decimalPart = '${decimalPart}0';
    } else if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    final int? units = int.tryParse(integerPart.isEmpty ? '0' : integerPart);
    final int? cents = int.tryParse(decimalPart);
    if (units == null || cents == null) {
      return null;
    }

    return (units * 100) + cents;
  }

  int _lastSeparatorIndex(String value) {
    final int lastComma = value.lastIndexOf(',');
    final int lastDot = value.lastIndexOf('.');
    return lastComma > lastDot ? lastComma : lastDot;
  }

  String _formatPriceInput(int cents) {
    return (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
  }

  int get _activeItemsCount {
    return _items.where((AdminMenuItem item) => item.active).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.store_mall_directory_outlined,
                  color: Color(0xFFFDA4AF),
                  size: 40,
                ),
                const SizedBox(height: 14),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 200,
                  child: GradientButton(
                    label: 'Tentar novamente',
                    onPressed: _loadCatalog,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCatalog,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Text(
            'Gerencie o cardapio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie categorias, cadastre itens, atualize preco e desative sabores sem precisar tocar no banco manualmente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  label: 'Categorias',
                  value: '${_categories.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Itens',
                  value: '${_items.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Ativos',
                  value: '$_activeItemsCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: _buildCategoryManager(),
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: _buildItemForm(),
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: _buildItemList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Categorias',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use categorias para organizar o cardapio antes de criar os itens.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _categoryFormKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _categoryNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: _editingCategoryId == null
                      ? 'Nova categoria'
                      : 'Editar categoria',
                ),
                validator: (String? value) => _validateRequired(
                  value,
                  'Informe o nome da categoria.',
                ),
              ),
              if (_categoryError != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _categoryError!,
                  style: const TextStyle(
                    color: Color(0xFFFDA4AF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GradientButton(
                      label: _editingCategoryId == null
                          ? 'Salvar categoria'
                          : 'Atualizar categoria',
                      isLoading: _isSavingCategory,
                      onPressed: _submitCategory,
                    ),
                  ),
                  if (_editingCategoryId != null) ...<Widget>[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSavingCategory
                            ? null
                            : () => setState(_resetCategoryForm),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Color(0x33FFFFFF)),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_categories.isEmpty)
          const _EmptyState(
            title: 'Nenhuma categoria cadastrada',
            message: 'Crie a primeira categoria para liberar o cadastro de itens.',
            icon: Icons.category_outlined,
          )
        else
          ..._categories.map(
            (AdminCategory category) {
              final int linkedItems = _items
                  .where((AdminMenuItem item) => item.categoryId == category.id)
                  .length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x10FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              category.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$linkedItems item(ns) vinculados',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar categoria',
                        onPressed: () => _startEditingCategory(category),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white70,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Excluir categoria',
                        onPressed: () => _deleteCategory(category),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFFDA4AF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildItemForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _editingItemId == null ? 'Novo item' : 'Editar item',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Os dados abaixo vao direto para o backend admin e persistem no PostgreSQL via Prisma.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 16),
        if (_categories.isEmpty)
          const _EmptyState(
            title: 'Cadastre uma categoria primeiro',
            message: 'Sem categoria, nao da para relacionar o item no cardapio.',
            icon: Icons.rule_folder_outlined,
          )
        else
          Form(
            key: _itemFormKey,
            child: Column(
              children: <Widget>[
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  dropdownColor: const Color(0xFF1B0B2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(label: 'Categoria'),
                  items: _categories
                      .map(
                        (AdminCategory category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _itemNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(label: 'Nome do item'),
                  validator: (String? value) => _validateRequired(
                    value,
                    'Informe o nome do item.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _itemPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    label: 'Preco em reais',
                    hint: 'Ex: 19,90',
                  ),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _itemShortDescriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    label: 'Descricao curta',
                    hint: 'Resumo exibido no cardapio',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _itemIngredientsController,
                  minLines: 2,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    label: 'Ingredientes',
                    hint: 'Lista de ingredientes ou observacoes',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _itemImageUrlController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    label: 'URL da imagem',
                    hint: '/uploads/acai.png ou https://...',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _itemActive,
                  onChanged: (bool value) {
                    setState(() => _itemActive = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFFD946EF),
                  title: const Text(
                    'Item ativo no cardapio',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Itens inativos continuam no banco, mas saem da vitrine.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                if (_itemImageUrlController.text.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RemoteImage(
                      imageUrl: _itemImageUrlController.text.trim(),
                      width: 120,
                      height: 120,
                      borderRadius: BorderRadius.circular(18),
                      placeholderLabel: _itemNameController.text.trim(),
                    ),
                  ),
                ],
                if (_itemError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _itemError!,
                    style: const TextStyle(
                      color: Color(0xFFFDA4AF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GradientButton(
                        label: _editingItemId == null
                            ? 'Salvar item'
                            : 'Atualizar item',
                        isLoading: _isSavingItem,
                        onPressed: _submitItem,
                      ),
                    ),
                    if (_editingItemId != null) ...<Widget>[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSavingItem
                              ? null
                              : () => setState(_resetItemForm),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Color(0x33FFFFFF)),
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemList() {
    if (_items.isEmpty) {
      return const _EmptyState(
        title: 'Nenhum item cadastrado',
        message: 'Quando voce salvar um item, ele aparecera aqui para edicao rapida.',
        icon: Icons.restaurant_menu_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Itens cadastrados',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Edite o cardapio existente, altere preco ou desative um item sem excluir o historico da base.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 16),
        ..._items.map(
          (AdminMenuItem item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x10FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RemoteImage(
                    imageUrl: item.imageUrl,
                    width: 84,
                    height: 84,
                    borderRadius: BorderRadius.circular(18),
                    placeholderLabel: item.name,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _StatusBadge(
                              label: item.active ? 'Ativo' : 'Inativo',
                              color: item.active
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFFDA4AF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.categoryName ?? 'Sem categoria',
                          style: const TextStyle(
                            color: Color(0xFFF0ABFC),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DisplayUtils.formatCurrency(item.priceCents),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if ((item.shortDescription ?? '').isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            item.shortDescription!,
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if ((item.ingredients ?? '').isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            item.ingredients!,
                            style: const TextStyle(
                              color: Colors.white54,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: () => _startEditingItem(item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0x33FFFFFF),
                                ),
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Editar'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _deleteItem(item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFDA4AF),
                                side: const BorderSide(
                                  color: Color(0x44FB7185),
                                ),
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Excluir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0x14FFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x809333EA), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFB7185), width: 1.4),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: const Color(0xFFF0ABFC),
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
