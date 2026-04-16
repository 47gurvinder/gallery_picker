import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery_picker/models/media_type.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';

import '../models/config.dart';
import '../models/gallery_media.dart';
import '../models/media_file.dart';
import '/models/gallery_album.dart';
import '/models/medium.dart';
import 'picker_listener.dart';

class PhoneGalleryController extends GetxController {
  late Config config;
  late GalleryMediaType mediaType;

  void configuration(Config? config,
      {required dynamic Function(List<MediaFile>) onSelect,
        required Widget Function(String, MediaFile, BuildContext)? heroBuilder,
        required bool isRecent,
        required bool startWithRecent,
        required List<MediaFile>? initSelectedMedias,
        required List<MediaFile>? extraRecentMedia,
        required Widget Function(List<MediaFile>, BuildContext)?
        multipleMediasBuilder,
        required GalleryMediaType mediaType}) {
    this.onSelect = onSelect;
    this.heroBuilder = heroBuilder;
    this.isRecent = isRecent;
    this.startWithRecent = startWithRecent;
    this.multipleMediasBuilder = multipleMediasBuilder;
    this.mediaType = mediaType;
    pageController = PageController();
    pickerPageController = PageController(initialPage: startWithRecent ? 0 : 1);
    this.config = config ?? Config();
    if (initSelectedMedias != null) {
      _selectedFiles = initSelectedMedias.map((e) => e).toList();
    }
    if (extraRecentMedia != null) {
      _extraRecentMedia = extraRecentMedia.map((e) => e).toList();
    }
    if (selectedFiles.isNotEmpty) {
      _pickerMode = true;
    }
    configurationCompleted = true;
  }

  late bool startWithRecent;
  late bool isRecent;
  bool? permissionGranted;
  bool configurationCompleted = false;
  late Function(List<MediaFile> selectedMedias) onSelect;
  Widget Function(String tag, MediaFile media, BuildContext context)?
  heroBuilder;
  Widget Function(List<MediaFile> medias, BuildContext context)?
  multipleMediasBuilder;
  GalleryMedia? _media;

  GalleryMedia? get media => _media;

  List<GalleryAlbum> get galleryAlbums => _media == null ? [] : _media!.albums;
  List<MediaFile> _selectedFiles = [];
  List<MediaFile>? _extraRecentMedia;

  List<MediaFile> get selectedFiles => _selectedFiles;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  List<MediaFile>? get extraRecentMedia => _extraRecentMedia;
  bool _pickerMode = false;

  bool get pickerMode => _pickerMode;
  late PageController pageController;
  late PageController pickerPageController;
  GalleryAlbum? selectedAlbum;
  bool _isHydratingAlbums = false;
  Locale? _activeLocale;
  Timer? _permissionPollingTimer;
  Future<void>? _initializationTask;
  int _permissionPollingAttempts = 0;
  static const int _maxPermissionPollingAttempts = 180;

