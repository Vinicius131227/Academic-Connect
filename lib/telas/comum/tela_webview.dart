// lib/telas/comum/tela_webview.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Requer pacote webview_flutter
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'WebView Genérica',
  type: TelaWebView,
)
Widget buildTelaWebView(BuildContext context) {
  return const ProviderScope(
    child: TelaWebView(
      url: 'https://flutter.dev', 
      titulo: 'Site Oficial Flutter'
    ),
  );
}

/// Tela que exibe um navegador web interno.
///
/// Usada para:
/// - Abrir links de materiais de aula.
/// - Assistir vídeos recomendados.
/// - Acessar documentos externos.
class TelaWebView extends StatefulWidget {
  final String url;
  final String titulo;

  const TelaWebView({
    super.key, 
    required this.url, 
    required this.titulo
  });

  @override
  State<TelaWebView> createState() => _TelaWebViewState();
}

class _TelaWebViewState extends State<TelaWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicializa o controlador da WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            // Tratamento básico de erro
            debugPrint("Erro na WebView: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titulo, 
          style: GoogleFonts.poppins(color: textColor, fontSize: 16)
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 1,
        actions: [
          // Botão de Recarregar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          )
        ],
      ),
      body: Stack(
        children: [
          // O Conteúdo Web
          WebViewWidget(controller: _controller),
          
          // Indicador de carregamento sobreposto
          if (_isLoading)
            const LinearProgressIndicator(
              color: AppColors.primaryPurple,
              backgroundColor: Colors.transparent,
            ),
        ],
      ),
    );
  }
}