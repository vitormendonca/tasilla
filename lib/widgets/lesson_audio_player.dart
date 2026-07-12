import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class LessonAudioPlayer extends StatefulWidget {
  final String audioPath;
  final String transcript;
  final int maxPlays;
  final bool allowTranscript;

  const LessonAudioPlayer({
    super.key,
    required this.audioPath,
    required this.transcript,
    required this.maxPlays,
    required this.allowTranscript,
  });

  @override
  State<LessonAudioPlayer> createState() => _LessonAudioPlayerState();
}

class _LessonAudioPlayerState extends State<LessonAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _state = PlayerState.stopped;
  int _playCount = 0;
  bool _showTranscript = false;
  String? _error;

  String get _assetPath => widget.audioPath.startsWith('assets/')
      ? widget.audioPath.substring('assets/'.length)
      : widget.audioPath;

  bool get _canStartNewPlay => _playCount < widget.maxPlays;
  bool get _transcriptAvailable =>
      widget.allowTranscript || _playCount >= widget.maxPlays;

  @override
  void initState() {
    super.initState();
    _subscriptions.add(
      _player.onDurationChanged.listen((value) {
        if (mounted) setState(() => _duration = value);
      }),
    );
    _subscriptions.add(
      _player.onPositionChanged.listen((value) {
        if (mounted) setState(() => _position = value);
      }),
    );
    _subscriptions.add(
      _player.onPlayerStateChanged.listen((value) {
        if (mounted) setState(() => _state = value);
      }),
    );
    _subscriptions.add(
      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _state = PlayerState.completed;
            _position = _duration;
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      setState(() => _error = null);
      if (_state == PlayerState.playing) {
        await _player.pause();
        return;
      }
      if (_state == PlayerState.paused) {
        await _player.resume();
        return;
      }
      if (!_canStartNewPlay) return;

      await _player.play(AssetSource(_assetPath));
      if (mounted) {
        setState(() {
          _playCount++;
          _position = Duration.zero;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Audio unavailable for this lesson.');
      }
    }
  }

  String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? const Color(0xFFF5F5F0)
        : const Color(0xFF1A1A1A);
    final textMuted = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF706D67);
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    final canPlay =
        _state == PlayerState.playing ||
        _state == PlayerState.paused ||
        _canStartNewPlay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              key: const ValueKey('lesson_audio_toggle'),
              tooltip: _state == PlayerState.playing
                  ? 'Pause audio'
                  : 'Play audio',
              onPressed: canPlay ? _togglePlayback : null,
              icon: Icon(
                _state == PlayerState.playing ? Icons.pause : Icons.play_arrow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text(
                    '${_time(_position)} / ${_time(_duration)}  ·  '
                    'Play $_playCount of ${widget.maxPlays}',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
        const SizedBox(height: 8),
        if (_transcriptAvailable)
          TextButton.icon(
            onPressed: () => setState(() => _showTranscript = !_showTranscript),
            icon: Icon(
              _showTranscript
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17,
            ),
            label: Text(
              _showTranscript ? 'Hide transcript' : 'Show transcript',
            ),
          )
        else
          Text(
            'The transcript unlocks after the listening questions or all plays.',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        if (_showTranscript && _transcriptAvailable) ...[
          const SizedBox(height: 6),
          Text(
            widget.transcript,
            style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
          ),
        ],
      ],
    );
  }
}
