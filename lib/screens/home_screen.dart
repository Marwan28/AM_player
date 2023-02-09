import 'dart:io';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Directory dir = Directory('/storage/emulated/0/dcim');
  late List<FileSystemEntity> files;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    files = dir.listSync(recursive: true);
    for (var file in files) {
      FileStat f1 = file.statSync();
      print(file.path);
      print(f1.type);
    }
    print(files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: <Widget>[
            if(files!=null)
              Expanded(
                child: ListView.builder(
                itemBuilder: (context, index) =>
                    Text(files[index].toString() ?? ''),
                itemCount: files.length ?? 0,
            ),
              ),
          ],
        ),
      ),
    );
  }
}
