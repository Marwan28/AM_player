import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class Video {
  String title;
  String path;
  int duration;
  Uint8List image;

  Video(
      {required this.title,
      required this.path,
      required this.duration,required this.image}) {
  }

}
