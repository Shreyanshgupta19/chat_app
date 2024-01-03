import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key,});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _isLogin = true;
  bool _hiddenPassword = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _isAuthenticating = false;
  var _enteredUsername = '';

  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid || !_isLogin && _selectedImage == null) {
      // show error message like show snackbar...
      return;
    }// else
    _form.currentState!.save();
    // print(_enteredEmail);
    // print(_enteredPassword);
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail, password: _enteredPassword,);
        print(userCredentials);
      }
      else { //signup
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail, password: _enteredPassword,);
        final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = storageRef.getDownloadURL();
        print(userCredentials);
        print(imageUrl);

        await FirebaseFirestore.instance.collection('users').doc(userCredentials.user!.uid).set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) { // 'on' keyword define the type this error will be off And here we learned that in the end it will be an error of type FirebaseAuthException which in the end is just a more specific version or a specific kind of exception and therefore here, we can add FirebaseAuthException as the type that will be assumed for this error object
      if (error.code == 'email-already-in-use') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message ?? 'Authentication failed.'),
      ));
      setState(() {
        _isAuthenticating = false;
      });
    }
  }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .primary,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(!_isLogin) UserImagePicker(onPickImage: (pickedImage) { _selectedImage = pickedImage; }, ),
                Container(
                  margin: const EdgeInsets.only(
                    top: 30, bottom: 20, left: 20, right: 20,),
                  width: 200,
                  child: _isLogin
                      ? Image.asset('assets/images/chat.png')
                      : Image.asset('assets/images/singup.png'),
                ),
                Card(
                  margin: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          // this column will only take as much space as needed by its content essentially instead of taking as much space as it can get and having no boundaries on the vertical axis
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              // to turn off autocorrection because that can, of course, be super annoying if we are entering an email address and we are getting corrected all the time
                              textCapitalization: TextCapitalization.none,
                              // to ensure that the email address won't get capitalized so that the first character of the email address won't be uppercase because that can also be very annoying
                              validator: (value) {
                                if (value == null || value
                                    .trim()
                                    .isEmpty || !value.contains('@')) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredEmail = value!;
                              },
                            ),
                            if(!_isLogin)
                            TextFormField(
                              validator: (value){
                              if(value == null || value.isEmpty || value.trim().length <4){
                                return 'Please enter at least 4 characters';
                              }
                              return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Username',
                              ),
                              enableSuggestions: false,
                              onSaved: (value) {
                                _enteredUsername = value!;
                              },
                            ),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _hiddenPassword = !_hiddenPassword;
                                      // or _hiddenPassword = _hiddenPassword ? false : true;
                                    });
                                  },
                                  icon: _hiddenPassword == true
                                      ? const Icon(
                                      Icons.remove_red_eye_outlined)
                                      : const Icon(Icons.password),),
                              ),
                              obscureText: _hiddenPassword,
                              obscuringCharacter: '*',
                              validator: (value) {
                                if (value == null || value
                                    .trim()
                                    .length < 8) {
                                  return 'Password must be at least 8 characters long.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredPassword = value!;
                              },
                            ),
                            const SizedBox(height: 12,),
                            if(_isAuthenticating)
                              CircularProgressIndicator(),
                              if(!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme
                                    .of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: Text(_isLogin ? 'Login' : 'Signup'),),
                            if(!_isAuthenticating)
                              TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _form.currentState!.reset();
                                  // or _isLogin = _isLogin ? false : true;
                                });
                              },
                              child: Text(_isLogin
                                  ? 'Create an account'
                                  : 'I already have an account'),),

                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }
  }
