// Original scaffold preserved in git history — being broken up across T1–T10
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:snapfood/app/app_shell.dart';

void main() => runApp(
      DevicePreview(
        enabled: true, // set to false when done designing
        builder: (context) => const AppShell(),
      ),
    );
