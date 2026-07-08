import 'package:am_player/widget.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongWidget extends StatelessWidget {
  const SongWidget({super.key, required this.songList});

  final List<SongModel> songList;

  static String parseToMinSec(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: songList.length,
      itemBuilder: (context, index) {
        final song = songList[index];
        if (!song.displayName.toLowerCase().contains('.mp3')) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 2,
                        children: [
                          _MetaText('Year: ${song.dateAdded}'),
                          _MetaText('Artist: ${song.artist ?? 'Unknown'}'),
                          _MetaText(
                            'Duration: ${parseToMinSec(song.duration ?? 0)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const IconText(
                  iconData: Icons.volume_up,
                  string: 'play',
                  iconColor: Colors.blue,
                  textColor: Colors.blue,
                  iconSize: 25,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetaText extends StatelessWidget {
  final String text;

  const _MetaText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.grey,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
