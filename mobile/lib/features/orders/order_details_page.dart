import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/order_models.dart';
import '../../core/services/api_client.dart';
import '../../core/services/orders_service.dart';
import '../../core/utils/display_utils.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/status_pill.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({
    super.key,
    required this.orderId,
  });

  static const String routeName = '/order-details';

  final String orderId;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final OrdersService _ordersService = OrdersService();
  Timer? _pollingTimer;

  OrderDetails? _order;
  bool _isLoading = true;
  bool _isConfirming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    _pollingTimer?.cancel();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final OrderDetails order =
          await _ordersService.fetchOrderDetails(widget.orderId);

      if (!mounted) {
        return;
      }

      setState(() {
        _order = order;
        _isLoading = false;
      });

      if (order.status != 'Entregue') {
        _pollingTimer = Timer(
          const Duration(seconds: 5),
          _loadOrder,
        );
      }
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
        _errorMessage = 'Nao foi possivel carregar o pedido.';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelivery() async {
    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    try {
      await _ordersService.confirmDelivery(widget.orderId);
      await _loadOrder();
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = 'Nao foi possivel confirmar a entrega.');
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0316),
      appBar: AppBar(
        title: Text('Pedido #${widget.orderId}'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null && _order == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.receipt_long_outlined,
                              color: Color(0xFFFDA4AF),
                              size: 40,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style:
                                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white70,
                                      ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _loadOrder,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _OrderDetailsView(
                    order: _order!,
                    isConfirming: _isConfirming,
                    errorMessage: _errorMessage,
                    onConfirmDelivery: _confirmDelivery,
                  ),
      ),
    );
  }
}

class _OrderDetailsView extends StatelessWidget {
  const _OrderDetailsView({
    required this.order,
    required this.isConfirming,
    required this.errorMessage,
    required this.onConfirmDelivery,
  });

  final OrderDetails order;
  final bool isConfirming;
  final String? errorMessage;
  final VoidCallback onConfirmDelivery;

  @override
  Widget build(BuildContext context) {
    final bool canConfirm = order.status == 'Pronto';
    final bool isDelivered = order.status == 'Entregue';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        GlassCard(
          child: Column(
            children: <Widget>[
              Text(
                'Pedido #${order.id}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              if ((order.customerName ?? '').isNotEmpty)
                Text(
                  order.customerName!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 14),
              StatusPill(status: order.status),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Status do pedido',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 20),
              _StatusTracker(currentStatus: order.status),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Resumo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: 'Data',
                value: DisplayUtils.formatDateTime(order.createdAt),
              ),
              if ((order.customerTable ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Mesa',
                  value: order.customerTable!,
                ),
              ],
              const SizedBox(height: 10),
              _SummaryRow(
                label: 'Total',
                value: DisplayUtils.formatCurrency(order.totalCents),
                highlight: true,
              ),
              if ((order.deliveryAddress ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Entrega',
                  value: _deliveryLabel(order),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Itens',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              ...order.items.map(
                (OrderLineItem item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderItemTile(item: item),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                isDelivered
                    ? 'Pedido finalizado'
                    : canConfirm
                        ? 'Seu pedido esta pronto!'
                        : 'Aguardando atualizacao',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                isDelivered
                    ? 'A entrega ja foi confirmada.'
                    : canConfirm
                        ? 'Confirme o recebimento assim que o pedido for entregue.'
                        : 'Esta tela atualiza automaticamente enquanto o pedido estiver em andamento.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.45,
                    ),
              ),
              if (errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFFDA4AF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              GradientButton(
                label: isDelivered ? 'Pedido entregue' : 'Recebi meu pedido',
                isLoading: isConfirming,
                onPressed: canConfirm && !isDelivered ? onConfirmDelivery : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _deliveryLabel(OrderDetails order) {
    final List<String> parts = <String>[
      order.deliveryAddress ?? '',
      order.deliveryCity ?? '',
      order.deliveryState ?? '',
      order.deliveryZipCode ?? '',
    ].where((String value) => value.trim().isNotEmpty).toList();

    return parts.join(' • ');
  }
}

class _StatusTracker extends StatelessWidget {
  const _StatusTracker({
    required this.currentStatus,
  });

  final String currentStatus;

  static const List<String> _steps = <String>[
    'Recebido',
    'Em preparo',
    'Pronto',
    'Entregue',
  ];

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _steps.indexOf(
      DisplayUtils.formatOrderStatus(currentStatus),
    );

    return Row(
      children: List<Widget>.generate(_steps.length * 2 - 1, (int index) {
        if (index.isOdd) {
          final int stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < currentIndex
                  ? const Color(0xFFA855F7)
                  : const Color(0x334A0E8A),
            ),
          );
        }

        final int stepIndex = index ~/ 2;
        final String step = _steps[stepIndex];
        final bool isCompleted = stepIndex < currentIndex;
        final bool isActive = stepIndex == currentIndex;

        return SizedBox(
          width: 62,
          child: Column(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: isActive ? 38 : 34,
                width: isActive ? 38 : 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive
                      ? (isActive
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFF8B5CF6))
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted || isActive
                        ? Colors.transparent
                        : const Color(0xFF4A0E8A),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isCompleted ? '✓' : '${stepIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFFA78BFA)
                      : isCompleted
                          ? Colors.white
                          : Colors.white54,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 72,
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

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({
    required this.item,
  });

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${item.quantity}x ${item.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DisplayUtils.formatCurrency(item.unitPriceCents)} cada',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            DisplayUtils.formatCurrency(item.subtotalCents),
            style: const TextStyle(
              color: Color(0xFFF0ABFC),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
