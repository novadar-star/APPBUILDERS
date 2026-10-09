import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:snapfood/app/app_shell.dart';

void main() => runApp(
      kDebugMode
          ? DevicePreview(
              enabled: true,
              builder: (context) => const AppShell(),
            )
          : const AppShell(),
    );
