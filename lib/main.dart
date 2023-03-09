import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/screens/loading.dart';
import 'package:am_player/song_widget.dart';
import 'package:am_player/widget.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';


Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(MyApp(appRouter: AppRouter(),));
}


// var audioManagerInstance = AudioManager.instance;
// bool showVol = false;
// PlayMode playMode = audioManagerInstance.playMode;
// bool isPlaying = false;
// double? _slider;

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  const MyApp({super.key, required this.appRouter});
  //
  // Widget bottomPanel() {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(
  //           horizontal: 10,
  //         ),
  //         child: songProgress(context),
  //       ),
  //       Container(
  //         padding: const EdgeInsets.symmetric(
  //           vertical: 10,
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: [
  //             CircleAvatar(
  //               backgroundColor: Colors.cyan.withOpacity(0.3),
  //               child: Center(
  //                 child: IconButton(
  //                   icon: const Icon(
  //                     Icons.skip_previous,
  //                     color: Colors.white,
  //                   ),
  //                   onPressed: () => audioManagerInstance.previous(),
  //                 ),
  //               ),
  //             ),
  //             CircleAvatar(
  //               radius: 30,
  //               child: Center(
  //                 child: IconButton(
  //                   icon: Icon(
  //                     audioManagerInstance.isPlaying
  //                         ? Icons.pause
  //                         : Icons.play_arrow,
  //                     color: Colors.white,
  //                   ),
  //                   onPressed: () async {
  //                     audioManagerInstance.playOrPause();
  //                   },
  //                   padding: const EdgeInsets.all(0),
  //                 ),
  //               ),
  //             ),
  //             CircleAvatar(
  //               backgroundColor: Colors.cyan.withOpacity(0.3),
  //               child: Center(
  //                 child: IconButton(
  //                   icon: const Icon(
  //                     Icons.skip_next,
  //                     color: Colors.white,
  //                   ),
  //                   onPressed: () => audioManagerInstance.next(),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget songProgress(BuildContext context) {
  //   TextStyle style = const TextStyle(color: Colors.black);
  //   return Row(
  //     children: [
  //       Text(
  //         _formatDuration(audioManagerInstance.position),
  //         style: style,
  //       ),
  //       Expanded(
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(
  //             horizontal: 5,
  //           ),
  //           child: SliderTheme(
  //             data: SliderTheme.of(context).copyWith(
  //                 trackHeight: 2,
  //                 thumbColor: Colors.blueAccent,
  //                 overlayColor: Colors.blue,
  //                 thumbShape: const RoundSliderThumbShape(
  //                   disabledThumbRadius: 5,
  //                   enabledThumbRadius: 5,
  //                 ),
  //               overlayShape: const RoundSliderOverlayShape(overlayRadius: 10,),
  //               activeTrackColor: Colors.blueAccent,
  //
  //               inactiveTrackColor: Colors.grey,
  //             ),
  //             child: Slider(
  //               value: _slider??0,
  //               onChanged: (value){
  //                 setState(() {
  //                   _slider = value;
  //                 });
  //               },
  //               onChangeEnd: (value){
  //                 Duration mse = Duration(milliseconds: (audioManagerInstance.duration.inMilliseconds*value).round());
  //                 audioManagerInstance.seekTo(mse);
  //               },
  //             ),
  //           ),
  //         ),
  //       ),
  //       Text(
  //         _formatDuration(audioManagerInstance.duration),
  //         style: style,
  //       ),
  //     ],
  //   );
  // }
  //
  // String _formatDuration(Duration? d){
  //   if(d==null) return '--:--';
  //   int minute = d.inMinutes;
  //   int second = (d.inSeconds>60)? (d.inSeconds%60):d.inSeconds;
  //   String format = '${(minute<10)?'0$minute':'$minute'}:${(second<10)? '0$second':'$second'}';
  //   return format;
  // }
  //

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   setupAudio();
  // }
  // void setupAudio() {
  //   audioManagerInstance.onEvents((events, args) {
  //     switch (events) {
  //       case AudioManagerEvents.start:
  //         _slider = 0;
  //         break;
  //       case AudioManagerEvents.seekComplete:
  //         _slider = audioManagerInstance.position.inMilliseconds /
  //             audioManagerInstance.duration.inMilliseconds;
  //         setState(() {
  //
  //         });
  //         break;
  //       case AudioManagerEvents.playstatus:
  //         isPlaying = audioManagerInstance.isPlaying;
  //         setState(() {
  //
  //         });
  //         break;
  //       case AudioManagerEvents.timeupdate:
  //         _slider = audioManagerInstance.position.inMilliseconds /
  //             audioManagerInstance.duration.inMilliseconds;
  //         audioManagerInstance.updateLrc(args["position"].toString());
  //         setState(() {
  //
  //         });
  //         break;
  //       case AudioManagerEvents.ended:
  //         audioManagerInstance.next();
  //         setState(() {
  //
  //         });
  //         break;
  //       default:
  //         break;
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: appRouter.generateRoute,
    );
  }
  // Widget scaffold(){
  //   return Scaffold(
  //     drawer: const Drawer(),
  //     appBar: AppBar(
  //       actions: [
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: InkWell(
  //             onTap: () {
  //               setState(() {
  //                 showVol = !showVol;
  //               });
  //             },
  //             child: const IconText(
  //               textColor: Colors.white,
  //               iconColor: Colors.white,
  //               string: 'volume',
  //               iconSize: 20,
  //               iconData: Icons.volume_down,
  //             ),
  //           ),
  //         ),
  //       ],
  //       elevation: 0,
  //       backgroundColor: Colors.black,
  //       title: showVol
  //           ? Slider(
  //         value: audioManagerInstance.volume,
  //         onChanged: (value) {
  //           setState(() {
  //             audioManagerInstance.setVolume(value, showVolume: true);
  //           });
  //         },
  //       )
  //           : const Text('AM player'),
  //     ),
  //     body: Column(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Expanded(
  //           child: SingleChildScrollView(
  //             child: SizedBox(
  //               height: 700,
  //               child: FutureBuilder(
  //                 future: OnAudioQuery().querySongs(
  //                   sortType: SongSortType.TITLE,
  //                 ),
  //                 builder: (context, snapshot) {
  //                   List<SongModel>? songInfo = snapshot.data;
  //                   if (snapshot.hasData) return SongWidget(songList: songInfo!);
  //                   return SizedBox(
  //                     height: MediaQuery.of(context).size.height * 0.4,
  //                     child: Center(
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: const [
  //                           CircularProgressIndicator(),
  //                           SizedBox(
  //                             width: 20,
  //                           ),
  //                           Text(
  //                             'Loading...',
  //                             style: TextStyle(
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ),
  //         ),
  //         bottomPanel(),
  //       ],
  //     ),
  //   );
  // }
}









