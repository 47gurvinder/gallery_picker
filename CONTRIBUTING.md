# Contributing to gallery_picker_gdx_plus

Thank you for helping maintain `gallery_picker_gdx_plus`. Feature requests and Pull Requests are always welcome.

## Before you start

- Search the [existing issues](https://github.com/47gurvinder/gallery_picker/issues) and [Pull Requests](https://github.com/47gurvinder/gallery_picker/pulls).
- Use the [feature request form](https://github.com/47gurvinder/gallery_picker/issues/new?template=feature_request.yml) for proposed behavior.
- Open a regular [issue](https://github.com/47gurvinder/gallery_picker/issues) for reproducible bugs.
- Do not report security vulnerabilities publicly; follow [SECURITY.md](SECURITY.md).
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Development setup

1. Fork and clone the [maintained repository](https://github.com/47gurvinder/gallery_picker).
2. Install the Flutter version required by `pubspec.yaml` or newer within its supported SDK range.
3. Run `flutter pub get` in the repository root and in `example/`.
4. Make a focused change with tests or an example update where appropriate.
5. Run the validation commands before opening a Pull Request.

```sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
cd example && flutter analyze && flutter test
```

Platform behavior should also be tested manually on a supported Android or iOS device when the change affects permissions, gallery access, thumbnails, or video playback.

## Pull Requests

Keep Pull Requests focused and explain the user-visible behavior, validation performed, and any platform-specific considerations. Link the relevant issue when one exists. Do not include generated build output or unrelated dependency lockfile changes.

By contributing, you agree that your contribution is licensed under the repository's [MIT License](LICENSE). Existing upstream copyright, license, attribution, and history must remain intact.
