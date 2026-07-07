package com.example.am_player

import android.content.res.Configuration
import cl.puntito.simple_pip_mode.PipCallbackHelper
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: AudioServiceActivity() {
    private val pipCallbackHelper = PipCallbackHelper()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pipCallbackHelper.configureFlutterEngine(flutterEngine)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration?
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipCallbackHelper.onPictureInPictureModeChanged(isInPictureInPictureMode)
    }
}
