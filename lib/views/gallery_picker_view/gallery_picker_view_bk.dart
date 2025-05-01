/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/gallery_controller.dart';
import '../../models/config.dart';
import '../../models/gallery_album.dart';
import '../../models/media_file.dart';
import '../album_categories_view/album_categories_view.dart';
import '../album_view/album_medias_view.dart';
import '../album_view/album_page.dart';
import 'permission_denied_view.dart';
import 'picker_appbar.dart';

class GalleryPickerView extends StatefulWidget {
  final Config? config;
  final Function(List<MediaFile> selectedMedia) onSelect;
  final Widget Function(String tag, MediaFile media, BuildContext context)?
      heroBuilder;
  final Widget Function(List<MediaFile> media, BuildContext context)?
      multipleMediaBuilder;
  final bool startWithRecent;
  final bool isBottomSheet;
  final Locale? locale;
  final List<MediaFile>? initSelectedMedia;
  final List<MediaFile>? extraRecentMedia;
  final bool singleMedia;

  const GalleryPickerView(
      {super.key,
      this.config,
      required this.onSelect,
      this.initSelectedMedia,
      this.extraRecentMedia,
      this.singleMedia = false,
      this.isBottomSheet = false,
      this.heroBuilder,
      this.locale,
      this.multipleMediaBuilder,
      this.startWithRecent = false});

  @override
  State<GalleryPickerView> createState() => _GalleryPickerState();
}

class _GalleryPickerState extends State<GalleryPickerView> {
  PhoneGalleryController galleryController = Get.put(PhoneGalleryController());

  bool noPhotoSeleceted = true;
  late Config config;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration()).then(
      (value) {
        _initializeGallery();
      },
    );
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _initializeGallery();
    // });
  }

  Future<void> _initializeGallery() async {
    if (galleryController.configurationCompleted) {
      galleryController.updateConfig(widget.config);
    } else {
      galleryController.configuration(
        widget.config,
        onSelect: widget.onSelect,
        startWithRecent: widget.startWithRecent,
        heroBuilder: widget.heroBuilder,
        multipleMediasBuilder: widget.multipleMediaBuilder,
        initSelectedMedias: widget.initSelectedMedia,
        extraRecentMedia: widget.extraRecentMedia,
        isRecent: widget.startWithRecent,
      );
    }

    config = galleryController.config;

    if (!galleryController.isInitialized) {
      await galleryController.initializeAlbums(locale: widget.locale);
    }
    setState(() {}); // Refresh page after async init
  }

  @override
  void dispose() async {
    // galleryController.dispose();
    // await Get.delete<PhoneGalleryController>();
    super.dispose();
  }

  GalleryAlbum? selectedAlbum;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (!galleryController.isInitialized) {
      // While the gallery is still initializing, show a lightweight loader
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.grey,
          ),
        ),
      );
    }

    return GetBuilder<PhoneGalleryController>(builder: (controller) {
      return galleryController.permissionGranted != false
          ? PageView(
              controller: galleryController.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PopScope(
                  canPop: true,
                  onPopInvoked: (value) {
                    print("selectMedia pop 1 ");
                    if (!widget.isBottomSheet) {
                      galleryController.disposeController();
                    }
                  },
                  child: Scaffold(
                    backgroundColor: config.backgroundColor,
                    appBar: PickerAppBar(
                      controller: galleryController,
                      isBottomSheet: widget.isBottomSheet,
                      singleMedia: widget.singleMedia,
                    ),
                    body: Column(
                      children: [
                        Container(
                          width: width,
                          height: 48,
                          color: config.appbarColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMenuButton(
                                title: config.recents,
                                isSelected: galleryController.isRecent,
                                onPressed: () {
                                  galleryController.pickerPageController
                                      .animateToPage(
                                    0,
                                    duration: const Duration(milliseconds: 50),
                                    curve: Curves.easeIn,
                                  );
                                  galleryController.isRecent = true;
                                  galleryController.switchPickerMode(false);
                                },
                              ),
                              _buildMenuButton(
                                title: config.gallery,
                                isSelected: !galleryController.isRecent,
                                onPressed: () {
                                  galleryController.pickerPageController
                                      .animateToPage(
                                    1,
                                    duration: const Duration(milliseconds: 50),
                                    curve: Curves.easeIn,
                                  );
                                  galleryController.isRecent = false;
                                  galleryController.switchPickerMode(false);
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PageView(
                            controller: galleryController.pickerPageController,
                            onPageChanged: (value) {
                              print("seledAlbum 2: ${value}");

                              galleryController.isRecent = (value == 0);
                              galleryController.switchPickerMode(false);
                            },
                            scrollDirection: Axis.horizontal,
                            children: [
                              if (galleryController.recent != null)
                                AlbumMediasView(
                                  galleryAlbum: galleryController.recent!,
                                  controller: galleryController,
                                  isBottomSheet: widget.isBottomSheet,
                                  singleMedia: widget.singleMedia,
                                ),
                              AlbumCategoriesView(
                                controller: galleryController,
                                isBottomSheet: widget.isBottomSheet,
                                singleMedia: widget.singleMedia,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AlbumPage(
                  album: galleryController.selectedAlbum,
                  controller: galleryController,
                  singleMedia: widget.singleMedia,
                  isBottomSheet: widget.isBottomSheet,
                ),
              ],
            )
          : Material(
              child: galleryController.config.permissionDeniedPage ??
                  PermissionDeniedView(
                    config: galleryController.config,
                  ),
            );
    });
  }

  Widget _buildMenuButton({
    required String title,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: isSelected
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: config.underlineColor,
                    width: 3.0,
                  ),
                ),
              )
            : null,
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            title,
            style: isSelected
                ? config.selectedMenuStyle
                : config.unselectedMenuStyle,
          ),
        ),
      ),
    );
  }
}
*/
