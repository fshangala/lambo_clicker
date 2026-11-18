import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/lambo_socket_service.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class AppViewModel extends ChangeNotifier {
  AppViewModel({LamboSocketService? socketService, Logger? logger})
    : _socketService = socketService ?? LamboSocketService(),
      _logger = logger ?? Logger();

  static const _roomKey = 'room_code';
  static final _roomPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
  static final _hostPattern = RegExp(r'^[a-zA-Z0-9.:-]+$');

  final LamboSocketService _socketService;
  final Logger _logger;
  SharedPreferences? _preferences;
  String? _host;
  int? _port;
  WebSocket? _socket;
  int _generation = 0;
  bool _disposed = false;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _connectionMessage;
  String? _configurationError;
  String _savedRoom = '';

  ConnectionStatus get status => _status;
  String? get connectionMessage => _connectionMessage;
  String? get configurationError => _configurationError;
  String get savedRoom => _savedRoom;
  bool get canConnect => _configurationError == null;

  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      final host = dotenv.env['HOST']?.trim() ?? '';
      final port = int.tryParse(dotenv.env['PORT']?.trim() ?? '');
      if (host.isEmpty || !_hostPattern.hasMatch(host)) {
        throw const FormatException('HOST must be a hostname or IP address.');
      }
      if (port == null || port < 1 || port > 65535) {
        throw const FormatException('PORT must be between 1 and 65535.');
      }
      final uri = Uri(scheme: 'ws', host: host, port: port);
      if (uri.host.isEmpty) {
        throw const FormatException('HOST must be a hostname or IP address.');
      }
      _host = host;
      _port = port;
      _preferences = await SharedPreferences.getInstance();
      _savedRoom = _preferences!.getString(_roomKey) ?? '';
    } on FileNotFoundError catch (error, stackTrace) {
      _failInitialization(error, stackTrace);
    } on EmptyEnvFileError catch (error, stackTrace) {
      _failInitialization(error, stackTrace);
    } on FormatException catch (error, stackTrace) {
      _failInitialization(error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      _failInitialization(error, stackTrace);
    } on MissingPluginException catch (error, stackTrace) {
      _failInitialization(error, stackTrace);
    }
  }

  void _failInitialization(Object error, StackTrace stackTrace) {
    _logger.e(
      'Failed to initialize app configuration',
      error: error,
      stackTrace: stackTrace,
    );
    _configurationError =
        'Could not load configuration or saved settings. Check .env and restart the app. ($error)';
    _status = ConnectionStatus.error;
    _connectionMessage = _configurationError;
  }

  Future<void> connect(String roomInput) async {
    if (!canConnect ||
        _status == ConnectionStatus.connecting ||
        _status == ConnectionStatus.connected) {
      return;
    }
    final room = roomInput.trim();
    if (!_roomPattern.hasMatch(room)) {
      _status = ConnectionStatus.error;
      _connectionMessage =
          'Enter a room code using letters, numbers, hyphens, or underscores.';
      notifyListeners();
      return;
    }

    final generation = ++_generation;
    _status = ConnectionStatus.connecting;
    _connectionMessage = null;
    notifyListeners();
    try {
      final saved = await _preferences!.setString(_roomKey, room);
      if (!saved) {
        throw StateError('The room code could not be saved.');
      }
      if (!_isCurrent(generation)) return;
      _savedRoom = room;
      final uri = Uri(
        scheme: 'ws',
        host: _host!,
        port: _port!,
        pathSegments: ['ws', 'pcautomation', room],
        queryParameters: {'role': 'master'},
      );
      final future = _socketService.connect(uri).then((socket) {
        if (!_isCurrent(generation)) {
          unawaited(_closeSocket(socket));
          return null;
        }
        return socket;
      });
      final socket = await future.timeout(const Duration(seconds: 30));
      if (socket == null) return;
      if (!_isCurrent(generation)) {
        unawaited(_closeSocket(socket));
        return;
      }
      _socket = socket;
      socket.listen(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          if (!_isCurrent(generation)) return;
          _logger.e('WebSocket error', error: error, stackTrace: stackTrace);
          _generation++;
          _socket = null;
          _status = ConnectionStatus.error;
          _connectionMessage = 'Connection error. Retry to reconnect.';
          unawaited(_closeSocket(socket));
          notifyListeners();
        },
        onDone: () {
          if (!_isCurrent(generation)) return;
          _socket = null;
          _status = ConnectionStatus.disconnected;
          _connectionMessage = 'Connection closed. Connect to rejoin the room.';
          notifyListeners();
        },
        cancelOnError: true,
      );
      _status = ConnectionStatus.connected;
      _connectionMessage = null;
      notifyListeners();
    } on IOException catch (error, stackTrace) {
      _failConnection(generation, error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      _failConnection(generation, error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      _failConnection(generation, error, stackTrace);
    } on MissingPluginException catch (error, stackTrace) {
      _failConnection(generation, error, stackTrace);
    } on StateError catch (error, stackTrace) {
      _failConnection(generation, error, stackTrace);
    }
  }

  void _failConnection(int generation, Object error, StackTrace stackTrace) {
    if (!_isCurrent(generation)) return;
    _generation++;
    _logger.e('Failed to connect', error: error, stackTrace: stackTrace);
    _status = ConnectionStatus.error;
    _connectionMessage =
        'Could not connect or save the room. Check settings and retry.';
    notifyListeners();
  }

  void disconnect() {
    _generation++;
    final socket = _socket;
    _socket = null;
    _status = ConnectionStatus.disconnected;
    _connectionMessage = null;
    if (socket != null) unawaited(_closeSocket(socket));
    notifyListeners();
  }

  String? sendClick() {
    final socket = _socket;
    if (_status != ConnectionStatus.connected || socket == null) {
      return 'Click not sent: connect to a room first.';
    }
    try {
      socket.add(
        jsonEncode({'event': 'click', 'payload': <String, dynamic>{}}),
      );
      return null;
    } on IOException catch (error, stackTrace) {
      return _failSend(socket, error, stackTrace);
    } on StateError catch (error, stackTrace) {
      return _failSend(socket, error, stackTrace);
    }
  }

  String _failSend(WebSocket socket, Object error, StackTrace stackTrace) {
    _logger.e('Failed to send click', error: error, stackTrace: stackTrace);
    _generation++;
    _socket = null;
    _status = ConnectionStatus.error;
    _connectionMessage = 'Failed to send click. Retry the connection.';
    unawaited(_closeSocket(socket));
    notifyListeners();
    return 'Click not sent: connection failed.';
  }

  void logVolumeError(Object error, StackTrace stackTrace) {
    _logger.e(
      'Volume-up listener failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<void> _closeSocket(WebSocket socket) async {
    try {
      await socket.close();
    } on IOException catch (error, stackTrace) {
      _logger.e(
        'Failed to close WebSocket',
        error: error,
        stackTrace: stackTrace,
      );
    } on StateError catch (error, stackTrace) {
      _logger.e(
        'Failed to close WebSocket',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    final socket = _socket;
    _socket = null;
    if (socket != null) unawaited(_closeSocket(socket));
    super.dispose();
  }
}
