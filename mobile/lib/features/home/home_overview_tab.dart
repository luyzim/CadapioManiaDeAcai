import 'package:flutter/material.dart';

import '../../core/config/project_info.dart';
import '../../core/models/client_session.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/remote_image.dart';

class HomeOverviewTab extends StatelessWidget {
  const HomeOverviewTab({
    super.key,
    required this.session,
    required this.onBrowseMenu,
    required this.onOpenCart,
    required this.onOpenOrders,
    required this.onOpenAbout,
  });

  final ClientSession session;
  final VoidCallback onBrowseMenu;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: <Widget>[
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x26D946EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Qualidade artesanal desde 2015',
                  style: TextStyle(
                    color: Color(0xFFF5D0FE),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Bem-vindo, ${_firstName(session.client.name)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'O melhor acai artesanal da cidade, agora em formato mobile.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Monte seu pedido, acompanhe o preparo e finalize tudo sem sair do app.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              GradientButton(
                label: 'Ver cardapio',
                onPressed: onBrowseMenu,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOpenCart,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Abrir carrinho'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0x33FFFFFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 240,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: RemoteImage(
                  imageUrl: '/img/loja_franquia4.png',
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  placeholderLabel: 'Loja ManiaDeAcai',
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0x0F0B0316),
                        Color(0xCC0B0316),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricChip(
                        icon: Icons.timer_outlined,
                        label: 'Aberto hoje ate 22h',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricChip(
                        icon: Icons.icecream_outlined,
                        label: 'Sabores e toppings',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const <Widget>[
            _FeatureChip(label: 'Ingredientes selecionados'),
            _FeatureChip(label: 'Opcoes sem lactose'),
            _FeatureChip(label: 'Retirada rapida'),
            _FeatureChip(label: 'Acompanhamento do pedido'),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: _QuickActionCard(
                icon: Icons.receipt_long_outlined,
                title: 'Meus pedidos',
                description: 'Consulte status e historico.',
                onTap: onOpenOrders,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.info_outline_rounded,
                title: 'Sobre',
                description: 'Equipe, disciplina e versao.',
                onTap: onOpenAbout,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InfoLine(
                icon: Icons.location_on_outlined,
                title: 'Endereco',
                value:
                    'Av. Pedro Duarte Amoroso, 3093 - Jardim Julia, Cravinhos - SP',
              ),
              SizedBox(height: 16),
              _InfoLine(
                icon: Icons.schedule_outlined,
                title: 'Horarios',
                value: 'Seg-Sab: 12h-22h | Dom: 14h-20h',
              ),
              SizedBox(height: 16),
              _InfoLine(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Contato',
                value: 'WhatsApp: (13) 99629-6452 | Instagram: @maniadeacaicravinhos',
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
                'Projeto academico',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                ProjectInfo.objective,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Versao ${ProjectInfo.appVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFF0ABFC),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _firstName(String fullName) {
    final List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'cliente' : parts.first;
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x8A0B0316),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFFF0ABFC)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: const Color(0xFFF0ABFC)),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFFF0ABFC)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
