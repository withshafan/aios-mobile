import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/browser_service.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          context.read<BrowserService>().setLoading(true);
          _urlController.text = url;
        },
        onPageFinished: (url) {
          context.read<BrowserService>().setLoading(false);
          _urlController.text = url;
        },
        onWebResourceError: (error) {
          context.read<BrowserService>().setLoading(false);
        },
      ));

    // Listen to initial URL from service
    final browserService = context.read<BrowserService>();
    _loadUrl(browserService.url);
    _urlController.text = browserService.url;
  }

  void _loadUrl(String url) {
    final validUrl = url.startsWith('http://') || url.startsWith('https://') ? url : 'https://$url';
    _controller.loadRequest(Uri.parse(validUrl));
  }

  void _onSubmit(String value) {
    _loadUrl(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final browserService = context.watch<BrowserService>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (await _controller.canGoBack()) {
                    await _controller.goBack();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () async {
                  if (await _controller.canGoForward()) {
                    await _controller.goForward();
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: 'Enter URL or search',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onSubmitted: _onSubmit,
                  keyboardType: TextInputType.url,
                ),
              ),
              if (browserService.isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: WebViewWidget(controller: _controller),
        ),
      ],
    );
  }
}