/*
*  import 'dart:async';
    import 'dart:math';

    import 'package:audio_service/audio_service.dart';
    import 'package:flutter/material.dart';
    import 'package:rxdart/rxdart.dart';
    import 'package:flutter/foundation.dart';
    import 'package:just_audio/just_audio.dart';
    import 'package:rxdart/rxdart.dart';

    // You might want to provide this using dependency injection rather than a
    // global variable.
    late AudioHandler _audioHandler;

    Future<void> main() async {
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
          androidNotificationChannelName: 'Audio playback',
          androidNotificationOngoing: true,
        ),
      );
      runApp(MyApp());
    }

    class MyApp extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          title: 'Audio Service Demo',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: MainScreen(),
        );
      }
    }

    class MainScreen extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Audio Service Demo'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Show media item title
                StreamBuilder<MediaItem?>(
                  stream: _audioHandler.mediaItem,
                  builder: (context, snapshot) {
                    final mediaItem = snapshot.data;
                    return Text(mediaItem?.title ?? '');
                  },
                ),
                // Play/pause/stop buttons.
                StreamBuilder<bool>(
                  stream: _audioHandler.playbackState
                      .map((state) => state.playing)
                      .distinct(),
                  builder: (context, snapshot) {
                    final playing = snapshot.data ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _button(Icons.fast_rewind, _audioHandler.rewind),
                        if (playing)
                          _button(Icons.pause, _audioHandler.pause)
                        else
                          _button(Icons.play_arrow, _audioHandler.play),
                        _button(Icons.stop, _audioHandler.stop),
                        _button(Icons.fast_forward, _audioHandler.fastForward),
                      ],
                    );
                  },
                ),
                // A seek bar.
                StreamBuilder<MediaState>(
                  stream: _mediaStateStream,
                  builder: (context, snapshot) {
                    final mediaState = snapshot.data;
                    return SeekBar(
                      duration: mediaState?.mediaItem?.duration ?? Duration.zero,
                      position: mediaState?.position ?? Duration.zero,
                      onChangeEnd: (newPosition) {
                        _audioHandler.seek(newPosition);
                      },
                    );
                  },
                ),
                // Display the processing state.
                StreamBuilder<AudioProcessingState>(
                  stream: _audioHandler.playbackState
                      .map((state) => state.processingState)
                      .distinct(),
                  builder: (context, snapshot) {
                    final processingState =
                        snapshot.data ?? AudioProcessingState.idle;
                    return Text(
                        "Processing state: ${describeEnum(processingState)}");
                  },
                ),
              ],
            ),
          ),
        );
      }

      /// A stream reporting the combined state of the current media item and its
      /// current position.
      Stream<MediaState> get _mediaStateStream =>
          Rx.combineLatest2<MediaItem?, Duration, MediaState>(
              _audioHandler.mediaItem,
              AudioService.position,
                  (mediaItem, position) => MediaState(mediaItem, position));

      IconButton _button(IconData iconData, VoidCallback onPressed) => IconButton(
        icon: Icon(iconData),
        iconSize: 64.0,
        onPressed: onPressed,
      );
    }

    class MediaState {
      final MediaItem? mediaItem;
      final Duration position;

      MediaState(this.mediaItem, this.position);
    }

    /// An [AudioHandler] for playing a single item.
    class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
      static final _item = MediaItem(
        id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
        album: "Science Friday",
        title: "A Salute To Head-Scratching Science",
        artist: "Science Friday and WNYC Studios",
        duration: const Duration(milliseconds: 5739820),
        artUri: Uri.parse(
            'https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg'),
      );

      final _player = AudioPlayer();

      /// Initialise our audio handler.
      AudioPlayerHandler() {
        // So that our clients (the Flutter UI and the system notification) know
        // what state to display, here we set up our audio handler to broadcast all
        // playback state changes as they happen via playbackState...
        _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
        // ... and also the current media item via mediaItem.
        mediaItem.add(_item);

        // Load the player.
        _player.setAudioSource(AudioSource.uri(Uri.parse(_item.id)));
      }

      // In this simple example, we handle only 4 actions: play, pause, seek and
      // stop. Any button press from the Flutter UI, notification, lock screen or
      // headset will be routed through to these 4 methods so that you can handle
      // your audio playback logic in one place.

      @override
      Future<void> play() => _player.play();

      @override
      Future<void> pause() => _player.pause();

      @override
      Future<void> seek(Duration position) => _player.seek(position);

      @override
      Future<void> stop() => _player.stop();

      /// Transform a just_audio event into an audio_service state.
      ///
      /// This method is used from the constructor. Every event received from the
      /// just_audio player will be transformed into an audio_service state so that
      /// it can be broadcast to audio_service clients.
      PlaybackState _transformEvent(PlaybackEvent event) {
        return PlaybackState(
          controls: [
            MediaControl.rewind,
            if (_player.playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.fastForward,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: _player.playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        );
      }
    }


    class PositionData {
      final Duration position;
      final Duration bufferedPosition;
      final Duration duration;

      PositionData(this.position, this.bufferedPosition, this.duration);
    }

    class SeekBar extends StatefulWidget {
      final Duration duration;
      final Duration position;
      final Duration bufferedPosition;
      final ValueChanged<Duration>? onChanged;
      final ValueChanged<Duration>? onChangeEnd;

      SeekBar({
        required this.duration,
        required this.position,
        this.bufferedPosition = Duration.zero,
        this.onChanged,
        this.onChangeEnd,
      });

      @override
      _SeekBarState createState() => _SeekBarState();
    }

    class _SeekBarState extends State<SeekBar> {
      double? _dragValue;
      bool _dragging = false;
      late SliderThemeData _sliderThemeData;

      @override
      void didChangeDependencies() {
        super.didChangeDependencies();

        _sliderThemeData = SliderTheme.of(context).copyWith(
          trackHeight: 2.0,
        );
      }

      @override
      Widget build(BuildContext context) {
        final value = min(
          _dragValue ?? widget.position.inMilliseconds.toDouble(),
          widget.duration.inMilliseconds.toDouble(),
        );
        if (_dragValue != null && !_dragging) {
          _dragValue = null;
        }
        return Stack(
          children: [
            SliderTheme(
              data: _sliderThemeData.copyWith(
                thumbShape: HiddenThumbComponentShape(),
                activeTrackColor: Colors.blue.shade100,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              child: ExcludeSemantics(
                child: Slider(
                  min: 0.0,
                  max: widget.duration.inMilliseconds.toDouble(),
                  value: min(widget.bufferedPosition.inMilliseconds.toDouble(),
                      widget.duration.inMilliseconds.toDouble()),
                  onChanged: (value) {},
                ),
              ),
            ),
            SliderTheme(
              data: _sliderThemeData.copyWith(
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(
                min: 0.0,
                max: widget.duration.inMilliseconds.toDouble(),
                value: value,
                onChanged: (value) {
                  if (!_dragging) {
                    _dragging = true;
                  }
                  setState(() {
                    _dragValue = value;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(Duration(milliseconds: value.round()));
                  }
                },
                onChangeEnd: (value) {
                  if (widget.onChangeEnd != null) {
                    widget.onChangeEnd!(Duration(milliseconds: value.round()));
                  }
                  _dragging = false;
                },
              ),
            ),
            Positioned(
              right: 16.0,
              bottom: 0.0,
              child: Text(
                  RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch("$_remaining")
                      ?.group(1) ??
                      '$_remaining',
                  style: Theme.of(context).textTheme.caption),
            ),
          ],
        );
      }

      Duration get _remaining => widget.duration - widget.position;
    }

    class HiddenThumbComponentShape extends SliderComponentShape {
      @override
      Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

      @override
      void paint(
          PaintingContext context,
          Offset center, {
            required Animation<double> activationAnimation,
            required Animation<double> enableAnimation,
            required bool isDiscrete,
            required TextPainter labelPainter,
            required RenderBox parentBox,
            required SliderThemeData sliderTheme,
            required TextDirection textDirection,
            required double value,
            required double textScaleFactor,
            required Size sizeWithOverflow,
          }) {}
    }

    class LoggingAudioHandler extends CompositeAudioHandler {
      LoggingAudioHandler(AudioHandler inner) : super(inner) {
        playbackState.listen((state) {
          _log('playbackState changed: $state');
        });
        queue.listen((queue) {
          _log('queue changed: $queue');
        });
        queueTitle.listen((queueTitle) {
          _log('queueTitle changed: $queueTitle');
        });
        mediaItem.listen((mediaItem) {
          _log('mediaItem changed: $mediaItem');
        });
        ratingStyle.listen((ratingStyle) {
          _log('ratingStyle changed: $ratingStyle');
        });
        androidPlaybackInfo.listen((androidPlaybackInfo) {
          _log('androidPlaybackInfo changed: $androidPlaybackInfo');
        });
        customEvent.listen((dynamic customEventStream) {
          _log('customEvent changed: $customEventStream');
        });
        customState.listen((dynamic customState) {
          _log('customState changed: $customState');
        });
      }

      // TODO: Use logger. Use different log levels.
      void _log(String s) => print('----- LOG: $s');

      @override
      Future<void> prepare() {
        _log('prepare()');
        return super.prepare();
      }

      @override
      Future<void> prepareFromMediaId(String mediaId,
          [Map<String, dynamic>? extras]) {
        _log('prepareFromMediaId($mediaId, $extras)');
        return super.prepareFromMediaId(mediaId, extras);
      }

      @override
      Future<void> prepareFromSearch(String query, [Map<String, dynamic>? extras]) {
        _log('prepareFromSearch($query, $extras)');
        return super.prepareFromSearch(query, extras);
      }

      @override
      Future<void> prepareFromUri(Uri uri, [Map<String, dynamic>? extras]) {
        _log('prepareFromSearch($uri, $extras)');
        return super.prepareFromUri(uri, extras);
      }

      @override
      Future<void> play() {
        _log('play()');
        return super.play();
      }

      @override
      Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) {
        _log('playFromMediaId($mediaId, $extras)');
        return super.playFromMediaId(mediaId, extras);
      }

      @override
      Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) {
        _log('playFromSearch($query, $extras)');
        return super.playFromSearch(query, extras);
      }

      @override
      Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) {
        _log('playFromUri($uri, $extras)');
        return super.playFromUri(uri, extras);
      }

      @override
      Future<void> playMediaItem(MediaItem mediaItem) {
        _log('playMediaItem($mediaItem)');
        return super.playMediaItem(mediaItem);
      }

      @override
      Future<void> pause() {
        _log('pause()');
        return super.pause();
      }

      @override
      Future<void> click([MediaButton button = MediaButton.media]) {
        _log('click($button)');
        return super.click(button);
      }

      @override
      Future<void> stop() {
        _log('stop()');
        return super.stop();
      }

      @override
      Future<void> addQueueItem(MediaItem mediaItem) {
        _log('addQueueItem($mediaItem)');
        return super.addQueueItem(mediaItem);
      }

      @override
      Future<void> addQueueItems(List<MediaItem> mediaItems) {
        _log('addQueueItems($mediaItems)');
        return super.addQueueItems(mediaItems);
      }

      @override
      Future<void> insertQueueItem(int index, MediaItem mediaItem) {
        _log('insertQueueItem($index, $mediaItem)');
        return super.insertQueueItem(index, mediaItem);
      }

      @override
      Future<void> updateQueue(List<MediaItem> queue) {
        _log('updateQueue($queue)');
        return super.updateQueue(queue);
      }

      @override
      Future<void> updateMediaItem(MediaItem mediaItem) {
        _log('updateMediaItem($mediaItem)');
        return super.updateMediaItem(mediaItem);
      }

      @override
      Future<void> removeQueueItem(MediaItem mediaItem) {
        _log('removeQueueItem($mediaItem)');
        return super.removeQueueItem(mediaItem);
      }

      @override
      Future<void> removeQueueItemAt(int index) {
        _log('removeQueueItemAt($index)');
        return super.removeQueueItemAt(index);
      }

      @override
      Future<void> skipToNext() {
        _log('skipToNext()');
        return super.skipToNext();
      }

      @override
      Future<void> skipToPrevious() {
        _log('skipToPrevious()');
        return super.skipToPrevious();
      }

      @override
      Future<void> fastForward() {
        _log('fastForward()');
        return super.fastForward();
      }

      @override
      Future<void> rewind() {
        _log('rewind()');
        return super.rewind();
      }

      @override
      Future<void> skipToQueueItem(int index) {
        _log('skipToQueueItem($index)');
        return super.skipToQueueItem(index);
      }

      @override
      Future<void> seek(Duration position) {
        _log('seek($position)');
        return super.seek(position);
      }

      @override
      Future<void> setRating(Rating rating, [Map<String, dynamic>? extras]) {
        _log('setRating($rating, $extras)');
        return super.setRating(rating, extras);
      }

      @override
      Future<void> setCaptioningEnabled(bool enabled) {
        _log('setCaptioningEnabled($enabled)');
        return super.setCaptioningEnabled(enabled);
      }

      @override
      Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
        _log('setRepeatMode($repeatMode)');
        return super.setRepeatMode(repeatMode);
      }

      @override
      Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) {
        _log('setShuffleMode($shuffleMode)');
        return super.setShuffleMode(shuffleMode);
      }

      @override
      Future<void> seekBackward(bool begin) {
        _log('seekBackward($begin)');
        return super.seekBackward(begin);
      }

      @override
      Future<void> seekForward(bool begin) {
        _log('seekForward($begin)');
        return super.seekForward(begin);
      }

      @override
      Future<void> setSpeed(double speed) {
        _log('setSpeed($speed)');
        return super.setSpeed(speed);
      }

      @override
      Future<dynamic> customAction(String name,
          [Map<String, dynamic>? extras]) async {
        _log('customAction($name, extras)');
        final dynamic result = await super.customAction(name, extras);
        _log('customAction -> $result');
        return result;
      }

      @override
      Future<void> onTaskRemoved() {
        _log('onTaskRemoved()');
        return super.onTaskRemoved();
      }

      @override
      Future<void> onNotificationDeleted() {
        _log('onNotificationDeleted()');
        return super.onNotificationDeleted();
      }

      @override
      Future<List<MediaItem>> getChildren(String parentMediaId,
          [Map<String, dynamic>? options]) async {
        _log('getChildren($parentMediaId, $options)');
        final result = await super.getChildren(parentMediaId, options);
        _log('getChildren -> $result');
        return result;
      }

      @override
      ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
        _log('subscribeToChildren($parentMediaId)');
        final result = super.subscribeToChildren(parentMediaId);
        result.listen((options) {
          _log('$parentMediaId children changed with options $options');
        });
        return result;
      }

      @override
      Future<MediaItem?> getMediaItem(String mediaId) async {
        _log('getMediaItem($mediaId)');
        final result = await super.getMediaItem(mediaId);
        _log('getMediaItem -> $result');
        return result;
      }

      @override
      Future<List<MediaItem>> search(String query,
          [Map<String, dynamic>? extras]) async {
        _log('search($query, $extras)');
        final result = await super.search(query, extras);
        _log('search -> $result');
        return result;
      }

      @override
      Future<void> androidSetRemoteVolume(int volumeIndex) {
        _log('androidSetRemoteVolume($volumeIndex)');
        return super.androidSetRemoteVolume(volumeIndex);
      }

      @override
      Future<void> androidAdjustRemoteVolume(AndroidVolumeDirection direction) {
        _log('androidAdjustRemoteVolume($direction)');
        return super.androidAdjustRemoteVolume(direction);
      }
    }

    void showSliderDialog({
      required BuildContext context,
      required String title,
      required int divisions,
      required double min,
      required double max,
      String valueSuffix = '',
      // TODO: Replace these two by ValueStream.
      required double value,
      required Stream<double> stream,
      required ValueChanged<double> onChanged,
    }) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title, textAlign: TextAlign.center),
          content: StreamBuilder<double>(
            stream: stream,
            builder: (context, snapshot) => Container(
              height: 100.0,
              child: Column(
                children: [
                  Text('${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                      style: const TextStyle(
                          fontFamily: 'Fixed',
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0)),
                  Slider(
                    divisions: divisions,
                    min: min,
                    max: max,
                    value: snapshot.data ?? value,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }*/











