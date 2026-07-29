import 'package:flutter/material.dart';

/// Rectángulo con un pulso de opacidad suave, para placeholders de
/// carga ("skeleton"). Si el usuario tiene activado "reducir
/// movimiento", se queda en opacidad fija sin animar.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 0.9,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget box(double opacity) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );

    if (reduceMotion) return box(0.7);

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => box(_opacity.value),
    );
  }
}

/// Placeholder con la silueta de una tarjeta de partido, para mostrar
/// mientras carga la lista real.
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 44, height: 44, borderRadius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 140, height: 16),
                      SizedBox(height: 8),
                      SkeletonBox(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SkeletonBox(width: 90, height: 28, borderRadius: 8),
                SkeletonBox(width: 70, height: 28, borderRadius: 8),
                SkeletonBox(width: 60, height: 28, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonBox(height: 8, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}

/// Placeholder con la silueta de una tarjeta de jugador.
class PlayerCardSkeleton extends StatelessWidget {
  const PlayerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SkeletonBox(width: 56, height: 56, borderRadius: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 160, height: 17),
                  SizedBox(height: 10),
                  SkeletonBox(width: 110, height: 20, borderRadius: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de placeholders separados, como la lista real que sustituyen.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, required this.itemBuilder, this.count = 4});

  final WidgetBuilder itemBuilder;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => itemBuilder(context),
    );
  }
}
