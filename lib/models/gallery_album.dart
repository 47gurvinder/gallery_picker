import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:photo_gallery/photo_gallery.dart';

import '../controller/gallery_controller.dart';
import '/models/media_file.dart';
import '/models/medium.dart';
import 'config.dart';

class GalleryAlbum {
  late Album album;
  Album? secondaryAlbum;
  List<int>? thumbnail;
  List<DateCategory> dateCategories = [];
  late AlbumType type;
  int _estimatedCount = 0;
  bool _initialized = false;
  bool _isLoadingMore = false;
  bool _hasLoadedAllMedia = false;
  Future<void>? _initializationTask;
  Future<void>? _paginationTask;
  Future<void>? _previewTask;

  bool get isInitialized => _initialized;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasLoadedAllMedia => _hasLoadedAllMedia;
  bool get hasPreview => thumbnail != null;
  int get count =>
      _initialized
          ? dateCategories.expand((element) => element.files).toList().length
          : _estimatedCount;
  String? get name => album.name;

  GalleryAlbum.album(this.album) {
    _estimatedCount = album.count;
  }

  GalleryAlbum(
      {required this.album,
      required this.type,
      this.thumbnail,
      this.dateCategories = const []});

  List<MediaFile> get medias {
    return dateCategories
        .expand<MediaFile>((element) => element.files)
        .toList();
  }

  set setType(AlbumType type) {
    this.type = type;
  }

  void addEstimatedCount(int count) {
    _estimatedCount += count;
  }

  void setSecondaryAlbum(Album album) {
    secondaryAlbum = album;
  }

  IconData get icon {
    switch (type) {
      case AlbumType.image:
        return Icons.image;
      case AlbumType.video:
        return Icons.videocam;
      case AlbumType.mixed:
        return Icons.perm_media_outlined;
    }
  }

  Future<void> initialize(
      {Locale? locale,
      VoidCallback? onChanged,
      bool lightWeight = false}) async {
    if (_initialized) {
      return _paginationTask ?? Future.value();
    }

    if (_initializationTask != null) {
      return _initializationTask!;
    }

    _initializationTask =
        _initializeInPages(locale: locale, onChanged: onChanged, lightWeight: lightWeight);
    await _initializationTask!;
    _initializationTask = null;
  }

  Future<void> loadPreview({VoidCallback? onChanged}) async {
    if (thumbnail != null) {
      return;
    }
    if (_previewTask != null) {
      return _previewTask!;
    }

    _previewTask = _loadThumbnail().whenComplete(() {
      onChanged?.call();
      _previewTask = null;
    });

    return _previewTask!;
  }

  Future<void> _initializeInPages(
      {Locale? locale,
      VoidCallback? onChanged,
      required bool lightWeight}) async {
    _isLoadingMore = true;

    MediaPage primaryPage = await album.listMedia(
      take: PhotoGallery.defaultPageSize,
      lightWeight: lightWeight,
    );
    _appendMediaItems(primaryPage.items, locale: locale);

    MediaPage? secondaryPage;
    if (type == AlbumType.mixed && secondaryAlbum != null) {
      secondaryPage = await secondaryAlbum!.listMedia(
        take: PhotoGallery.defaultPageSize,
        lightWeight: lightWeight,
      );
      _appendMediaItems(secondaryPage.items, locale: locale);
    }

    sort();
    await _loadThumbnail();
    _initialized = true;
    onChanged?.call();

    List<Future<void>> remainingPageTasks = [];
    if (!primaryPage.isLast) {
      remainingPageTasks.add(_loadRemainingPages(
        sourceAlbum: album,
        startAt: primaryPage.end,
        locale: locale,
        onChanged: onChanged,
        lightWeight: lightWeight,
      ));
    }
    if (secondaryPage != null && !secondaryPage.isLast) {
      remainingPageTasks.add(_loadRemainingPages(
        sourceAlbum: secondaryAlbum!,
        startAt: secondaryPage.end,
        locale: locale,
        onChanged: onChanged,
        lightWeight: lightWeight,
      ));
    }

    if (remainingPageTasks.isEmpty) {
      _hasLoadedAllMedia = true;
      _isLoadingMore = false;
      onChanged?.call();
      return;
    }

    _paginationTask = Future.wait(remainingPageTasks).then((_) {
      _hasLoadedAllMedia = true;
      _isLoadingMore = false;
      onChanged?.call();
    });
    unawaited(_paginationTask);
  }

