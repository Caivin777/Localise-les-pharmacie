import 'package:flutter/material.dart';
import 'package:koko/pages/login_page.dart';
import 'package:koko/widgets/onboarding.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}
class _OnboardingPageState extends State<OnboardingPage> {

  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView(
            onPageChanged: (index){
              setState(() {
                currentIndex = index;
              });
            },

            children: [
            Onboarding(
                title: "Nearby Pharmacies ",
                subTitle: "Find pharmacies and medical stores in your area with ease, wherever you need them.",
                image: "assets/images/copie.png"
            ),
            Onboarding(
                title: "Real-Time Updates",
                subTitle: "Access live information on pharmacy availability opening hours,and emergency services.",
                image: "assets/images/copie1.png"
            ),
              Onboarding(
                  title: "Navigate Easily",
                  subTitle: "Get step-by-step walking or driving directions to neart pharmacy quickly.",
                  image: "assets/images/copie2.png"
              )
            ],
          ),
          Padding(
              padding: EdgeInsets.all(20),
            child: Column(   
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                     GestureDetector(
                  onTap: (){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(),
                    )
                    );
                  },
                    child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.teal[300],
                ),
                  child: Center(
                    child: Text(
                        "GET STARTED",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                    ),
                  ),
                )
                ),
                SizedBox(height: 20,),
            Padding(
                padding: EdgeInsets.only(bottom: 20),
            child: Row(
                  mainAxisAlignment:MainAxisAlignment.center,
                  children:List.generate(
                      3,
                      (index) => AnimatedContainer(duration: const Duration(milliseconds: 300),
                        height: 10,
                        
                        width: currentIndex == index? 20 : 10,
                        margin: EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: currentIndex == index? Colors.teal[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                  ),
                ),
            ),
              ],
            ),
          )
        ],
      ),
    );
    }
}
