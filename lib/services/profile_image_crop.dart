import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Full-screen profile photo crop UI shared by onboarding and profile screens.
class ProfileImageCrop {
  ProfileImageCrop._();

  static const Color _bg = Color(0xFF0A0A12);
  static const Color _toolbar = Color(0xFF14141F);
  static const Color _accent = Color(0xFF00B8D4);

  /// Opens the native crop & rotate UI (fullscreen on Android via [Ucrop.CropTheme]).
  static Future<CroppedFile?> crop(
    String sourcePath, {
    BuildContext? webContext,
  }) {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Photo',
          toolbarColor: _toolbar,
          toolbarWidgetColor: Colors.white,
          // Do not set statusBarColor — it forces the system bars to stay visible.
          statusBarLight: false,
          navBarLight: false,
          backgroundColor: _bg,
          activeControlsWidgetColor: _accent,
          dimmedLayerColor: const Color(0xE6000000),
          cropFrameColor: _accent,
          cropGridColor: Color(0x5900B8D4),
          cropFrameStrokeWidth: 2,
          cropGridStrokeWidth: 1,
          showCropGrid: true,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Adjust Photo',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          resetButtonHidden: true,
          aspectRatioPickerButtonHidden: true,
        ),
        if (webContext != null)
          WebUiSettings(
            context: webContext,
            presentStyle: WebPresentStyle.page,
          ),
      ],
    );
  }
}
