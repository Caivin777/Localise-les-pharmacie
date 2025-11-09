import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:koko/pages/home_page.dart';
import 'package:koko/widgets/firebase_auth/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController =TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child:  SafeArea(
        child: Center(
            child: Column(
        children: [
          SizedBox(height: 50,),
          //logo  
          Icon(Icons.medical_services,size:100,color: Colors.teal,),
          const SizedBox(height: 50,),
          //Welcome back , you've  been missed!
          Text(_isLogin? "PHARMACY" : "Join us!",
            style: TextStyle(fontSize: 45,
                color: Colors.teal[300]),
          ),
          const SizedBox(height: 20,),
          //username textfield
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
            child: TextFormField(
              controller: _emailController,
            decoration: InputDecoration(
              labelText: "Email",
              hintText: "Enter your Email",
             labelStyle: TextStyle(color: Colors.blue),
              fillColor: Colors.grey[300],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Enter your mail";
                }else if(!value.contains("@")){
                  return "Enter your address";
               }else if(!value.contains(".")){
                  return "Enter your Address";
                }else{
                  return null;
                }
              },
            )
          ),
           SizedBox(height: 10,),
          //password textfield
               Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
            child: TextFormField(
              controller: _passwordController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              labelText: "Password",
              hintText: "Enter your Password",
             labelStyle: TextStyle(color: Colors.blue),
              fillColor: Colors.grey[300],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                  onPressed: (){
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                  icon: Icon(_isObscure?  Icons.visibility_off:Icons.visibility,color: Colors.teal[300],),
              )
            ),
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Enter your Password";
              }else{
                  return null;
                }
              }
          ),
          ),
          const SizedBox(height: 10,),
         if(!_isLogin)  Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
            child: TextFormField(
              controller: _passwordConfirmController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              labelText: "Password",
              hintText: "Enter your Password",
             labelStyle: TextStyle(color: Colors.blue),
              fillColor: Colors.grey[300],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                  onPressed: (){
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                  icon: Icon(_isObscure?  Icons.visibility_off:Icons.visibility,color: Colors.teal[300],),
              )
            ),
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Enter your Password";
              }else if(value !=_passwordController.text){
                  return "Enter the correct password";
                }else{
                  return null;
                }
              },
          ),
          ),
          const SizedBox(height: 10,),
          //forgot password
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Forgot password !",style: TextStyle(color: Colors.grey[600]),),
          ]
          )
          ),
          const SizedBox(height: 20,),
          //sign in button
          GestureDetector(
            onTap:_isLoading? null : () async {
              if(_formKey.currentState!.validate()){
                setState(() {
                  _isLoading=true;
                });
                try{
                  if(_isLogin){
                    await Auth().loginWithEmailAndPassword(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                  );
                  }else {
                    await Auth().createUserWithEmailAndPassword(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                  }
                  setState(() {
                    _isLoading = false;
                  });
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(),),
                  );
                }on FirebaseAuthException catch (e){
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${e.message}"),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.teal[300],
                  ),
                  );
                }
              }
            },
          child: Container(
            padding: EdgeInsets.all(19),
            margin: EdgeInsets.symmetric(horizontal: 25),
            decoration: BoxDecoration(
              color: Colors.teal[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _isLoading? CircularProgressIndicator() : Text(_isLogin? "Log in " : "Sign up",
                style: TextStyle(color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
          )
          )
          ),
          const SizedBox(height: 50,),
          //or continue with
          const SizedBox(height: 20,),

          //google  + appel sign in button

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isLogin? "I don't have an account?" : "I have an account",style: TextStyle(color: Colors.grey[700]),),
              const SizedBox(width:10,),
               GestureDetector(
               child: Text(_isLogin? "Sign up" : "Log in",style: TextStyle(color: Colors.blue,fontWeight: FontWeight.bold),),
                 onTap: (){
                 setState(() {
                   _isLogin = !_isLogin;
                 });
                 _emailController.text = "";
                 _passwordController.text = "";
                 _passwordConfirmController.text = "";
                 }
               ),
            ],
          ),
          //not a menber , register
        ],
            )
        )
      ),
      )
      )
    );
  }
}
