import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/cart_controller.dart';
import '../../app/session_controller.dart';
import '../../shared/widgets/brand_background.dart';
import '../about/about_page.dart';
import '../cart/cart_page.dart';
import '../menu/menu_page.dart';
import '../orders/checkout_page.dart';
import '../orders/my_orders_page.dart';
import '../orders/order_details_page.dart';
import 'home_overview_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  Future<void> _openCheckout() async {
    final Object? result =
        await Navigator.of(context).pushNamed(CheckoutPage.routeName);
    final String? createdOrderId = result as String?;

    if (!mounted || createdOrderId == null || createdOrderId.isEmpty) {
      return;
    }

    await Navigator.of(context).pushNamed(
      OrderDetailsPage.routeName,
      arguments: createdOrderId,
    );

    if (mounted) {
      setState(() => _currentIndex = 3);
    }
  }

  void _openOrderDetails(String orderId) {
    Navigator.of(context).pushNamed(
      OrderDetailsPage.routeName,
      arguments: orderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = context.watch<SessionController>();
    final CartController cartController = context.watch<CartController>();
    final session = sessionController.session;

    if (session == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0316),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> tabs = <Widget>[
      HomeOverviewTab(
        session: session,
        onBrowseMenu: () => setState(() => _currentIndex = 1),
        onOpenCart: () => setState(() => _currentIndex = 2),
        onOpenOrders: () => setState(() => _currentIndex = 3),
        onOpenAbout: () => Navigator.of(context).pushNamed(AboutPage.routeName),
      ),
      const MenuPage(),
      CartPage(
        onBrowseMenu: () => setState(() => _currentIndex = 1),
        onCheckout: _openCheckout,
      ),
      MyOrdersPage(
        onOpenOrder: _openOrderDetails,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0316),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_titleForIndex(_currentIndex)),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AboutPage.routeName);
            },
            tooltip: 'Sobre o projeto',
            icon: const Icon(Icons.info_outline_rounded),
          ),
          PopupMenuButton<_HomeMenuAction>(
            onSelected: (_HomeMenuAction action) {
              switch (action) {
                case _HomeMenuAction.admin:
                  Navigator.of(context).pushNamed('/admin');
                  break;
                case _HomeMenuAction.signOut:
                  context.read<SessionController>().signOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<_HomeMenuAction>>[
              PopupMenuItem<_HomeMenuAction>(
                value: _HomeMenuAction.admin,
                child: Text('Painel admin'),
              ),
              PopupMenuItem<_HomeMenuAction>(
                value: _HomeMenuAction.signOut,
                child: Text('Sair'),
              ),
            ],
          ),
        ],
      ),
      body: BrandBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0x1AFFFFFF)),
          ),
          color: Color(0xFF14091F),
        ),
        child: NavigationBar(
          height: 78,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0x269333EA),
          selectedIndex: _currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (int index) {
            setState(() => _currentIndex = index);
          },
          destinations: <Widget>[
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu_rounded),
              label: 'Cardapio',
            ),
            NavigationDestination(
              icon: _CartIconBadge(count: cartController.itemCount),
              selectedIcon: _CartIconBadge(
                count: cartController.itemCount,
                selected: true,
              ),
              label: 'Carrinho',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Pedidos',
            ),
          ],
        ),
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'ManiaDeAcai';
      case 1:
        return 'Cardapio';
      case 2:
        return 'Carrinho';
      case 3:
        return 'Meus pedidos';
      default:
        return 'ManiaDeAcai';
    }
  }
}

enum _HomeMenuAction {
  admin,
  signOut,
}

class _CartIconBadge extends StatelessWidget {
  const _CartIconBadge({
    required this.count,
    this.selected = false,
  });

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          selected ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined,
        ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFBE185D),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
