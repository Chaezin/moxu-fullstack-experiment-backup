import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'voice/speech_recognition_service.dart';
import 'voice/voice_bridge_protocol.dart';
import 'voice/voice_input_controller.dart';

class StandardWebViewPage extends StatefulWidget {
  const StandardWebViewPage({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<StandardWebViewPage> createState() => _StandardWebViewPageState();
}

class _StandardWebViewPageState extends State<StandardWebViewPage> {
  late final WebViewController _controller;
  late final VoiceInputController _voiceController;
  int _progress = 0;
  bool _canGoBack = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _voiceController = VoiceInputController(
      service: DeviceSpeechRecognitionService(),
      emit: (event) {
        _emitVoiceEvent(event);
      },
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ShiguangVoiceBridge',
        onMessageReceived: (message) => _handleVoiceMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _error = null;
              _progress = 0;
            });
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageFinished: (_) async {
            if (Platform.isIOS) {
              await _controller.runJavaScript('''
                (() => {
                  const viewport = document.querySelector('meta[name="viewport"]');
                  if (viewport) {
                    viewport.setAttribute(
                      'content',
                      'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover'
                    );
                  }
                  if (!document.getElementById('shiguang-ios-webview-fix')) {
                    const style = document.createElement('style');
                    style.id = 'shiguang-ios-webview-fix';
                    style.textContent = 'input, textarea, select { font-size: 16px !important; }';
                    document.head.appendChild(style);
                  }
                  const resetInitialFocus = () => {
                    if (document.activeElement instanceof HTMLElement) {
                      document.activeElement.blur();
                    }
                    window.scrollTo(0, 0);
                  };
                  resetInitialFocus();
                  setTimeout(resetInitialFocus, 500);
                })();
              ''');
            }
            final canGoBack = await _controller.canGoBack();
            if (mounted) {
              setState(() {
                _progress = 100;
                _canGoBack = canGoBack;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            setState(() => _error = error.description);
          },
        ),
      );
    _loadInitialPage();
  }

  @override
  void dispose() {
    _voiceController.dispose();
    super.dispose();
  }

  Future<void> _emitVoiceEvent(Map<String, Object?> event) =>
      _controller.runJavaScript(
        'window.ShiguangVoiceInput?.receive(${jsonEncode(event)});',
      );

  Future<void> _handleVoiceMessage(String message) async {
    try {
      final command = VoiceBridgeCommand.parseJson(message);
      switch (command.type) {
        case VoiceCommandType.start:
          await _voiceController.start(
            sessionId: command.sessionId,
            preferredLocale: command.preferredLocale,
          );
        case VoiceCommandType.stop:
          await _voiceController.stop(sessionId: command.sessionId);
        case VoiceCommandType.cancel:
          await _voiceController.cancel(sessionId: command.sessionId);
      }
    } on FormatException {
      await _emitVoiceEvent({
        'type': 'voice.error',
        'code': 'invalid_command',
      });
    }
  }

  Future<void> _loadInitialPage() async {
    await _controller.clearCache();
    await _controller.loadFlutterAsset(widget.assetPath);
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      if (mounted) setState(() => _canGoBack = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_canGoBack,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _handleBack();
    },
    child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: WebViewWidget(controller: _controller)),
            if (_progress < 100)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 2,
                  color: const Color(0xFF2C695C),
                  backgroundColor: Colors.transparent,
                ),
              ),
            if (_error != null)
              _WebViewError(
                message: _error!,
                onRetry: _loadInitialPage,
              ),
          ],
        ),
      ),
    ),
  );
}

class _WebViewError extends StatelessWidget {
  const _WebViewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFFFFDF8),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 46),
            const SizedBox(height: 16),
            const Text('页面暂时无法加载', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('重新加载')),
          ],
        ),
      ),
    ),
  );
}
