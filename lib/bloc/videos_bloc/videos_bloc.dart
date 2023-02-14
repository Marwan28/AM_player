import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'videos_event.dart';
part 'videos_state.dart';

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  VideosBloc() : super(VideosInitial()) {
    on<VideosEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
