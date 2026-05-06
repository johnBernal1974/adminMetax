import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;

  const AudioPlayerWidget({super.key, required this.url});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;

  bool isPlaying = false;
  bool isLoading = true;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      final loadedDuration = await _player.setUrl(widget.url);

      if (!mounted) return;

      setState(() {
        duration = loadedDuration ?? Duration.zero;
        isLoading = false;
      });

      _player.positionStream.listen((p) {
        if (mounted) {
          setState(() => position = p);
        }
      });

      _player.durationStream.listen((d) {
        if (mounted && d != null) {
          setState(() => duration = d);
        }
      });

      _player.playerStateStream.listen((state) {
        if (!mounted) return;

        setState(() {
          isPlaying = state.playing;
        });

        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      });
    } catch (e) {
      print("❌ Error cargando audio: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> togglePlay() async {
    if (isLoading) return;

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = duration.inSeconds == 0 ? 1.0 : duration.inSeconds.toDouble();
    final currentSeconds = position.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: togglePlay,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: currentSeconds,
                    min: 0,
                    max: maxSeconds,
                    onChanged: isLoading
                        ? null
                        : (value) {
                      _player.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        format(position),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        format(duration),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}