import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/cart_controller.dart';
import '../../core/models/cart_item.dart';
import '../../core/utils/display_utils.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/remote_image.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    super.key,
    required this.onBrowseMenu,
    required this.onCheckout,
  });

  final VoidCallback onBrowseMenu;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final CartController cartController = context.watch<CartController>();

    if (!cartController.isReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (cartController.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 40,
                  color: Colors.white38,
                ),
                const SizedBox(height: 14),
                Text(
                  'Seu carrinho esta vazio.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adicione sabores do cardapio para continuar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 180,
                  child: GradientButton(
                    label: 'Ver cardapio',
                    onPressed: onBrowseMenu,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: <Widget>[
        Text(
          'Seu carrinho',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Revise os itens antes de seguir para o pagamento via PIX.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 18),
        ...cartController.items.map(
          (CartItem item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CartItemCard(
              item: item,
              onDecrease: () => cartController.updateQuantity(
                item.itemId,
                item.quantity - 1,
              ),
              onIncrease: () => cartController.updateQuantity(
                item.itemId,
                item.quantity + 1,
              ),
              onRemove: () => cartController.removeItem(item.itemId),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Resumo do pedido',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              _SummaryLine(
                label: 'Itens',
                value: '${cartController.itemCount}',
              ),
              const SizedBox(height: 10),
              _SummaryLine(
                label: 'Total',
                value: DisplayUtils.formatCurrency(cartController.totalCents),
                highlight: true,
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Finalizar pedido',
                onPressed: onCheckout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          RemoteImage(
            imageUrl: item.imageUrl,
            width: 76,
            height: 76,
            borderRadius: BorderRadius.circular(22),
            placeholderLabel: item.name,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.shortDescription?.trim().isNotEmpty == true
                      ? item.shortDescription!
                      : 'Produto artesanal',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  DisplayUtils.formatCurrency(item.subtotalCents),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFF0ABFC),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: <Widget>[
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFDA4AF),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: onDecrease,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: onIncrease,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color color = highlight ? const Color(0xFFF0ABFC) : Colors.white70;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: highlight ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
