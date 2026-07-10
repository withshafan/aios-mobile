import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, desktop }

DeviceType getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return DeviceType.phone;
  if (width < 900) return DeviceType.tablet;
  return DeviceType.desktop;
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType) builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, getDeviceType(context));
  }
}