  static bool _isPermissionAuthorized(PermissionStatus status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  void resetBottomSheetView() {
    if (permissionGranted == true) {
      isRecent = true;
      if (selectedAlbum == null) {
        pickerPageController.jumpToPage(0);
      } else {
        pageController.jumpToPage(0);
        pickerPageController = PageController();
      }
      selectedAlbum = null;
      update();
    }
  }

  void updateConfig(Config? config) {
    this.config = config ?? Config();
  }

  void updateSelectedFiles(List<MediaFile> media) {
    _selectedFiles = media.map((e) => e).toList();
    if (selectedFiles.isEmpty) {
      _pickerMode = false;
    } else {
      _pickerMode = true;
    }
    update();
  }

  void updateExtraRecentMedia(List<MediaFile> media) {
    _extraRecentMedia = media.map((e) => e).toList();
    GalleryAlbum? recentTmp = recent;
    if (recentTmp != null) {
      _extraRecentMedia!.removeWhere(
              (element) =>
              recentTmp.files.any((file) => element.id == file.id));
    }
    update();
  }

  Future<void> changeAlbum({required GalleryAlbum album,
    required BuildContext context,
    required PhoneGalleryController controller,
    required bool singleMedia,
    required bool isBottomSheet}) async {
    _selectedFiles.clear();
    if (!album.isInitialized) {
      unawaited(album.initialize(
          locale: _activeLocale, onChanged: update, lightWeight: true));
    }
    selectedAlbum = album;
    update();
    updatePickerListener();
    await pageController.animateToPage(1,
        duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  Future<void> backToPicker() async {
    _selectedFiles.clear();
    _pickerMode = false;
    pickerPageController = PageController(initialPage: 1);
    update();
    await pageController.animateToPage(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
    selectedAlbum = null;
    update();
  }

  void unselectMedia(MediaFile file) {
    _selectedFiles.removeWhere((element) => element.id == file.id);
    if (_selectedFiles.isEmpty) {
      _pickerMode = false;
    }
    update();
    updatePickerListener();
  }

  void selectMedia(MediaFile file) {
    if (!_selectedFiles.any((element) => element.id == file.id)) {
      _selectedFiles.add(file);
    }
    if (!_pickerMode) {
      _pickerMode = true;
    }
    update();
    updatePickerListener();
  }

  void switchPickerMode(bool value) {
    if (!value) {
      _selectedFiles.clear();
      updatePickerListener();
    }
    _pickerMode = value;
    update();
  }

  void updatePickerListener() {
    if (GetInstance().isRegistered<PickerListener>()) {
      Get.find<PickerListener>().updateController(_selectedFiles);
    }
  }

  static Future<bool> promptPermissionSetting(
      {required GalleryMediaType mediaType}) async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final AndroidDeviceInfo info = await deviceInfoPlugin.androidInfo;
      if (info.version.sdkInt >= 33) {
        if (mediaType == GalleryMediaType.image) {
          return await PhoneGalleryController.requestPermission(Permission.photos);
        }
        if (mediaType == GalleryMediaType.video) {
          return await PhoneGalleryController.requestPermission(Permission.videos);
        }

        final photosGranted =
            await PhoneGalleryController.requestPermission(Permission.photos);
        if (!photosGranted) {
          return false;
        }
        return await PhoneGalleryController.requestPermission(Permission.videos);
      } else {
        return await PhoneGalleryController.requestPermission(
            Permission.storage);
      }
    }

    if (Platform.isIOS) {
      return await PhoneGalleryController.requestPermission(Permission.photos);
    }

    return await PhoneGalleryController.requestPermission(Permission.storage);
  }

  static Future<bool> requestPermission(Permission permission) async {
    final current = await permission.status;
    if (_isPermissionAuthorized(current)) {
      return true;
    }

    final requested = await permission.request();
    return _isPermissionAuthorized(requested);
  }

  Future<void> initializeAlbums({Locale? locale}) async {
    if (_isInitialized) {
      return;
    }
    if (_initializationTask != null) {
      return _initializationTask!;
    }

    _initializationTask = _initializeAlbumsInternal(locale: locale);
    try {
      await _initializationTask!;
    } finally {
      _initializationTask = null;
    }
  }

  Future<void> _initializeAlbumsInternal({Locale? locale}) async {
    _activeLocale = locale;
    _media = await PhoneGalleryController.collectGallery(
        locale: locale, mediaType: mediaType, eagerLoad: false);
    if (_media != null) {
      _permissionPollingTimer?.cancel();
      _permissionPollingTimer = null;
      _permissionPollingAttempts = 0;
      if (_extraRecentMedia != null) {
        GalleryAlbum? recentTmp = recent;
        if (recentTmp != null) {
          _extraRecentMedia!.removeWhere((element) =>
              recentTmp.files.any((file) => element.id == file.id));
        }
      }
      permissionGranted = true;
      _isInitialized = true;
      unawaited(_hydrateAlbums(locale: locale));
    } else {
      permissionGranted = false;
      permissionListener(locale: locale);
    }
    update();
  }

  Future<void> _hydrateAlbums({Locale? locale}) async {
    if (_isHydratingAlbums || _media == null) {
      return;
    }
    _isHydratingAlbums = true;
    try {
      final albums = _media!.albums.map((e) => e).toList();
      GalleryAlbum? recentAlbum;
      try {
        recentAlbum = albums.firstWhere((album) => album.name == "All");
      } catch (_) {
        recentAlbum = null;
      }

      if (recentAlbum != null) {
        unawaited(recentAlbum.initialize(
            locale: locale, onChanged: update, lightWeight: true));
      }

      for (final album in albums) {
        if (identical(album, recentAlbum) || album.hasPreview) {
          continue;
        }
        await album.loadPreview(onChanged: update);
      }
    } finally {
      _isHydratingAlbums = false;
    }
  }

  void permissionListener({Locale? locale}) {
    _permissionPollingTimer?.cancel();
    _permissionPollingAttempts = 0;
    _permissionPollingTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      _permissionPollingAttempts++;
      if (_permissionPollingAttempts >= _maxPermissionPollingAttempts) {
        timer.cancel();
        _permissionPollingTimer = null;
        return;
      }
      if (await isGranted()) {
        initializeAlbums(locale: locale);
        timer.cancel();
        _permissionPollingTimer = null;
        _permissionPollingAttempts = 0;
      }
    });
  }

