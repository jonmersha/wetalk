import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wetalk/widget/image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isAuthenticating = false;
  var _enteredEmailValue = '';
  var _enteredPasswordValue = '';
  var _enteredUserNamelValue = '';
  File? _selectedImage;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !_isLogin && _selectedImage == null) {
      //Show Error Message
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        //login to firebase
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmailValue, password: _enteredPasswordValue);

        //print(userCredentials);
      } else {
        //create users using email

        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmailValue, password: _enteredPasswordValue);
        final storgeRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        await storgeRef.putFile(_selectedImage!);
        final imageUrl = await storgeRef.getDownloadURL();

        FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'user_name': _enteredUserNamelValue,
          'email': _enteredEmailValue,
          'imageUrl': imageUrl
        });
      }
      setState(() {
        _isAuthenticating = false;
      });
    } on FirebaseAuthException catch (error) {
      setState(() {
        _isAuthenticating = false;
      });
      // if(error.code=='')
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
          child: SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            margin: const EdgeInsets.only(top: 30, bottom: 20, right: 20),
            width: 200,
            child: Image.asset('asset/chat.png'),
          ),
          Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(children: [
                    if (!_isLogin)
                      UserImagePicker(
                        onPickImage: (pickedImage) {
                          _selectedImage = pickedImage;
                        },
                      ),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Email Address'),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'email address required';
                        }

                        if (!value.contains('@')) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredEmailValue = value!;
                      },
                    ),
                    if (!_isLogin)
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'User Name'),
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (value == null || value.trim().length < 4) {
                            return 'User Name required required';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredUserNamelValue = value!;
                        },
                      ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().length < 6) {
                          return 'Password must be atleast 6 charactes long';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredPasswordValue = value!;
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    if (!_isAuthenticating)
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          onPressed: _submit,
                          child: Text(_isLogin ? 'Login' : 'SignUp')),
                    if (!_isAuthenticating)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(_isLogin
                            ? 'Create an Account'
                            : 'Already heve Account,Login'),
                      ),
                    if (_isAuthenticating)
                      CircularProgressIndicator(
                        backgroundColor: Colors.black,
                      )
                  ]),
                )),
          )
        ]),
      )),
    );
  }
}
