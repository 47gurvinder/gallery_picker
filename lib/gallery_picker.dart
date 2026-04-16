import 'dart:async';

import 'package:bottom_sheet_scaffold/bottom_sheet_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:gallery_picker/models/gallery_media.dart';
import 'package:gallery_picker/models/media_type.dart';
import 'package:get/get.dart';
import 'package:page_transition/page_transition.dart';

import '../../controller/gallery_controller.dart';
import 'controller/picker_listener.dart';
import 'models/config.dart';
import 'models/media_file.dart';
import 'views/gallery_picker_view/gallery_picker_view.dart';

export 'package:bottom_sheet_scaffold/models/sheet_status.dart';
export 'package:bottom_sheet_scaffold/views/bottom_sheet_builder.dart';
export 'package:page_transition/src/enum.dart';

export 'models/config.dart';
export 'models/gallery_album.dart';
export 'models/gallery_media.dart';
export 'models/media_file.dart';
export 'models/medium.dart';
export 'models/mode.dart';
export 'user_widgets/album_categories_view.dart';
export 'user_widgets/album_media_view.dart';
export 'user_widgets/date_category_view.dart';
export 'user_widgets/gallery_picker_builder.dart';
export 'user_widgets/media_provider.dart';
export 'user_widgets/photo_provider.dart';
export 'user_widgets/thumbnail_album.dart';
export 'user_widgets/thumbnail_media.dart';
export 'user_widgets/video_provider.dart';
export 'views/gallery_picker_view/gallery_picker_view.dart';
export 'views/picker_scaffold.dart';

class GalleryPicker {
  static PhoneGalleryController _getOrCreateController() {
    if (GetInstance().isRegistered<PhoneGalleryController>()) {
      return Get.find<PhoneGalleryController>();
    }
    return Get.put(PhoneGalleryController());
  }

  static Route<dynamic> _buildPickerRoute({
    required Widget child,
    required PageTransitionType pageTransitionType,
  }) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoPageRoute(builder: (_) => child);
    }
    return PageTransition(type: pageTransitionType, child: child);
  }

  static Stream<List<MediaFile>> get listenSelectedFiles {
    var controller = Get.put(PickerListener());
    return controller.stream;
  }

  static void disposeSelectedFilesListener() {
    if (GetInstance().isRegistered<PickerListener>()) {
      Get.find<PickerListener>().dispose();
    }
  }

  static void dispose() {
    if (GetInstance().isRegistered<PhoneGalleryController>()) {
      Get.find<PhoneGalleryController>().disposeController();
    }
  }

  static Future<List<MediaFile>?> pickMedia({Config? config,
    bool startWithRecent = false,
    bool singleMedia = false,
    Locale? locale,
    PageTransitionType pageTransitionType = PageTransitionType.rightToLeft,
    List<MediaFile>? initSelectedMedia,
    List<MediaFile>? extraRecentMedia,
    required BuildContext context,
    GalleryMediaType? mediaType}) async {
    final resolvedMediaType = mediaType ?? GalleryMediaType.all;
    final controller = _getOrCreateController();
    List<MediaFile>? media;
    controller.configuration(config,
        onSelect: (selectedMedias) {
          media = selectedMedias;
        },
        startWithRecent: startWithRecent,
        heroBuilder: null,
        multipleMediasBuilder: null,
        initSelectedMedias: initSelectedMedia,
        extraRecentMedia: extraRecentMedia,
        isRecent: startWithRecent,
        mediaType: resolvedMediaType);
    if (!controller.isInitialized) {
      unawaited(controller.initializeAlbums(locale: locale));
    }

    await Navigator.push(
        context,
        _buildPickerRoute(
            pageTransitionType: pageTransitionType,
            child: GalleryPickerView(
              onSelect: (mediaTmp) {
                media = mediaTmp;
              },
              config: config,
              locale: locale,
              singleMedia: singleMedia,
              initSelectedMedia: initSelectedMedia,
              extraRecentMedia: extraRecentMedia,
              startWithRecent: startWithRecent,
              mediaType: resolvedMediaType,
            )));
    return media;
  }

  static Future<void> pickMediaWithBuilder({Config? config,
    required Widget Function(List<MediaFile> media, BuildContext context)?
    multipleMediaBuilder,
    Widget Function(String tag, MediaFile media, BuildContext context)?
    heroBuilder,
    Locale? locale,
    bool singleMedia = false,
    PageTransitionType pageTransitionType = PageTransitionType.rightToLeft,
    List<MediaFile>? initSelectedMedia,
    List<MediaFile>? extraRecentMedia,
    bool startWithRecent = false,
    required BuildContext context}) async {
    final controller = _getOrCreateController();
    controller.configuration(config,
        onSelect: (media) {},
        startWithRecent: startWithRecent,
        heroBuilder: heroBuilder,
        multipleMediasBuilder: multipleMediaBuilder,
        initSelectedMedias: initSelectedMedia,
        extraRecentMedia: extraRecentMedia,
        isRecent: startWithRecent,
        mediaType: GalleryMediaType.all);
    if (!controller.isInitialized) {
      unawaited(controller.initializeAlbums(locale: locale));
    }

    await Navigator.push(
        context,
        _buildPickerRoute(
            pageTransitionType: pageTransitionType,
            child: GalleryPickerView(
              onSelect: (media) {},
              locale: locale,
              multipleMediaBuilder: multipleMediaBuilder,
              heroBuilder: heroBuilder,
              singleMedia: singleMedia,
              config: config,
              initSelectedMedia: initSelectedMedia,
              extraRecentMedia: extraRecentMedia,
              startWithRecent: startWithRecent,
            )));
  }

  static Future<void> openSheet() async {
    BottomSheetPanel.open();
  }

  static Future<void> closeSheet() async {
    BottomSheetPanel.close();
  }

  static bool get isSheetOpened {
    return BottomSheetPanel.isOpen;
  }

  static bool get isSheetExpanded {
    return BottomSheetPanel.isExpanded;
  }

  static bool get isSheetCollapsed {
    return BottomSheetPanel.isCollapsed;
  }

  static Future<GalleryMedia?> collectGallery(
      {Locale? locale, GalleryMediaType mediaType = GalleryMediaType
          .all}) async {
    return await PhoneGalleryController.collectGallery(
      locale: locale, mediaType: mediaType, eagerLoad: true);
  }

  static Future<GalleryMedia?> initializeGallery({Locale? locale}) async {
    final controller = Get.put(PhoneGalleryController());
    await controller.initializeAlbums(locale: locale);
    return controller.media;
  }
}
