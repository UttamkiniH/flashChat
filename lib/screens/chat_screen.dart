import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
final _firestore = FirebaseFirestore.instance;
User loggedInUser;


class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth= FirebaseAuth.instance;

 String messageText;

 @override
 void initState() {
    super.initState();
    getCurrentUser();
  }
  void getCurrentUser() async
  {
    try {
      final user =  _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    }
    catch(e){
      print(e);
    }
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
              }),
        ],
        title: Text('Chat',
        style: TextStyle(
          fontWeight: FontWeight.bold
        ),),

        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      //messageText + loggedInUser.email
                      _firestore.collection('messages').add({
                        'text':messageText,
                        'sender': loggedInUser.email,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').orderBy('timestamp').snapshots(),

        builder: (context, snapshot){
          if(!snapshot.hasData){
            return Center(

              child: CircularProgressIndicator(
                backgroundColor: Colors.blueAccent,
              ),

            );
          }
          final messages = snapshot.data.docs.reversed;
          List<MessageBubble> messageBubbles = [];
          for ( var message in messages) {
            final messageData = message.data();
            final messageText = messageData['text'];
            final messageSender = messageData['sender'];

            final currentUser = loggedInUser.email;


            final messageBubble = MessageBubble(
                sender: messageSender,
                text: messageText,
                isMe: currentUser==messageSender,
            );
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
              children: messageBubbles,
            ),
          );
        }
    );
  }
}

//MessageBubbles

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender,this.text, this.isMe});
  final String sender;
  final String text;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget> [
          Text(sender,
          style: TextStyle(
            color:Colors.black,
            fontSize: 10.0,
          ),
          ),
          SizedBox(
            height: 10,
          ),
          Material(
          borderRadius: isMe ? BorderRadius.only(topLeft: Radius.elliptical(15, 15),
              topRight: Radius.elliptical(15, 15),
              bottomLeft:Radius.elliptical(15,15) ) : BorderRadius.only(topLeft: Radius.elliptical(15, 15),
              topRight: Radius.elliptical(15, 15),
              bottomRight:Radius.elliptical(15,15)),
          elevation: 8,
          color: isMe ? Colors.lightBlueAccent : Colors.white,
          child: Padding(
            padding:EdgeInsets.symmetric(vertical: 10,horizontal: 20),
            child: Text('$text',
              style: TextStyle(
                color: isMe? Colors.white : Colors.black54,
                fontSize: 18,
              ),),
          ),
        ),
      ]),
    );
  }
}
