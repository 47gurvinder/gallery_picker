import 'package:bottom_sheet_scaffold/bottom_sheet_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../controller/gallery_controller.dart';
import '../../../models/media_file.dart';
import '../thumbnail_media_file.dart';

class MediaView extends StatelessWidget {
  final MediaFile file;
  final PhoneGalleryController controller;
  final bool singleMedia;
  final bool isBottomSheet;
  const MediaView(this.file,
      {super.key,
      required this.controller,
      required this.singleMedia,
      required this.isBottomSheet});
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ThumbnailMediaFile(
            onLongPress: () async {
              if (singleMedia) {
                controller.selectedFiles.add(file);
                if (controller.heroBuilder != null) {
                  await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (BuildContext context) {
                    return controller.heroBuilder!(file.id, file, context);
                  }));
                  controller.switchPickerMode(true);
                } else if (controller.multipleMediasBuilder != null) {
                  await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (BuildContext context) {
                    return controller.multipleMediasBuilder!([file], context);
                  }));
                  controller.switchPickerMode(true);
                } else {
                  controller.onSelect(controller.selectedFiles);
                  if (isBottomSheet) {
                    BottomSheetPanel.close();
                    controller.switchPickerMode(true);
                    controller.updatePickerListener();
                  } else {
                    Navigator.pop(context);
                    controller.updatePickerListener();
                    controller.disposeController();
                  }
                }
              } else {
                controller.selectMedia(file);
                print("selectMedia 1 $file");
              }
            },
            onTap: () async {
              if (controller.pickerMode) {
                if (controller.isSelectedMedia(file)) {
                  controller.unselectMedia(file);
                  print("selectMedia 2 $file");
                } else {
                  controller.selectMedia(file);
                  print("selectMedia 3 $file");
                }
              } else {
                print("selectMedia 4 $file");
                controller.selectedFiles.clear(); // Important: clear previous selection
                controller.selectedFiles.add(file);
                if (controller.heroBuilder != null) {
                  await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (BuildContext context) {
                    return controller.heroBuilder!(file.id, file, context);
                  }));
                  controller.switchPickerMode(true);
                  print("selectMedia 5 $file");
                } else if (controller.multipleMediasBuilder != null) {
                  await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (BuildContext context) {
                    return controller.multipleMediasBuilder!([file], context);
                  }));
                  controller.switchPickerMode(true);
                  print("selectMedia 6 $file");
                } else {

                  controller.onSelect(controller.selectedFiles);
                  if (isBottomSheet) {
                    print("selectMedia 7 $file");
                    BottomSheetPanel.close();
                    controller.switchPickerMode(true);
                    controller.updatePickerListener();
                  } else {
                    print("selectMedia 8 $file");
                    controller.updatePickerListener();
                    controller.disposeController();
                    Navigator.of(context, rootNavigator: true).pop(); // --> full pop
                  }
                }
              }
            },
            file: file,
            failIconColor: controller.config.appbarIconColor,
            controller: controller),
      ],
    );
  }
}
