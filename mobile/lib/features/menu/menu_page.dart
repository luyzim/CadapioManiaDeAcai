import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/cart_controller.dart';
import '../../core/models/menu_models.dart';
import '../../core/services/api_client.dart';
import '../../core/services/menu_service.dart';
import '../../core/utils/display_utils.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/remote_image.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  final MenuService _menuService = MenuService();

  List<MenuCategory> _categories = const <MenuCategory>[];
  bool _isLoading = true;
  String? _errorMessage;
  String _activeCategory = 'Todas';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<MenuCategory> categories = await _menuService.fetchCategories();

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Nao foi possivel carregar o cardapio.';
        _isLoading = false;
      });
    }
  }

  List<MenuItemModel> get _filteredItems {
    final String normalizedQuery = _query.trim().toLowerCase();
    final Iterable<MenuItemModel> allItems = _categories.expand(
      (MenuCategory category) => category.items,
    );

    return allItems.where((MenuItemModel item) {
      final bool matchesCategory = _activeCategory == 'Todas' ||
          item.categoryName == _activeCategory;
      final bool matchesQuery = normalizedQuery.isEmpty ||
          item.name.toLowerCase().contains(normalizedQuery) ||
          (item.shortDescription ?? '').toLowerCase().contains(normalizedQuery) ||
          (item.ingredients ?? '').toLowerCase().contains(normalizedQuery);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<String> get _categoryNames {
    return <String>[
      'Todas',
      ..._categories.map((MenuCategory category) => category.name),
    ];
  }

  Future<void> _addToCart(MenuItemModel item) async {
    await context.read<CartController>().addItem(item);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} foi adicionado ao carrinho.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openDetails(MenuItemModel item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12061F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    height: 4,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                RemoteImage(
                  imageUrl: item.imageUrl,
                  height: 220,
                  borderRadius: BorderRadius.circular(26),
                  placeholderLabel: item.name,
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    if ((item.categoryName ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x26D946EF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.categoryName!,
                          style: const TextStyle(
                            color: Color(0xFFF5D0FE),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                if ((item.shortDescription ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    item.shortDescription!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                  ),
                ],
                if ((item.ingredients ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Ingredientes',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.ingredients!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        DisplayUtils.formatCurrency(item.priceCents),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFFF0ABFC),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: GradientButton(
                        label: 'Adicionar',
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _addToCart(item);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFFDA4AF),
                  size: 40,
                ),
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 180,
                  child: GradientButton(
                    label: 'Tentar novamente',
                    onPressed: _loadMenu,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<MenuItemModel> items = _filteredItems;

    return RefreshIndicator(
      onRefresh: _loadMenu,
      color: const Color(0xFFD946EF),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: <Widget>[
          Text(
            'Vitrine de sabores artesanais',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Busque por sabor, ingrediente ou categoria e adicione ao carrinho em poucos toques.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (String value) {
              setState(() => _query = value);
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
              hintText: 'Buscar sabor, ingrediente...',
              hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
              filled: true,
              fillColor: const Color(0x14FFFFFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categoryNames.length,
              separatorBuilder: (_, int index) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final String category = _categoryNames[index];
                final bool isActive = category == _activeCategory;

                return ChoiceChip(
                  label: Text(category),
                  selected: isActive,
                  onSelected: (_) {
                    setState(() => _activeCategory = category);
                  },
                  selectedColor: const Color(0x26D946EF),
                  backgroundColor: const Color(0x14FFFFFF),
                  side: BorderSide(
                    color: isActive
                        ? const Color(0x66F0ABFC)
                        : const Color(0x1AFFFFFF),
                  ),
                  labelStyle: TextStyle(
                    color: isActive ? const Color(0xFFF5D0FE) : Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            GlassCard(
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.search_off_rounded,
                    color: Colors.white38,
                    size: 38,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum item encontrado.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tente ajustar a busca ou trocar a categoria selecionada.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (BuildContext context, int index) {
                final MenuItemModel item = items[index];

                return _MenuCard(
                  item: item,
                  onTap: () => _openDetails(item),
                  onAddToCart: () => _addToCart(item),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.item,
    required this.onTap,
    required this.onAddToCart,
  });

  final MenuItemModel item;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x1AFFFFFF)),
          gradient: const LinearGradient(
            colors: <Color>[Color(0x19FFFFFF), Color(0x0CFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: RemoteImage(
                      imageUrl: item.imageUrl,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(23),
                      ),
                      placeholderLabel: item.name,
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCCBE185D),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.categoryName ?? 'Acai',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.shortDescription?.trim().isNotEmpty == true
                        ? item.shortDescription!
                        : 'Toque para ver os detalhes deste item.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          DisplayUtils.formatCurrency(item.priceCents),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFF0ABFC),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onAddToCart,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBE185D),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
