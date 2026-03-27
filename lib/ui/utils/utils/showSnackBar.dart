import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

void showSnackBar(
    {required String message,
    required bool isError,
    required BuildContext context}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isError
          ? CustomColors().getShowSnackBarError()
          : CustomColors().getShowSnackBarSuccess(),
      duration: const Duration(seconds: 3),
    ),
  );
}
