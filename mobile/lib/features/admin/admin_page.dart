import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/admin_session_controller.dart';
import '../../core/models/admin_models.dart';
import '../../core/models/order_models.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/api_client.dart';
import '../../core/utils/display_utils.dart';
import '../../core/utils/email_validator.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/status_pill.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  static const String routeName = '/admin';

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final TabController _tabController;
  late AdminSessionController _adminSessionController;
  bool _didBindController = false;

  List<AdminDashboardOrder> _dashboardOrders = const <AdminDashboardOrder>[];
  List<OrderSummary> _activeOrders = const <OrderSummary>[];
  List<OrderSummary> _deliveryOrders = const <OrderSummary>[];

  bool _isLoggingIn = false;
  bool _isLoadingDashboard = false;
  bool _isLoadingActiveOrders = false;
  bool _isLoadingDeliveryOrders = false;

  String _dashboardStatusFilter = '';
  String? _loginError;
  String? _emailError;
  String? _passwordError;
  String? _dashboardError;
  String? _activeOrdersError;
  String? _deliveryOrdersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBindController) {
      return;
    }

    _didBindController = true;
    _adminSessionController = context.read<AdminSessionController>();
    _adminSessionController.addListener(_handleSessionChanged);

    if (_adminSessionController.isAuthenticated) {
      _loadAll();
    }
  }

  @override
  void dispose() {
    if (_didBindController) {
      _adminSessionController.removeListener(_handleSessionChanged);
    }
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSessionChanged() {
    if (!mounted) {
      return;
    }

    if (_adminSessionController.isAuthenticated) {
      _loadAll();
    } else {
      setState(() {
        _dashboardOrders = const <AdminDashboardOrder>[];
        _activeOrders = const <OrderSummary>[];
        _deliveryOrders = const <OrderSummary>[];
      });
    }
  }

  Future<void> _loadAll() async {
    await Future.wait(<Future<void>>[
      _loadDashboardOrders(),
      _loadActiveOrders(),
      _loadDeliveryOrders(),
    ]);
  }

  Future<void> _loadDashboardOrders() async {
    final String token = _adminSessionController.token ?? '';
    if (token.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final List<AdminDashboardOrder> orders =
          await _adminService.fetchDashboardOrders(
        token,
        status: _dashboardStatusFilter,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardOrders = orders;
        _isLoadingDashboard = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardError = error.message;
        _isLoadingDashboard = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardError = 'Nao foi possivel carregar os pedidos.';
        _isLoadingDashboard = false;
      });
    }
  }

  Future<void> _loadActiveOrders() async {
    final String token = _adminSessionController.token ?? '';
    if (token.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingActiveOrders = true;
      _activeOrdersError = null;
    });

    try {
      final List<OrderSummary> orders =
          await _adminService.fetchPaidOrders(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _activeOrders = orders;
        _isLoadingActiveOrders = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeOrdersError = error.message;
        _isLoadingActiveOrders = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeOrdersError = 'Nao foi possivel carregar a fila de pedidos.';
        _isLoadingActiveOrders = false;
      });
    }
  }

  Future<void> _loadDeliveryOrders() async {
    final String token = _adminSessionController.token ?? '';
    if (token.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingDeliveryOrders = true;
      _deliveryOrdersError = null;
    });

    try {
      final List<OrderSummary> orders =
          await _adminService.fetchDeliveryOrders(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _deliveryOrders = orders;
        _isLoadingDeliveryOrders = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _deliveryOrdersError = error.message;
        _isLoadingDeliveryOrders = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _deliveryOrdersError = 'Nao foi possivel carregar os pedidos prontos.';
        _isLoadingDeliveryOrders = false;
      });
    }
  }

  String? _validateEmail(String value) {
    final String email = value.trim().toLowerCase();
    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }

    if (!EmailValidator.isValid(email)) {
      return 'Informe um e-mail valido.';
    }

    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Informe sua senha.';
    }

    return null;
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim().toLowerCase();
    final String password = _passwordController.text;
    final String? emailError = _validateEmail(email);
    final String? passwordError = _validatePassword(password);

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _loginError = null;
    });

    if (emailError != null || passwordError != null) {
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      await _adminSessionController.login(
        email: email,
        password: password,
      );
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loginError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _loginError = 'Falha ao entrar no painel admin.');
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final String token = _adminSessionController.token ?? '';
    if (token.isEmpty) {
      return;
    }

    try {
      await _adminService.updateOrderStatus(
        token: token,
        orderId: orderId,
        status: status,
      );
      await _loadAll();
    } on ApiFailure catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AdminSessionController adminSessionController =
        context.watch<AdminSessionController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0316),
      appBar: AppBar(
        title: const Text('Painel admin'),
        actions: <Widget>[
          if (adminSessionController.isAuthenticated)
            IconButton(
              onPressed: context.read<AdminSessionController>().signOut,
              tooltip: 'Sair',
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
        bottom: adminSessionController.isAuthenticated
            ? TabBar(
                controller: _tabController,
                tabs: const <Tab>[
                  Tab(text: 'Pedidos'),
                  Tab(text: 'Fila'),
                  Tab(text: 'Entrega'),
                ],
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: adminSessionController.isAuthenticated
            ? TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _DashboardTab(
                    orders: _dashboardOrders,
                    isLoading: _isLoadingDashboard,
                    errorMessage: _dashboardError,
                    activeFilter: _dashboardStatusFilter,
                    onFilterChanged: (String status) {
                      setState(() => _dashboardStatusFilter = status);
                      _loadDashboardOrders();
                    },
                    onRefresh: _loadDashboardOrders,
                    onStatusChanged: _updateOrderStatus,
                  ),
                  _QueueTab(
                    title: 'Fila de pedidos ativos',
                    orders: _activeOrders,
                    isLoading: _isLoadingActiveOrders,
                    errorMessage: _activeOrdersError,
                    onRefresh: _loadActiveOrders,
                  ),
                  _QueueTab(
                    title: 'Pedidos prontos para entrega',
                    orders: _deliveryOrders,
                    isLoading: _isLoadingDeliveryOrders,
                    errorMessage: _deliveryOrdersError,
                    onRefresh: _loadDeliveryOrders,
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Login admin',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (String value) {
                              if (_emailError != null || _loginError != null) {
                                setState(() {
                                  _emailError =
                                      _validateEmail(value.trim().toLowerCase());
                                  _loginError = null;
                                });
                              }
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              label: 'E-mail',
                              errorText: _emailError,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            onChanged: (String value) {
                              if (_passwordError != null || _loginError != null) {
                                setState(() {
                                  _passwordError = _validatePassword(value);
                                  _loginError = null;
                                });
                              }
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              label: 'Senha',
                              errorText: _passwordError,
                            ),
                          ),
                          if (_loginError != null) ...<Widget>[
                            const SizedBox(height: 14),
                            Text(
                              _loginError!,
                              style: const TextStyle(
                                color: Color(0xFFFDA4AF),
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 18),
                          GradientButton(
                            label: 'Entrar',
                            isLoading: _isLoggingIn,
                            onPressed: _login,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Color(0xFFFDA4AF),
        fontWeight: FontWeight.w600,
      ),
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

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.orders,
    required this.isLoading,
    required this.errorMessage,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onStatusChanged,
  });

  final List<AdminDashboardOrder> orders;
  final bool isLoading;
  final String? errorMessage;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function({
    required String orderId,
    required String status,
  }) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FilterChip(
                status: '',
                isActive: activeFilter.isEmpty,
                onTap: () => onFilterChanged(''),
              ),
              ...<String>['Recebido', 'Em preparo', 'Pronto', 'Entregue'].map(
                (String status) => _FilterChip(
                  status: status,
                  isActive: activeFilter == status,
                  onTap: () => onFilterChanged(status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            _StateCard(message: errorMessage!, isError: true)
          else if (orders.isEmpty)
            const _StateCard(message: 'Nenhum pedido encontrado.')
          else
            ...orders.map(
              (AdminDashboardOrder order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DashboardOrderCard(
                  order: order,
                  onStatusChanged: (String status) {
                    onStatusChanged(orderId: order.id, status: status);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  const _QueueTab({
    required this.title,
    required this.orders,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
  });

  final String title;
  final List<OrderSummary> orders;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            _StateCard(message: errorMessage!, isError: true)
          else if (orders.isEmpty)
            const _StateCard(message: 'Nenhum pedido nesta fila.')
          else
            ...orders.map(
              (OrderSummary order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QueueOrderCard(order: order),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardOrderCard extends StatelessWidget {
  const _DashboardOrderCard({
    required this.order,
    required this.onStatusChanged,
  });

  final AdminDashboardOrder order;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final String selectedStatus = DisplayUtils.formatOrderStatus(order.status);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Pedido #${order.id}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              StatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cliente: ${order.customerName ?? 'Nao informado'}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Mesa: ${order.customerTable ?? 'N/A'}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Itens: ${order.totalItems}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Data: ${DisplayUtils.formatDateTime(order.createdAt)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            dropdownColor: const Color(0xFF1B0B2E),
            decoration: const InputDecoration(
              labelText: 'Atualizar status',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Color(0x14FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                borderSide: BorderSide.none,
              ),
            ),
            items: const <String>[
              'Recebido',
              'Em preparo',
              'Pronto',
              'Entregue',
            ].map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null && value != selectedStatus) {
                onStatusChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QueueOrderCard extends StatelessWidget {
  const _QueueOrderCard({
    required this.order,
  });

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Pedido #${order.id}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              StatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cliente: ${order.customerName ?? 'Nao informado'}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Mesa: ${order.customerTable ?? 'N/A'}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Data: ${DisplayUtils.formatDateTime(order.createdAt)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Total: ${DisplayUtils.formatCurrency(order.totalCents)}',
            style: const TextStyle(
              color: Color(0xFFF0ABFC),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (order.items.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            ...order.items.map(
              (OrderLineItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${item.quantity}x ${item.name}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.status,
    required this.isActive,
    this.onTap,
  });

  final String status;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String label = status.isEmpty ? 'Todos' : status;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF9333EA) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isError ? const Color(0xFFFDA4AF) : Colors.white70,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
