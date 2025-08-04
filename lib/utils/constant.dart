import 'package:flutter/material.dart';

const background_theme = Color.fromARGB(255, 142, 5, 166);
// ignore: constant_identifier_names
const color_white = Colors.white;
// ignore: constant_identifier_names
const color_error = Colors.red;
const color_success = Color.fromARGB(255, 11, 118, 15);
const theme_light = Color.fromARGB(255, 244, 234, 255);
const color_warning = Colors.orange;
const devise = 'Ar';
const logo_path = 'assets/images/logoStock.png';

const LinearGradient headerGradient = LinearGradient(
  colors: <Color>[
    background_theme,
    background_theme,
    Color.fromARGB(255, 202, 58, 227)
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter
  );

  // ignore: constant_identifier_names
  const LinearGradient btn_gradient = LinearGradient(
  colors: <Color>[
    background_theme,
    background_theme,
    Colors.purpleAccent
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight
  );