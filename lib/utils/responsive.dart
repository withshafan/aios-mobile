import 'package:flutter/material.dart';
import '../theme/tokens.dart';

DeviceType getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < breakpointPhone) return DeviceType.phone;
  if (width < breakpointTablet) return DeviceType.tablet;
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
