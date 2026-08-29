import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter_windows/webview_flutter_windows.dart';

import 'voice/speech_recognition_service.dart';
import 'voice/voice_bridge_protocol.dart';
import 'voice/voice_input_controller.dart';
import 'voice/windows_web_assets.dart';

class WindowsWebViewPage extends StatefulWidget {
  const WindowsWebViewPage({super.key});

  @override
  State<WindowsWebViewPage> createState() => _WindowsWebViewPageState();
}

class _WindowsWebViewPageState extends State<WindowsWebViewPage> {
  final WebviewController _controller = WebviewController();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  late final VoiceInputController _voiceController;
  bool _loading = true;
  bool _canGoBack = false;
  String? _error;
  String _pageUrl = '';

  static const _appUrl = '$windowsWebOrigin/index.html';

  @override
  void initState() {
    super.initState();
    _voiceController = VoiceInputController(
      service: DeviceSpeechRecognitionService(),
      emit: _emitVoiceEvent,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      _subscriptions
        ..add(
          _controller.loadingState.listen((state) {
            if (!mounted) return;
            setState(() => _loading = state == LoadingState.loading);
          }),
        )
        ..add(
          _controller.historyChanged.listen((history) {
            if (mounted) setState(() => _canGoBack = history.canGoBack);
          }),
        )
        ..add(
          _controller.onLoadError.listen((error) {
            if (mounted) setState(() => _error = error.name);
          }),
        )
        ..add(_controller.url.listen((url) => _pageUrl = url))
        ..add(
          _controller.webMessage.listen(
            _handleVoiceMessage,
            onError: (_) {},
          ),
        );
      await _controller.addVirtualHostNameMapping(
        windowsWebHost,
        windowsWebAssetRoot(Platform.resolvedExecutable),
        WebviewHostResourceAccessKind.deny,
      );
      await _loadApp();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _loadApp() async {
    _pageUrl = _appUrl;
    await _controller.loadUrl(_appUrl);
  }

  Future<void> _emitVoiceEvent(Map<String, Object?> event) =>
      _controller.postWebMessage(jsonEncode(event));

  Future<void> _handleVoiceMessage(Object? message) async {
    if (!_pageUrl.startsWith('$windowsWebOrigin/')) {
      return;
    }
    try {
      final command = message is String
          ? VoiceBridgeCommand.parseJson(message)
          : VoiceBridgeCommand.parse(message);
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

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _voiceController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_canGoBack,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _controller.goBack();
    },
    child: Scaffold(
      body: Stack(
        children: [
          if (_controller.value.isInitialized)
            Positioned.fill(child: Webview(_controller))
          else
            const Center(child: CircularProgressIndicator()),
          if (_loading && _controller.value.isInitialized)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_error != null)
            ColoredBox(
              color: const Color(0xFFFFFDF8),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 46),
                      const SizedBox(height: 16),
                      const Text('页面暂时无法加载'),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _loading = true;
                          });
                          _loadApp();
                        },
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
