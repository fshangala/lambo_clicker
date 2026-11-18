import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/volume_up_service.dart';
import '../view_models/app_view_model.dart';

class MobileHome extends StatefulWidget {
  const MobileHome({super.key});

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  late final TextEditingController _roomController;
  late final StreamSubscription<dynamic> _volumeSubscription;
  String? _volumeError;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppViewModel>();
    _roomController = TextEditingController(text: app.savedRoom);
    _volumeSubscription = VolumeUpService().presses.listen(
      (_) {
        final message = app.sendClick();
        if (message != null && mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        app.logVolumeError(error, stackTrace);
        if (mounted) {
          setState(() {
            _volumeError = 'Volume-up listener unavailable. Restart the app.';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    unawaited(_volumeSubscription.cancel());
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (label, icon, color) = switch (app.status) {
      ConnectionStatus.disconnected => (
        'Disconnected',
        Icons.cloud_off,
        colorScheme.onSurfaceVariant,
      ),
      ConnectionStatus.connecting => (
        'Connecting',
        Icons.sync,
        colorScheme.primary,
      ),
      ConnectionStatus.connected => (
        'Connected',
        Icons.cloud_done,
        colorScheme.primary,
      ),
      ConnectionStatus.error => (
        'Connection error',
        Icons.error_outline,
        colorScheme.error,
      ),
    };
    final busy = app.status == ConnectionStatus.connecting;
    final connected = app.status == ConnectionStatus.connected;

    return Scaffold(
      appBar: AppBar(title: const Text('Lambo Clicker')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Remote clicker', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Connect to a room, then press volume up while this app is in the foreground to send a click.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (app.connectionMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        app.connectionMessage!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (_volumeError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _volumeError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _roomController,
              enabled: !busy && !connected && app.canConnect,
              decoration: const InputDecoration(
                labelText: 'Room code',
                helperText: 'Use the same room code as the desktop client.',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => app.connect(_roomController.text),
            ),
            const SizedBox(height: 16),
            if (connected || busy)
              OutlinedButton.icon(
                onPressed: app.disconnect,
                icon: const Icon(Icons.link_off),
                label: Text(busy ? 'Cancel' : 'Disconnect'),
              )
            else
              FilledButton.icon(
                onPressed: app.canConnect
                    ? () => app.connect(_roomController.text)
                    : null,
                icon: const Icon(Icons.link),
                label: Text(
                  app.status == ConnectionStatus.error
                      ? 'Retry connection'
                      : 'Connect',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
