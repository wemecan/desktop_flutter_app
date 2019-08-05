// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:desktop_flutter_app/ui/imageSlecect/supplemental/cut_corners_border.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'backdrop.dart';
import 'category_menu_page.dart';
import 'colors.dart';
import 'expanding_bottom_sheet.dart';
import 'home.dart';
import 'model/app_state_model.dart';

class ShrineApp extends StatefulWidget {
  @override
  _ShrineAppState createState() => _ShrineAppState();
}

class _ShrineAppState extends State<ShrineApp>
    with SingleTickerProviderStateMixin {
  // Controller to coordinate both the opening/closing of backdrop and sliding
  // of expanding bottom sheet
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppStateModel>(
        builder: (BuildContext context, Widget child, AppStateModel model) {
          final category = model.getCurrentCategory();
          return MaterialApp(
            title: 'Shrine',
            themeMode: ThemeMode.system,
            home: HomePage(
              backdrop: Backdrop(
                frontLayer: const ProductPage(),
                backLayer:
                CategoryMenuPage(onCategoryTap: () => _controller.forward()),
                frontTitle:  Center(
                  child: Text(category),
                ),
                backTitle: Center(
                  child: Text('目录'),
                ),
                controller: _controller,
              ),
              expandingBottomSheet: ExpandingBottomSheet(hideController: _controller),
            ),

            // Copy the platform from the main theme in order to support platform
            // toggling from the Gallery options menu.
            theme: _kShrineTheme.copyWith(platform: Theme.of(context).platform),
          );        });

  }
}

Route<dynamic> _getRoute(RouteSettings settings) {
  if (settings.name != '/login') {
    return null;
  }

  return MaterialPageRoute<void>(
    settings: settings,
    builder: (BuildContext context) => ProductPage(),
    fullscreenDialog: true,
  );
}

final ThemeData _kShrineTheme = _buildShrineTheme();

IconThemeData _customIconTheme(IconThemeData original) {
  return original.copyWith(color: kShrineBrown900);
}

ThemeData _buildShrineTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    colorScheme: kShrineColorScheme,
    accentColor: kShrineBrown900,
    primaryColor: kShrinePink100,
    buttonColor: kShrinePink100,
    scaffoldBackgroundColor: kShrineBackgroundWhite,
    cardColor: kShrineBackgroundWhite,
    textSelectionColor: kShrinePink100,
    errorColor: kShrineErrorRed,
    buttonTheme: const ButtonThemeData(
      colorScheme: kShrineColorScheme,
      textTheme: ButtonTextTheme.normal,
    ),
    primaryIconTheme: _customIconTheme(base.iconTheme),
    inputDecorationTheme:
        const InputDecorationTheme(border: CutCornersBorder()),
    textTheme: _buildShrineTextTheme(base.textTheme),
    primaryTextTheme: _buildShrineTextTheme(base.primaryTextTheme),
    accentTextTheme: _buildShrineTextTheme(base.accentTextTheme),
    iconTheme: _customIconTheme(base.iconTheme),
  );
}

TextTheme _buildShrineTextTheme(TextTheme base) {
  return base
      .copyWith(
        headline: base.headline.copyWith(fontWeight: FontWeight.w500),
        title: base.title.copyWith(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
        caption:
            base.caption.copyWith(fontWeight: FontWeight.w400, fontSize: 14.0),
        body2: base.body2.copyWith(fontWeight: FontWeight.w500, fontSize: 16.0),
        button:
            base.button.copyWith(fontWeight: FontWeight.w500, fontSize: 14.0),
      )
      .apply(
//    fontFamily: 'Raleway',
        displayColor: kShrineBrown900,
        bodyColor: kShrineBrown900,
      );
}

const ColorScheme kShrineColorScheme = ColorScheme(
  primary: kShrinePink100,
  primaryVariant: kShrineBrown900,
  secondary: kShrinePink50,
  secondaryVariant: kShrineBrown900,
  surface: kShrineSurfaceWhite,
  background: kShrineBackgroundWhite,
  error: kShrineErrorRed,
  onPrimary: kShrineBrown900,
  onSecondary: kShrineBrown900,
  onSurface: kShrineBrown900,
  onBackground: kShrineBrown900,
  onError: kShrineSurfaceWhite,
  brightness: Brightness.light,
);
