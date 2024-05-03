import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_buddies/components/my_button.dart';
import 'package:food_buddies/components/my_textfield.dart';
import 'package:food_buddies/components/square_tile.dart';
import 'package:food_buddies/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text editing controllers
  final emailController = TextEditingController();

  final passwordController = TextEditingController();
  final confirmedPasswordController = TextEditingController();

  // sign user up method
  void signUserUp() async {

      showDialog(context: context, 
      builder: (context) {
        return const Center(
          child:  CircularProgressIndicator(),
        );
      });
      //try creating the user
    try{
      //check if password and confirmed password are same
      if(passwordController.text == confirmedPasswordController.text){
            await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailController.text, password: passwordController.text);
      }
      else{
        //error message - passwords do not match
        wrongEmailMessage("Passwords do not Match ! ");
      }
            Navigator.pop(context); 
    }
    on FirebaseAuthException catch(e){
      Navigator.pop(context); 
      wrongEmailMessage("Wrong Credentials");
      
    }

    

    
  }
  void wrongEmailMessage(String text){
      showDialog(context: context, builder: (context){
        return  AlertDialog(
          title: Text(text, style: const TextStyle(color: Colors.white),),
        );
      },
      );
    }
    // void wrongPasswordMessage(){
    //   showDialog(context: context, builder: (context){
    //    return  const AlertDialog(
    //       title: Text('Incorrect Password'),
    //     );
    //   },
    //   );
    // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
            
                // logo
                const Icon(
                  Icons.lock,
                  size: 100,
                ),
            
                const SizedBox(height: 25),
            
                // welcome back, you've been missed!
                Text(
                  'Create an account',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
            
                const SizedBox(height: 25),
            
                // username textfield
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
            
                const SizedBox(height: 10),
            
                // password textfield
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
            
                const SizedBox(height: 10),

                // password textfield
                MyTextField(
                  controller: confirmedPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
            
                const SizedBox(height: 10),
            
               
            
                // sign in button
                MyButton(
                  text: "Sign Up",
                  onTap: signUserUp,
                ),
            
                const SizedBox(height: 50),
            
                // or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
            
                const SizedBox(height: 25),
            
                // google + apple sign in buttons
                 Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // google button
                    SquareTile(
                      onTap: () => AuthService().signInWithGoogle(),
                      imagePath: 'lib/images/google.png'),
            
                  ],
                ),
            
               
            
                // not a member? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already having an  account?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Login now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}