  Future<bool> isGranted() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final AndroidDeviceInfo info = await deviceInfoPlugin.androidInfo;
      if (info.version.sdkInt >= 33) {
        if (mediaType == GalleryMediaType.image) {
          return await Permission.photos.isGranted;
        }
        if (mediaType == GalleryMediaType.video) {
          return await Permission.videos.isGranted;
        }
        if (await Permission.photos.isGranted) {
          return await Permission.videos.isGranted;
        }
        return false;
      } else {
        return await Permission.storage.isGranted;
      }
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return _isPermissionAuthorized(status);
    }

    return await Permission.storage.isGranted;
  }

  static Future<GalleryMedia?> collectGallery(
      {Locale? locale,
      required GalleryMediaType mediaType,
      bool eagerLoad = true}) async {
    if (await promptPermissionSetting(mediaType: mediaType)) {
      List<GalleryAlbum> tempGalleryAlbums = [];
      List<Album> photoAlbums = [];
      List<Album> videoAlbums = [];

      if (!eagerLoad) {
        if (mediaType == GalleryMediaType.image) {
          photoAlbums =
                await PhotoGallery.listAlbums(mediumType: MediumType.image, approximateCount: true);
        }

        if (mediaType == GalleryMediaType.video) {
          videoAlbums =
                await PhotoGallery.listAlbums(mediumType: MediumType.video, approximateCount: true);
        }

        if (mediaType == GalleryMediaType.all) {
            final mixedAlbums = await PhotoGallery.listAlbums(approximateCount: true);
          for (final mixedAlbum in mixedAlbums) {
            final entry = GalleryAlbum.album(mixedAlbum);
            entry.setType = AlbumType.mixed;
            tempGalleryAlbums.add(entry);
          }
        } else if (mediaType == GalleryMediaType.image) {
          for (var photoAlbum in photoAlbums) {
            GalleryAlbum entry = GalleryAlbum.album(photoAlbum);
            entry.setType = AlbumType.image;
            tempGalleryAlbums.add(entry);
          }
        } else {
          for (var videoAlbum in videoAlbums) {
            GalleryAlbum entry = GalleryAlbum.album(videoAlbum);
            entry.setType = AlbumType.video;
            tempGalleryAlbums.add(entry);
          }
        }

        return GalleryMedia(tempGalleryAlbums);
      }

      if (mediaType == GalleryMediaType.image ||
          mediaType == GalleryMediaType.all) {
        photoAlbums =
        await PhotoGallery.listAlbums(mediumType: MediumType.image);
        if (mediaType == GalleryMediaType.all) {
          videoAlbums =
              await PhotoGallery.listAlbums(mediumType: MediumType.video);
        }
        for (var photoAlbum in photoAlbums) {
          GalleryAlbum entireGalleryAlbum = GalleryAlbum.album(photoAlbum);
          await entireGalleryAlbum.initialize(
              locale: locale, onChanged: null, lightWeight: false);
          entireGalleryAlbum.setType = AlbumType.image;
          if (videoAlbums.any((element) => element.id == photoAlbum.id)) {
            Album videoAlbum = videoAlbums
                .singleWhere((element) => element.id == photoAlbum.id);
            GalleryAlbum videoGalleryAlbum = GalleryAlbum.album(videoAlbum);
            await videoGalleryAlbum.initialize(
                locale: locale, onChanged: null, lightWeight: false);
            DateTime? lastPhotoDate = entireGalleryAlbum.lastDate;
            DateTime? lastVideoDate = videoGalleryAlbum.lastDate;

            if (lastPhotoDate == null) {
              try {
                entireGalleryAlbum.thumbnail =
                await videoAlbum.getThumbnail(highQuality: true);
              } catch (e) {
                if (kDebugMode) {
                  print(e);
                }
              }
            } else if (lastVideoDate == null) {} else {
              if (lastVideoDate.isAfter(lastPhotoDate)) {
                try {
                  entireGalleryAlbum.thumbnail =
                  await videoAlbum.getThumbnail(highQuality: true);
                } catch (e) {
                  entireGalleryAlbum.thumbnail = null;
                  if (kDebugMode) {
                    print(e);
                  }
                }
              }
            }
            for (var file in videoGalleryAlbum.files) {
              entireGalleryAlbum.addFile(file, locale: locale);
            }
            entireGalleryAlbum.sort();
            entireGalleryAlbum.setType = AlbumType.mixed;
            videoAlbums.remove(videoAlbum);
          }
          tempGalleryAlbums.add(entireGalleryAlbum);
        }
      }

      if (mediaType == GalleryMediaType.video) {
        videoAlbums =
        await PhotoGallery.listAlbums(mediumType: MediumType.video);
      }

      if (mediaType == GalleryMediaType.video ||
          mediaType == GalleryMediaType.all) {
        for (var videoAlbum in videoAlbums) {
          GalleryAlbum galleryVideoAlbum = GalleryAlbum.album(videoAlbum);
          await galleryVideoAlbum.initialize(
              locale: locale, onChanged: null, lightWeight: false);
          galleryVideoAlbum.setType = AlbumType.video;
          tempGalleryAlbums.add(galleryVideoAlbum);
        }
      }

      return GalleryMedia(tempGalleryAlbums);
    } else {
      return null;
    }
  }

  GalleryAlbum? get recent {
    try {
      return galleryAlbums.firstWhere((element) => element.album.name == "All");
    } catch (_) {
      return null;
    }
  }

  //GalleryAlbum? get recent {
  //  if (_isInitialized) {
  //    GalleryAlbum? recent;
  //    for (var album in _galleryAlbums) {
  //      if (recent == null || (album.count > recent.count)) {
  //        recent = album;
  //      }
  //    }
  //    if (recent != null) {
  //      return GalleryAlbum(
  //          album: recent.album,
  //          type: recent.type,
  //          thumbnail: recent.thumbnail,
  //          dateCategories: recent.dateCategories);
  //    } else {
  //      return null;
  //    }
  //  } else {
  //    return null;
  //  }
  //}

  List<Medium> sortAlbumMediaDates(List<Medium> mediumList) {
    mediumList.sort((a, b) {
      if (a.lastDate == null) {
        return 1;
      } else if (b.lastDate == null) {
        return -1;
      } else {
        return a.lastDate!.compareTo(b.lastDate!);
      }
    });
    return mediumList;
  }

  bool isSelectedMedia(MediaFile file) {
    return _selectedFiles.any((element) => element.id == file.id);
  }

  void disposeController() {
    _permissionPollingTimer?.cancel();
    _permissionPollingTimer = null;
    _permissionPollingAttempts = 0;
    _media = null;
    _selectedFiles = [];
    _isInitialized = false;
    _isHydratingAlbums = false;
    _initializationTask = null;
    if (GetInstance().isRegistered<PhoneGalleryController>()) {
      Get.delete<PhoneGalleryController>();
    }
  }
}
