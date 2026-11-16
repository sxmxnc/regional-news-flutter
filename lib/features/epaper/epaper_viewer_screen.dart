import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../ui/nav/area_navigation_bar.dart';

class EpaperViewerScreen extends StatelessWidget {
  const EpaperViewerScreen({
    required this.file,
    required this.title,
    super.key,
  });

  final File file;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(title)),
      body: PdfViewer.file(file.path),
    );
  }
}
