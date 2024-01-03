import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewMessages extends StatefulWidget {
  const NewMessages({super.key,});

  @override
  State<NewMessages> createState() => _NewMessagesState();
}

class _NewMessagesState extends State<NewMessages> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {

    final  enteredMessage = _messageController.text;

    if(enteredMessage.trim().isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus(); // this will close any open keyboard by removing the focus from input field
    _messageController.clear();

    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    FirebaseFirestore.instance.collection('chat').add({
      'text': enteredMessage,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'username': userData.data()!['username'],
      'userImage': userData.data()!['image_url'],
    });

  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14,),
      child: Row(
        children: [
          Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences, // to make sure how the device supports the user with entering text, that it, for example should capitalize the start of every new sentence which you can turn off or configure differently
                autocorrect: true,
                enableSuggestions: true,
                decoration: InputDecoration(
                  labelText: 'Send a message...',
                ),
              ),
          ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
              onPressed: _submitMessage,
              icon: const Icon(Icons.send),
          )
        ],
      )
    );
  }
}