import 'package:flutter/material.dart';

AppBar getHomeAppBar() {
  return AppBar(
    title: const Text("Minhas Academias"),
    centerTitle: true,
    backgroundColor: const Color(0xff0A6D92), //0xff => #
    actions: [
      IconButton(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
        ),
        onPressed: () {},
      ),
    ],
  );
}
