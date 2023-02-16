import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class Video {
  String title;
  String path;
  int duration;
  Uint8List image;
  Uri uri;
  File file;

  Video(
      {required this.title,
      required this.path,
      required this.duration,required this.image,required this.uri,required this.file}) {
  }

}
