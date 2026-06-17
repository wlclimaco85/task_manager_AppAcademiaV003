import 'package:flutter/material.dart';

class InputBuscarField extends StatelessWidget {
  const InputBuscarField(
      {super.key,
      required this.hint,
      required this.obscure,
      required this.icon,
      required this.onPresseds});

  final String hint;
  final bool obscure;
  final IconData icon;
  final void Function()? onPresseds;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
          color: Color(0xFFFA903A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(6.0),
            topRight: Radius.circular(6.0),
            bottomLeft: Radius.circular(6.0),
            bottomRight: Radius.circular(6.0),
          )),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                obscureText: obscure,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Image.asset('assets/images/Buscar.ico'),
                    onPressed: null,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 13.0,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    /*Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 50.0,
      color: const Color(0xffFA903A),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Padding(
            padding: const EdgeInsets.all(0.0),
            child: Icon(
              Icons.search,
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: TextFormField(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(10.0),
                hintText: 'Search artist, genre, playlist',
                hintStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 11.0,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
    ); */
  }
}
