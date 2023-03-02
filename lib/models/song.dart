import 'package:on_audio_query/on_audio_query.dart';

class Song {
  final String? filePath;
  final String? title;
  final Uri? uri;
  final String? id;
  // final String? author;
  // final SongModel? rawModel;

  Song({
    required this.filePath,
    required this.title,
    required this.uri,
    required this.id,
    // required this.author,
    // required this.rawModel,
  });
}
