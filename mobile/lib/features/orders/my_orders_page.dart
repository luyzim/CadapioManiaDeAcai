import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session_controller.dart';
import '../../core/models/order_models.dart';
import '../../core/services/api_client.dart';
import '../../core/services/orders_service.dart';
import '../../core/utils/display_utils.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/status_pill.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({
    super.key,
    required this.onOpenOrder,
  });

  final ValueChanged<String> onOpenOrder;

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final OrdersService _ordersService = OrdersService();

  List<OrderSummary> _orders = const <OrderSummary>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final String token = context.read<SessionController>().session?.token ?? '';
    if (token.isEmpty) {
      setState(() {
        _isLoading = false;
        _orders = const <OrderSummary>[];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<OrderSummary> orders =
          await _ordersService.fetchMyOrders(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
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
        _errorMessage = 'Nao foi possivel carregar seus pedidos.';
        _isLoading = false;
      });
    }
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
                  Icons.receipt_long_outlined,
                  color: Color(0xFFFDA4AF),
                  size: 38,
                ),
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _loadOrders,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.history_toggle_off_rounded,
                  color: Colors.white38,
                  size: 38,
                ),
                const SizedBox(height: 14),
                Text(
                  'Voce ainda nao fez nenhum pedido.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: const Color(0xFFD946EF),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: <Widget>[
          Text(
            'Meus pedidos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Acompanhe o historico e o andamento de cada pedido.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          ..._orders.map(
            (OrderSummary order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OrderCard(
                order: order,
                onTap: () => widget.onOpenOrder(order.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final OrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String previewItems = order.items
        .take(2)
        .map((OrderLineItem item) => '${item.quantity}x ${item.name}')
        .join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Pedido #${order.id}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusPill(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            _MetaLine(
              label: 'Data',
              value: DisplayUtils.formatDateTime(order.createdAt),
            ),
            const SizedBox(height: 8),
            _MetaLine(
              label: 'Cliente',
              value: order.customerName ?? 'Nao informado',
            ),
            if ((order.customerTable ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              _MetaLine(
                label: 'Mesa',
                value: order.customerTable!,
              ),
            ],
            const SizedBox(height: 8),
            _MetaLine(
              label: 'Total',
              value: DisplayUtils.formatCurrency(order.totalCents),
              highlight: true,
            ),
            if (previewItems.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                previewItems,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Ver detalhes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFF0ABFC),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFFF0ABFC) : Colors.white70,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