/*
from chat GPT
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Media',
      home: DeviceMediaScreen(),
    );
  }
}

class DeviceMediaScreen extends StatefulWidget {
  @override
  _DeviceMediaScreenState createState() => _DeviceMediaScreenState();
}

class _DeviceMediaScreenState extends State<DeviceMediaScreen> {
  List<AssetEntity> _photos = [];
  List<AssetEntity> _videos = [];
  List<AssetEntity> _audios = [];

  @override
  void initState() {
    super.initState();
    _getMedia();
  }

  Future<void> _getMedia() async {
    // Request permission to access device media
    // final permissionStatus = await PhotoManager.requestPermission();
    // if (permissionStatus != PermissionStatus.authorized) {
    //   return;
    // }

    // Load all the photos, videos, and audios on the device
    final List<AssetPathEntity> albums =
        await PhotoManager.getAssetPathList(type: RequestType.all);
    for (final album in albums) {
      if (album.isAll) {
        final photos = await album.getAssetListPaged(page:0, size:album.assetCount);
        _photos.addAll(photos.where((e) => e.type == AssetType.image));
        _videos.addAll(photos.where((e) => e.type == AssetType.video));
        _audios.addAll(photos.where((e) => e.type == AssetType.audio));
        break;
      }
    }

    // Refresh the UI to show the loaded media
    setState(() {});
    print(_photos.length);
    print(_videos.length);
    print(_audios.length);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Device Media'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Photos'),
              Tab(text: 'Videos'),
              Tab(text: 'Audios'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _photos.isEmpty
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) =>
                        _buildAssetThumbnail(_photos[index]),
                  ),
            _videos.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: FutureBuilder<Uint8List?>(
                        future: _videos[index].thumbnailDataWithSize(ThumbnailSize(120, 120)),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.data != null) {
                            return Image.memory(snapshot.data!);
                          }
                          return SizedBox.shrink();
                        },
                      ),
                      title: Text(_videos[index].title ?? ''),
                      onTap: () {
                        // Handle video selection
                        // ...
                      },
                    ),
                  ),
            _audios.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _audios.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: Icon(Icons.audiotrack),
                      title: Text(_audios[index].title ?? ''),
                      onTap: () {
// Handle audio selection
// ...
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetThumbnail(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(ThumbnailSize(120, 120)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return GestureDetector(
            onTap: () {
// Handle photo selection
// ...
            },
            child: Image.memory(snapshot.data!),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

*
* */
