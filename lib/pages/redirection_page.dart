import 'package:flutter/material.dart';
import 'package:koko/pages/Onboarding_page.dart';
import 'package:koko/pages/login_page.dart';

import '../widgets/firebase_auth/auth.dart';

class RedirectionPage extends StatefulWidget {
  const RedirectionPage({super.key});

  @override
  State<RedirectionPage> createState() => _RedirectionPageState();
}

class _RedirectionPageState extends State<RedirectionPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Auth().autStateChanges,
        builder: (context , snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const CircularProgressIndicator();
          }else if(snapshot.hasData){
            return const OnboardingPage();
          }else{
            return const LoginPage();
          }
        }
    );
  }
}
