import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GradientContainer(),
      )
    ),
  );
}

class GradientContainer extends StatelessWidget{
const GradientContainer({super.key});

  @override
  Widget build(context) {
    return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
            colors: [
            Colors.black,
            Colors.black12, 
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            )
          ),
          child: Center(
            child: 
            Text('Hello world!', 
            style: 
            TextStyle(
              color: Colors.amber, 
              fontSize: 28
              ),
            )
          ),
        );
  }
}
