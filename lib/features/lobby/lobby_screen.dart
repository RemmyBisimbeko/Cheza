import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/online_provider.dart';
import '../../providers/setup_provider.dart';
import '../../services/online_service.dart';
import '../../core/constants/app_theme.dart';


class LobbyScreen extends ConsumerStatefulWidget {
  final bool isHost;
  const LobbyScreen({super.key, required this.isHost});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final setup = ref.read(setupProvider);
      final service = ref.read(onlineServiceProvider);
      final roomId = await service.createRoom(
        setup.playerName,
        setup.playerCount,
        setup.gameType,
      );

      // Get room code from Firestore
      final code = await service.getRoomCode(roomId);

      ref.read(roomIdProvider.notifier).state = roomId;
      ref.read(roomCodeProvider.notifier).state = code;

      if (mounted) context.go('/lobby/waiting');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() {
        _error = 'Enter a valid 6-character code';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final setup = ref.read(setupProvider);
      final service = ref.read(onlineServiceProvider);
      final roomId = await service.joinRoom(code, setup.playerName);

      if (roomId == null) {
        setState(() {
          _error = 'Room not found or is full';
        });
        return;
      }

      ref.read(roomIdProvider.notifier).state = roomId;
      if (mounted) context.go('/lobby/waiting');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.tableGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textLight),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Online Game',
          style: TextStyle(color: AppTheme.accent),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Create Room
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _createRoom,
                icon: const Icon(Icons.add),
                label: const Text('Create Room'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider(color: AppTheme.textDim)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: AppTheme.textDim)),
                ),
                Expanded(child: Divider(color: AppTheme.textDim)),
              ],
            ),
            const SizedBox(height: 24),

            // Join Room
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'ROOM CODE',
                hintStyle: const TextStyle(
                  color: AppTheme.textDim,
                  letterSpacing: 4,
                ),
                counterText: '',
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.accent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _joinRoom,
                icon: const Icon(Icons.login, color: AppTheme.textLight),
                label: const Text(
                  'Join Room',
                  style: TextStyle(color: AppTheme.textLight),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.textDim),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],

            if (_loading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppTheme.accent),
            ],
          ],
        ),
      ),
    );
  }
}
