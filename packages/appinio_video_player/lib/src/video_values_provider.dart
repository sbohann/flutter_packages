import 'dart:async';
import 'package:appinio_video_player/src/custom_video_player_controller.dart';
import 'package:appinio_video_player/src/custom_video_player_service.dart';
import 'package:appinio_video_player/src/models/custom_video_player_settings.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class VideoValuesProvider extends ChangeNotifier {
  bool controlBarVisible;
  VideoPlayerController videoPlayerController;
  CustomVideoPlayerController customVideoPlayerController;
  BuildContext context;
  bool privateIsFullscreen = false;
  Duration videoProgress = Duration.zero;
  Timer? _timer;
  bool mounted = true;

  CustomVideoPlayerSettings customVideoPlayerSettings;

  VideoValuesProvider({
    this.controlBarVisible = true,
    required this.videoPlayerController,
    required this.customVideoPlayerController,
    required this.context,
    required this.customVideoPlayerSettings,
  }) {
    videoPlayerController.addListener(listener);
    customVideoPlayerController.addListener(fullscreenListener);
  }

  void fullscreenListener() {
    if (customVideoPlayerController.isFullscreen && !privateIsFullscreen) {
      CustomVideoPlayerService.enterFullscreen(
          context, videoPlayerController, this);
      privateIsFullscreen = true;
    } else if (!customVideoPlayerController.isFullscreen &&
        privateIsFullscreen) {
      CustomVideoPlayerService.exitFullscreen(context, this);
      privateIsFullscreen = false;
    }
    notifyListeners();
  }

  /// used to make progress more fluid
  listenVideoProgress() async {
    if (videoPlayerController.value.isPlaying) {
      _timer ??= Timer.periodic(const Duration(milliseconds: 100),
          (Timer timer) async {
        if (videoPlayerController.value.isInitialized) {
          if (mounted) {
            videoProgress =
                await videoPlayerController.position ?? videoProgress;
            notifyListeners();
          }
        }
      });
    } else {
      if (_timer != null) {
        _timer?.cancel();
        _timer = null;
        if (videoPlayerController.value.isInitialized) {
          videoProgress = (await videoPlayerController.position)!;
        }
      }
    }
  }

  void listener() {
    listenVideoProgress();

    if (videoPlayerController.value.isPlaying &&
        customVideoPlayerSettings.enableWakeLockWhenPlaying) {
      Wakelock.enable();
    } else {
      Wakelock.disable();
    }

    if (videoPlayerController.value.duration ==
            videoPlayerController.value.position &&
        !videoPlayerController.value.isPlaying &&
        customVideoPlayerSettings.exitFullscreenOnEnd) {
      customVideoPlayerController.setFullscreen(false);
    }

    if (videoPlayerController.value.position == Duration.zero &&
        videoPlayerController.value.isPlaying &&
        customVideoPlayerSettings.enterFullscreenOnStart) {
      customVideoPlayerController.setFullscreen(true);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    mounted = false;
    _timer?.cancel();
    videoPlayerController.removeListener(listener);
    customVideoPlayerController.removeListener(fullscreenListener);
    super.dispose();
  }
}
