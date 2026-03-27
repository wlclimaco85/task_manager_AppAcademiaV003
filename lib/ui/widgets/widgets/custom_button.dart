import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPresse;
  final String labels;

  const CustomButton({
    super.key,
    required this.onPresse,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    /* return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPresse,
        child: const Icon(Icons.arrow_circle_right_outlined),
      ),
    );*/
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFA903A),
        minimumSize: const Size.fromHeight(50), // NEW
      ),
      onPressed: () {
        onPresse();
      },
      child: const Text(
        'Label',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );

    /*return Container(
      IconButton(
        icon: Icon(Icons.volume_up),
        iconSize: 50,
        color: Colors.brown,
        tooltip: 'Increase volume by 5',
        onPressed: () {  };
        },
        
      ),
      Text('Speaker Volume: $_speakervolume')
    )*/
  }
}
