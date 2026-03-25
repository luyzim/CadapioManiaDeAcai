import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/cart_controller.dart';
import '../../app/session_controller.dart';
import '../../core/models/cart_item.dart';
import '../../core/services/api_client.dart';
import '../../core/services/orders_service.dart';
import '../../core/utils/display_utils.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/remote_image.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  static const String routeName = '/checkout';

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OrdersService _ordersService = OrdersService();
  late final TextEditingController _nameController;
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  bool _isSubmitting = false;
  bool _didHydrateName = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateName) {
      return;
    }

    _didHydrateName = true;
    _nameController.text =
        context.read<SessionController>().session?.client.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tableController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final SessionController sessionController = context.read<SessionController>();
    final CartController cartController = context.read<CartController>();
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final String token = sessionController.session?.token ?? '';
    if (token.isEmpty) {
      setState(
        () => _feedbackMessage = 'Sua sessao expirou. Faca login novamente.',
      );
      return;
    }

    if (cartController.items.isEmpty) {
      setState(() => _feedbackMessage = 'Seu carrinho esta vazio.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
    });

    try {
      final createdOrder = await _ordersService.createOrder(
        token: token,
        customerName: _nameController.text.trim(),
        customerTable: _tableController.text.trim().isEmpty
            ? null
            : _tableController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        deliveryCity: _cityController.text.trim(),
        deliveryState: _stateController.text.trim(),
        deliveryZipCode: _zipCodeController.text.trim(),
        items: cartController.items.map(_toPayload).toList(),
      );

      await cartController.clear();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<String>(createdOrder.id);
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _feedbackMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _feedbackMessage = 'Nao foi possivel finalizar o pedido.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Map<String, dynamic> _toPayload(CartItem item) {
    return <String, dynamic>{
      'item_id': item.itemId,
      'qty': item.quantity,
    };
  }

  String? _validateRequired(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return 'Informe $label.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = context.watch<CartController>();

    if (!cartController.isReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0316),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0316),
      appBar: AppBar(
        title: const Text('Finalizar pedido'),
      ),
      body: SafeArea(
        child: cartController.items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.remove_shopping_cart_outlined,
                          color: Colors.white38,
                          size: 40,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Seu carrinho esta vazio.',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Voltar'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  Text(
                    'Pagamento via PIX',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Confira os itens e preencha os dados de entrega para concluir o pedido.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 18),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Seu carrinho',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        ...cartController.items.map(
                          (CartItem item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CheckoutItemTile(item: item),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            const Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              DisplayUtils.formatCurrency(
                                cartController.totalCents,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFFF0ABFC),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Informacoes de entrega',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const SizedBox(height: 18),
                          _CheckoutField(
                            label: 'Nome completo',
                            controller: _nameController,
                            validator: (String? value) =>
                                _validateRequired(value, 'seu nome'),
                          ),
                          const SizedBox(height: 14),
                          _CheckoutField(
                            label: 'Numero da mesa (opcional)',
                            controller: _tableController,
                          ),
                          const SizedBox(height: 14),
                          _CheckoutField(
                            label: 'Endereco de entrega',
                            controller: _addressController,
                            validator: (String? value) =>
                                _validateRequired(value, 'o endereco'),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _CheckoutField(
                                  label: 'Cidade',
                                  controller: _cityController,
                                  validator: (String? value) =>
                                      _validateRequired(value, 'a cidade'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CheckoutField(
                                  label: 'Estado',
                                  controller: _stateController,
                                  validator: (String? value) =>
                                      _validateRequired(value, 'o estado'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _CheckoutField(
                            label: 'CEP',
                            controller: _zipCodeController,
                            keyboardType: TextInputType.number,
                            validator: (String? value) =>
                                _validateRequired(value, 'o CEP'),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0x1A9333EA),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0x409333EA),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Color(0xFFF0ABFC),
                                  size: 58,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Chave PIX ficticia: 123.456.789-00',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Use esta area como demonstracao do fluxo de pagamento.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white70,
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (_feedbackMessage != null) ...<Widget>[
                            const SizedBox(height: 16),
                            Text(
                              _feedbackMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFDA4AF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          GradientButton(
                            label: 'Confirmar pedido e pagar',
                            isLoading: _isSubmitting,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CheckoutItemTile extends StatelessWidget {
  const _CheckoutItemTile({
    required this.item,
  });

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        RemoteImage(
          imageUrl: item.imageUrl,
          width: 52,
          height: 52,
          borderRadius: BorderRadius.circular(16),
          placeholderLabel: item.name,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity}x ${DisplayUtils.formatCurrency(item.priceCents)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          DisplayUtils.formatCurrency(item.subtotalCents),
          style: const TextStyle(
            color: Color(0xFFF0ABFC),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CheckoutField extends StatelessWidget {
  const _CheckoutField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        errorStyle: const TextStyle(
          color: Color(0xFFFDA4AF),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ),
    );
  }
}
