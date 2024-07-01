
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../src/color.dart';

class Paginaantecedentes extends StatefulWidget {
  const Paginaantecedentes({super.key});

  @override
  State<Paginaantecedentes> createState() => _PaginaantecedentesState();
}

class _PaginaantecedentesState extends State<Paginaantecedentes> {
  double _progress = 0;
  late InAppWebViewController inAppWebViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: primary, size: 30),
        title: const Text("verificación Antecedentes"
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: Uri.parse('https://antecedentes.policia.gov.co:7005/WebJudicial/'),
            ),
            onWebViewCreated: (InAppWebViewController controller){
              inAppWebViewController = controller;
            },
            onProgressChanged:(InAppWebViewController controller, int progress) {
              setState(() {
                _progress = progress / 100;
              });

            },
          ),
          _progress < 1 ? Container(
            child: LinearProgressIndicator(
              backgroundColor: grisMedio,
              minHeight: 8,
              value: _progress,
            ),
          ): const SizedBox()
        ],
      ),
    );
  }
}


