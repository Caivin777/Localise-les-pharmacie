import 'package:flutter/material.dart';

class Onboarding extends StatelessWidget{
  final String title;
  final String subTitle;
  final String image;

  const Onboarding({
    Key? key,
    required this.title,
    required this.subTitle,
    required this.image
});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      children: [
       Positioned.fill(
         bottom: 200,
          child: Image.asset(
              image,
              fit: BoxFit.contain,
            ),
        ),
         Positioned.fill(
          top: 256,
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    textAlign: TextAlign.center,
                    title,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   Padding(
                       padding: EdgeInsets.all(20),
                   child: Text(
                     textAlign: TextAlign.center,
                    subTitle,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
         )
                ],
              ),
            )
        )
      ],
    );
  }
}