import 'package:am_player/screens/home.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  load(ctx) async {
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      ctx,
      PageTransition(
        type: PageTransitionType.bottomToTop,
        alignment: Alignment.center,
        child: const Home(),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    load(context);
  }

  @override
  Widget build(BuildContext context) {
    return const SpinKitRing(
      color: Colors.red,
      size: 100,
    );
  }
}