  Future<void> _loadRemainingPages(
      {required Album sourceAlbum,
      required int startAt,
      required Locale? locale,
      VoidCallback? onChanged,
      required bool lightWeight}) async {
    int currentOffset = startAt;

    while (currentOffset < sourceAlbum.count) {
      final page = await sourceAlbum.listMedia(
        skip: currentOffset,
        take: PhotoGallery.defaultPageSize,
        lightWeight: lightWeight,
      );
      if (page.items.isEmpty) {
        break;
      }

      _appendMediaItems(page.items, locale: locale);
      sort();
      currentOffset = page.end;
      onChanged?.call();

      if (page.isLast) {
        break;
      }
    }
  }

  Future<void> _loadThumbnail() async {
    if (thumbnail != null) {
      return;
    }

    try {
      thumbnail = await album.getThumbnail(highQuality: false);
      if (thumbnail == null && secondaryAlbum != null) {
        thumbnail = await secondaryAlbum!.getThumbnail(highQuality: false);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _appendMediaItems(List<Medium> items, {required Locale? locale}) {
    for (var medium in sortAlbumMediaDates(items)) {
      MediaFile mediaFile = MediaFile.medium(medium);
      String name = getDateCategory(mediaFile, locale: locale);
      if (dateCategories.any((element) => element.name == name)) {
        dateCategories
            .singleWhere((element) => element.name == name)
            .files
            .add(mediaFile);
      } else {
        DateTime? lastDate = mediaFile.lastModified;
        lastDate = lastDate ?? DateTime.now();
        dateCategories.add(
            DateCategory(files: [mediaFile], name: name, dateTime: lastDate));
      }
    }
  }

  DateTime? get lastDate {
    if (dateCategories.isNotEmpty &&
        dateCategories.first.files.first.medium != null) {
      return dateCategories.first.files.first.medium!.lastDate;
    } else {
      return null;
    }
  }

  List<MediaFile> get files =>
      dateCategories.expand((element) => element.files).toList();

  String getDateCategory(MediaFile media, {Locale? locale}) {
    Config config = GetInstance().isRegistered<PhoneGalleryController>()
        ? Get.find<PhoneGalleryController>().config
        : Config();
    DateTime? lastDate = media.lastModified;
    lastDate = lastDate ?? DateTime.now();
    initializeDateFormatting();
    String languageCode = locale != null
        ? (locale).languageCode
        : Platform.localeName.split('_')[0];
    if (daysBetween(lastDate) <= 3) {
      return config.recent;
    } else if (daysBetween(lastDate) > 3 && daysBetween(lastDate) <= 7) {
      return config.lastWeek;
    } else if (DateTime.now().month == lastDate.month) {
      return config.lastMonth;
    } else if (DateTime.now().year == lastDate.year) {
      String month = DateFormat.MMMM(languageCode).format(lastDate).toString();
      return "$month ${lastDate.day}";
    } else {
      String month = DateFormat.MMMM(languageCode).format(lastDate).toString();
      return "$month ${lastDate.day}, ${lastDate.year}";
    }
  }

  int daysBetween(DateTime from) {
    from = DateTime(from.year, from.month, from.day);
    return (DateTime.now().difference(from).inHours / 24).round();
  }

  static List<Medium> sortAlbumMediaDates(List<Medium> mediumList) {
    mediumList.sort((a, b) {
      if (a.lastDate == null) {
        return 1;
      } else if (b.lastDate == null) {
        return -1;
      } else {
        return b.lastDate!.compareTo(a.lastDate!);
      }
    });
    return mediumList;
  }

  sort() {
    dateCategories.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    for (var category in dateCategories) {
      category.files.sort((a, b) {
        if (a.medium == null) {
          return 1;
        } else if (b.medium == null) {
          return -1;
        } else {
          return b.medium!.lastDate!.compareTo(a.medium!.lastDate!);
        }
      });
    }
  }

  void addFile(MediaFile file, {Locale? locale}) {
    String name = getDateCategory(file, locale: locale);
    if (dateCategories.any((element) => element.name == name)) {
      dateCategories
          .singleWhere((element) => element.name == name)
          .files
          .add(file);
    } else {
      DateTime? lastDate = file.lastModified;
      lastDate = lastDate ?? DateTime.now();
      dateCategories
          .add(DateCategory(files: [file], name: name, dateTime: lastDate));
    }
  }
}

class DateCategory {
  String name;
  List<MediaFile> files;
  DateTime dateTime;
  DateCategory(
      {required this.files, required this.name, required this.dateTime});
}

enum AlbumType { video, image, mixed }
