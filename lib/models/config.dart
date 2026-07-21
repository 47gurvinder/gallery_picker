import 'package:flutter/material.dart';

import 'mode.dart';

class Config {
  late Widget selectIcon;
  Widget? permissionDeniedPage;
  late Color backgroundColor,
      appbarColor,
      appbarIconColor,
      underlineColor,
      bottomSheetColor;
  late TextStyle textStyle,
      appbarTextStyle,
      selectedMenuStyle,
      unselectedMenuStyle;
  String recents,
      recent,
      gallery,
      lastMonth,
      lastWeek,
      tapPhotoSelect,
      selected;
  int iOSOpeningGateMilliseconds;
  Mode mode;

  Config({
    Color? backgroundColor,
    Color? appbarColor,
    Color? bottomSheetColor,
    Color? appbarIconColor,
    Color? underlineColor,
    TextStyle? selectedMenuStyle,
    TextStyle? unselectedMenuStyle,
    TextStyle? textStyle,
    TextStyle? appbarTextStyle,
    this.permissionDeniedPage,
    this.recents = "RECENTS",
    this.recent = "Recent",
    this.gallery = "GALLERY",
    this.lastMonth = "Last Month",
    this.lastWeek = "Last Week",
    this.tapPhotoSelect = "Tap photo to select",
    this.selected = "Selected",
    this.iOSOpeningGateMilliseconds = 420,
    this.mode = Mode.light,
    Widget? selectIcon,
  }) {
    this.backgroundColor =
        backgroundColor ??
        (mode == Mode.dark
            ? const Color.fromARGB(255, 18, 27, 34)
            : Colors.white);
    this.appbarColor =
        appbarColor ??
        (mode == Mode.dark
            ? const Color.fromARGB(255, 31, 44, 52)
            : Colors.white);
    this.bottomSheetColor =
        bottomSheetColor ??
        (mode == Mode.dark
            ? const Color.fromARGB(255, 31, 44, 52)
            : const Color.fromARGB(255, 247, 248, 250));
    this.appbarIconColor =
        appbarIconColor ??
        (mode == Mode.dark
            ? Colors.white
            : const Color.fromARGB(255, 130, 141, 148));
    this.underlineColor =
        underlineColor ??
        (mode == Mode.dark
            ? const Color.fromARGB(255, 6, 164, 130)
            : const Color.fromARGB(255, 20, 161, 131));
    this.selectedMenuStyle =
        selectedMenuStyle ??
        TextStyle(color: mode == Mode.dark ? Colors.white : Colors.black);
    this.unselectedMenuStyle =
        unselectedMenuStyle ??
        TextStyle(
          color: mode == Mode.dark
              ? Colors.grey
              : const Color.fromARGB(255, 102, 112, 117),
        );
    this.textStyle =
        textStyle ??
        TextStyle(
          color: mode == Mode.dark
              ? Colors.grey[300]!
              : const Color.fromARGB(255, 108, 115, 121),
          fontWeight: FontWeight.bold,
        );
    this.appbarTextStyle =
        appbarTextStyle ??
        TextStyle(color: mode == Mode.dark ? Colors.white : Colors.black);
    this.selectIcon =
        selectIcon ??
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromARGB(255, 0, 168, 132),
          ),
          child: const Icon(Icons.check, color: Colors.white),
        );
  }
}
