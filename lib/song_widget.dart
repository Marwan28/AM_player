import 'package:am_player/main.dart';
import 'package:am_player/widget.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongWidget extends StatelessWidget {
  const SongWidget({Key? key, required this.songList}) : super(key: key);
  final List<SongModel> songList;

  static String parseToMinSec(int ms) {
    String data;
    Duration duration = Duration(milliseconds: ms);
    int min = duration.inMinutes;
    int sec = (duration.inSeconds) - (min * 60);
    data = min.toString() + '0';
    if (sec <= 9) data += '0';
    data += sec.toString();
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: songList.length,
      itemBuilder: (context, index) {
        SongModel song = songList[index];
        if (song.displayName.contains('.mp3')) {
          return Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: Text(
                                song.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              'Year: ${song.dateAdded}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Artist: ${song.artist}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Duration: ${parseToMinSec(song.duration!)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            audioManagerInstance
                                .start(
                                  'file:/${song.data}',
                                  song.title,
                                  desc: '',
                                  cover: '',
                                )
                                .then((value) => print(value));
                          },
                          child: const IconText(
                            iconData: Icons.volume_up,
                            string: 'play',
                            iconColor: Colors.blue,
                            textColor: Colors.blue,
                            iconSize: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox(height: 0,);
      },
    );
  }
}
