import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/admin_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/cart_store.dart';
import '../features/admin/admin_page.dart';
import '../features/about/about_page.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/home/home_page.dart';
import '../features/orders/checkout_page.dart';
import '../features/orders/order_details_page.dart';
import 'admin_session_controller.dart';
import 'cart_controller.dart';
import 'session_controller.dart';

class ManiaDeAcaiApp extends StatefulWidget {
  const ManiaDeAcaiApp({super.key});

  @override
  State<ManiaDeAcaiApp> createState() => _ManiaDeAcaiAppState();
}

class _ManiaDeAcaiAppState extends State<ManiaDeAcaiApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final SessionController _sessionController;
  late final CartController _cartController;
  late final AdminSessionController _adminSessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = SessionController(AuthService())
      ..addListener(_syncNavigation)
      ..restoreSession();
    _cartController = CartController(CartStore())..restoreCart();
    _adminSessionController = AdminSessionController(AdminService())
      ..restoreSession();
  }

  @override
  void dispose() {
    _sessionController
      ..removeListener(_syncNavigation)
      ..dispose();
    _cartController.dispose();
    _adminSessionController.dispose();
    super.dispose();
  }

  void _syncNavigation() {
    if (!_sessionController.isReady) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncNavigation());
      return;
    }

    final targetRoute = _sessionController.isAuthenticated
        ? HomePage.routeName
        : LoginPage.routeName;

    navigator.pushNamedAndRemoveUntil(targetRoute, (Route<dynamic> _) => false);
  }

  Route<dynamic> _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case LoginPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case SignUpPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SignUpPage(),
          settings: settings,
        );
      case ForgotPasswordPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordPage(),
          settings: settings,
        );
      case AboutPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AboutPage(),
          settings: settings,
        );
      case HomePage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case CheckoutPage.routeName:
        return MaterialPageRoute<String?>(
          builder: (_) => const CheckoutPage(),
          settings: settings,
        );
      case OrderDetailsPage.routeName:
        final String? orderId = settings.arguments as String?;

        return MaterialPageRoute<void>(
          builder: (_) => orderId == null || orderId.trim().isEmpty
              ? const _RouteErrorPage(
                  title: 'Pedido invalido',
                  message: 'Nao foi possivel abrir os detalhes do pedido.',
                )
              : OrderDetailsPage(orderId: orderId),
          settings: settings,
        );
      case AdminPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const _SplashPage(),
          settings: settings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<SessionController>.value(
          value: _sessionController,
        ),
        ChangeNotifierProvider<CartController>.value(
          value: _cartController,
        ),
        ChangeNotifierProvider<AdminSessionController>.value(
          value: _adminSessionController,
        ),
      ],
      child: MaterialApp(
        title: 'ManiaDeAcai',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        initialRoute: '/',
        onGenerateRoute: _buildRoute,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0B0316),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9333EA),
            brightness: Brightness.dark,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF0ABFC),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          appBarTheme: const AppBarTheme(
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
