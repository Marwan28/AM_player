import 'package:flutter/material.dart';

class SongsHomeScreen extends StatelessWidget {
  const SongsHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('songs',style: TextStyle(fontSize: 25,color: Colors.blue,),),),
      ),
    );
  }
}