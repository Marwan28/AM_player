import 'package:flutter/material.dart';

class VideosHomeScreen extends StatelessWidget {
  const VideosHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('videos',style: TextStyle(fontSize: 25,color: Colors.blue,),),),
      ),
    );
  }
}
