# gallery_picker_gdx_plus

[![pub package](https://img.shields.io/pub/v/gallery_picker_gdx_plus.svg)](https://pub.dev/packages/gallery_picker_gdx_plus)
[![pub points](https://img.shields.io/pub/points/gallery_picker_gdx_plus)](https://pub.dev/packages/gallery_picker_gdx_plus/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A community-maintained Flutter package for browsing a device gallery, selecting one or more images or videos, and presenting media with customizable, ready-to-use widgets.

<img src="https://raw.githubusercontent.com/FlutterWay/files/main/gallery_picker_views/gallery_picker_poster.png" alt="Gallery Picker overview" width="1200"/>

## Features

- Modern light and dark gallery interfaces
- Single- and multiple-media selection
- Image, video, or mixed-media filtering
- Recent-media and album views
- Full-page and bottom-sheet layouts
- Locale-aware recent date groups
- Initial selections and additional recent media
- Selection listeners and reactive builders
- Custom destination pages and Hero transitions
- Thumbnail, image, video, and media-provider widgets
- Permission requests and a customizable permission-denied page
- Sound null safety

The example implementations are available in [`example/lib/examples`](example/lib/examples).

<div align="center">
  <table>
    <tr>
      <td><img src="https://raw.githubusercontent.com/FlutterWay/files/main/gallery_picker_views/gallery_picker_light.gif" alt="Light gallery picker" width="200"/></td>
      <td><img src="https://raw.githubusercontent.com/FlutterWay/files/main/gallery_picker_views/gallery_picker_dark.gif" alt="Dark gallery picker" width="200"/></td>
      <td><img src="https://raw.githubusercontent.com/FlutterWay/files/main/gallery_picker_views/gallery_picker_destination.gif" alt="Custom destination" width="200"/></td>
      <td><img src="https://raw.githubusercontent.com/FlutterWay/files/main/gallery_picker_views/camera_page.gif" alt="Camera page integration" width="200"/></td>
    </tr>
  </table>
</div>

## Compatibility

| Platform | Minimum supported version |
| --- | --- |
| Android | API 24 |
| iOS | 13.0 |
| Dart | 3.11.0 |
| Flutter | 3.41.1 |

The package supports Android and iOS. It does not currently provide web, macOS, Windows, or Linux implementations.

## Installation

Add the package from pub.dev:

```sh
flutter pub add gallery_picker_gdx_plus
```

Or add it directly to `pubspec.yaml`:

```yaml
dependencies:
  gallery_picker_gdx_plus: ^0.6.0
```

Import the public library:

```dart
import 'package:gallery_picker_gdx_plus/gallery_picker.dart';
```

## Platform setup

### Android

Set your application's minimum SDK to API 24 or newer. In a current Flutter project using Kotlin DSL:

```kotlin
android {
    defaultConfig {
        minSdk = 24
    }
}
```

Declare the media permissions required by your application in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Android 12L (API 32) and earlier -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />

<!-- Android 13 (API 33) and newer -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

Only declare the image or video permission if your application restricts the picker to that media type.

### iOS

Set the deployment target to iOS 13.0 or newer and add a photo-library usage description to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access so you can select media.</string>
```

If the host application also saves media to the library, provide `NSPhotoLibraryAddUsageDescription` with an explanation appropriate to the app. The picker itself reads the library.

## Usage

### Pick one media file

`pickMedia` returns a list. When `singleMedia` is enabled, the list contains at most one item.

```dart
final List<MediaFile>? result = await GalleryPicker.pickMedia(
  context: context,
  singleMedia: true,
);

final MediaFile? selected =
    result == null || result.isEmpty ? null : result.first;
```

### Pick multiple media files

```dart
final List<MediaFile>? selected = await GalleryPicker.pickMedia(
  context: context,
);
```

Restrict the picker to images or videos with `GalleryMediaType`:

```dart
final List<MediaFile>? images = await GalleryPicker.pickMedia(
  context: context,
  mediaType: GalleryMediaType.image,
);
```

### Collect gallery media

```dart
final GalleryMedia? gallery = await GalleryPicker.collectGallery(
  mediaType: GalleryMediaType.all,
);
```

### Listen for selection changes

```dart
final Stream<List<MediaFile>> selections =
    GalleryPicker.listenSelectedFiles;
```

Dispose of the listener when it is no longer needed:

```dart
GalleryPicker.disposeSelectedFilesListener();
```

### Use the bottom-sheet layout

Use `PickerScaffold` in place of a standard `Scaffold`. A complete example is in [`bottom_sheet_example.dart`](example/lib/examples/bottom_sheet_example.dart).

```dart
@override
Widget build(BuildContext context) {
  return PickerScaffold(
    backgroundColor: Colors.transparent,
    onSelect: (media) {},
    initSelectedMedia: initialMedia,
    config: Config(mode: Mode.dark),
    body: const SizedBox.expand(),
  );
}
```

Open and close the sheet programmatically:

```dart
await GalleryPicker.openSheet();
await GalleryPicker.closeSheet();
```

### Build a custom destination page

`pickMediaWithBuilder` can navigate to custom content after selection. `heroBuilder` is used for a single selection; `multipleMediaBuilder` handles multiple selections and acts as the fallback when no Hero builder is supplied.

See [`pick_medias_with_builder.dart`](example/lib/examples/pick_medias_with_builder.dart) for a complete implementation.

```dart
await GalleryPicker.pickMediaWithBuilder(
  context: context,
  multipleMediaBuilder: (media, context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selected media')),
      body: GridView.count(
        crossAxisCount: 3,
        children: [
          for (final item in media) ThumbnailMedia(media: item),
        ],
      ),
    );
  },
  heroBuilder: (tag, media, context) {
    return Scaffold(
      body: Center(
        child: Hero(
          tag: tag,
          child: MediaProvider(media: media),
        ),
      ),
    );
  },
);
```

Release the picker controller after a custom flow is complete:

```dart
GalleryPicker.dispose();
```

## Configuration

Pass `Config` to `pickMedia`, `pickMediaWithBuilder`, or `PickerScaffold` to customize appearance and labels.

```dart
final List<MediaFile>? media = await GalleryPicker.pickMedia(
  context: context,
  pageTransitionType: PageTransitionType.rightToLeft,
  config: Config(
    mode: Mode.light,
    backgroundColor: Colors.white,
    appbarColor: Colors.white,
    bottomSheetColor: const Color(0xFFF7F8FA),
    appbarIconColor: const Color(0xFF828D94),
    underlineColor: const Color(0xFF14A183),
    selectedMenuStyle: const TextStyle(color: Colors.black),
    unselectedMenuStyle: const TextStyle(color: Color(0xFF667075)),
    textStyle: const TextStyle(
      color: Color(0xFF6C7379),
      fontWeight: FontWeight.bold,
    ),
    appbarTextStyle: const TextStyle(color: Colors.black),
    recents: 'RECENTS',
    gallery: 'GALLERY',
    lastMonth: 'Last Month',
    lastWeek: 'Last Week',
    tapPhotoSelect: 'Tap photo to select',
    selected: 'Selected',
    selectIcon: const Icon(Icons.check),
  ),
);
```

### Initial selections

```dart
final List<MediaFile>? media = await GalleryPicker.pickMedia(
  context: context,
  initSelectedMedia: initialMedia,
);
```

### Additional recent media

Create local entries with `MediaFile.file` and pass them through `extraRecentMedia`:

```dart
final MediaFile localFile = MediaFile.file(
  id: 'local-id',
  file: File('/path/to/image.jpg'),
  type: MediaType.image,
);

final List<MediaFile>? media = await GalleryPicker.pickMedia(
  context: context,
  extraRecentMedia: [localFile],
);
```

### Initial page

The picker contains Recent and Gallery pages. Select the initial page with `startWithRecent`:

```dart
final List<MediaFile>? media = await GalleryPicker.pickMedia(
  context: context,
  startWithRecent: true,
);
```

### Permission-denied page

```dart
Config(
  permissionDeniedPage: const MyPermissionDeniedPage(),
)
```

<img src="https://raw.githubusercontent.com/FlutterWay/files/main/gallery_picker_views/permission_denied.gif" alt="Permission denied interface" width="200"/>

## MediaFile

Picker results are represented by `MediaFile`. Each object exposes its ID, media type, underlying medium, thumbnail and file state, selection state, and asynchronous helpers including `getThumbnail`, `getFile`, and `getData`.

## Ready-to-use widgets

The package exports reusable building blocks for custom gallery experiences:

| Widget | Purpose |
| --- | --- |
| `ThumbnailMedia` | Render a media thumbnail |
| `ThumbnailAlbum` | Render an album thumbnail |
| `PhotoProvider` | Display an image media file |
| `VideoProvider` | Display a video media file |
| `MediaProvider` | Display either supported media type |
| `GalleryPickerBuilder` | Rebuild from selection changes |
| `BottomSheetBuilder` | Rebuild from bottom-sheet state |
| `AlbumMediaView` | Display media in one album |
| `AlbumCategoriesView` | Display available albums |

Example:

```dart
GalleryPickerBuilder(
  builder: (selectedFiles, context) {
    return Text('${selectedFiles.length} selected');
  },
)
```

## Examples

- [Standard gallery picker](example/lib/examples/gallery_picker_example.dart)
- [Custom destination page](example/lib/examples/pick_medias_with_builder.dart)
- [Bottom-sheet picker](example/lib/examples/bottom_sheet_example.dart)
- [Multiple-media view](example/lib/examples/multiple_medias.dart)
- [WhatsApp-style photo page](example/lib/examples/whatsapp_pick_photo.dart)

Run the example application:

```sh
cd example
flutter run
```

## Maintained Package

`gallery_picker_gdx_plus` is a community-maintained continuation of the original [`gallery_picker`](https://pub.dev/packages/gallery_picker) project by [Furkan Irmak / FlutterWay](https://github.com/FlutterWay/gallery_picker). This repository continues maintenance because the upstream package is inactive. Original copyright, license, authorship, contribution history, and project credits remain intact.

The current fork is maintained independently and is not presented as an official release from the original author.

## Acknowledgements

Thank you to Furkan Irmak, FlutterWay, and all [upstream contributors](https://github.com/FlutterWay/gallery_picker/graphs/contributors) for creating and improving the original project. Thanks also to the [fork contributors](https://github.com/47gurvinder/gallery_picker/graphs/contributors) and to the packages on which this library builds, including:

- [`photo_gallery_gdx_plus`](https://pub.dev/packages/photo_gallery_gdx_plus)
- [`video_thumbnail_gdx_plus`](https://pub.dev/packages/video_thumbnail_gdx_plus)
- [`permission_handler`](https://pub.dev/packages/permission_handler)
- [`bottom_sheet_scaffold`](https://pub.dev/packages/bottom_sheet_scaffold)
- [`transparent_image`](https://pub.dev/packages/transparent_image)
- [`video_player`](https://pub.dev/packages/video_player)
- [`get`](https://pub.dev/packages/get)
- [`intl`](https://pub.dev/packages/intl)

## Feature Requests

Feature requests and Pull Requests are always welcome.

- [Request a feature](https://github.com/47gurvinder/gallery_picker/issues/new?template=feature_request.yml)
- [Report a bug or browse issues](https://github.com/47gurvinder/gallery_picker/issues)
- [Open or review a Pull Request](https://github.com/47gurvinder/gallery_picker/pulls)

Please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## Need Help?

For consulting, package integration, plugin maintenance, or Flutter application development, visit [gurwinderdevx.com](https://gurwinderdevx.com) or use one of the maintainer profiles below.

## Maintainer

Maintained by **Gurwinder Singh**.

- [Website](https://gurwinderdevx.com)
- [GitHub](https://github.com/47gurvinder)
- [LinkedIn](https://www.linkedin.com/in/47gurvinder)
- [Upwork](https://www.upwork.com/freelancers/~01281f2b994bae6a1e)

## License

This project is distributed under the [MIT License](LICENSE). The original 2022 copyright notice for Furkan Irmak is preserved in the license file.
