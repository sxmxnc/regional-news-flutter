import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({this.rows = 6, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (_, _) => const LoadingPlaceholderRow(),
    );
  }
}

class LoadingPlaceholderRow extends StatelessWidget {
  const LoadingPlaceholderRow({super.key});

  @override
  Widget build(BuildContext context) {
    // Die Farbe kommt aus dem Theme, nicht aus dem Widget (README.md,
    // Konventionen) — und ändert sich damit später mit dem Farbschema mit.
    final Color color = Theme.of(context).dividerColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _bar(color, width: 90, height: 10),
        const SizedBox(height: 8),
        _bar(color, width: double.infinity, height: 16),
        const SizedBox(height: 6),
        _bar(color, width: 220, height: 16),
      ],
    );
  }

  Widget _bar(Color color, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
