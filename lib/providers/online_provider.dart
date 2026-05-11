import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/online_service.dart';
import '../core/models/playing_card.dart';
import '../core/constants/enums.dart';

// Add this import at top of online_service.dart too
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Room ID currently joined/hosting
final roomIdProvider = StateProvider<String?>((ref) => null);

// Room code to display to host
final roomCodeProvider = StateProvider<String?>((ref) => null);

// Live room data stream
final roomStreamProvider = StreamProvider.family<Map<String, dynamic>, String>((
  ref,
  roomId,
) {
  return ref.watch(onlineServiceProvider).roomStream(roomId);
});

// Live hand stream
final myHandStreamProvider = StreamProvider.family<List<PlayingCard>, String>((
  ref,
  roomId,
) {
  return ref.watch(onlineServiceProvider).myHandStream(roomId);
});
