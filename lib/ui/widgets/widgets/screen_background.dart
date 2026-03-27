// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/utils/assets_utils.dart';

class ScreenBackground extends StatelessWidget {
  final Widget child;
  const ScreenBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Image.asset(
            AssetsUtils.backgroundSVG,
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
