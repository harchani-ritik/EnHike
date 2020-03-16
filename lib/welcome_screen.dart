import 'dart:ui';

import 'package:beacon_share/hike_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_duration_picker/flutter_duration_picker.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'components/hike_button.dart';
import 'components/shape_painter.dart';
import 'constants.dart';

final _firestore = Firestore.instance;
class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isCreatingHikeRoom=false;
  String _hikerName; DateTime selectedTime=DateTime.now().subtract(Duration(hours: 1));
  Duration _duration = Duration(hours: 0,minutes: 0);

  void initDynamicLinks() async {
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      print('Deep Link: $deepLink');
      String receivedPasskey = deepLink.toString().substring(deepLink.toString().indexOf('?')+1,deepLink.toString().length).toString();
      Navigator.push(context,MaterialPageRoute(builder: (context) => HikeScreen(receivedPasskey,isReferred: true,)));
    }

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          final Uri deepLink = dynamicLink?.link;

          if (deepLink != null) {
            print('Deep Link: $deepLink');
            String receivedPasskey = deepLink.toString().substring(deepLink.toString().indexOf('?')+1,deepLink.toString().length).toString();
            Navigator.push(context,MaterialPageRoute(builder: (context) => HikeScreen(receivedPasskey,isReferred: true,),));
          }
        }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });
  }

  createHikeRoom()async{
    setState(() {
      isCreatingHikeRoom=true;
    });
    DocumentReference ref = await _firestore.collection('hikes').add({
      'hiker0': _hikerName??'John Doe',
      'numberOfHikers': 1,
      'expiringAt': selectedTime.millisecondsSinceEpoch.toString(),
    });
    String passKey = ref.documentID;
    setState(() {
      isCreatingHikeRoom=false;
    });
    Navigator.pop(context);
    Navigator.push(context,MaterialPageRoute(builder: (context)=> HikeScreen(passKey,isReferred: false,hikerName: _hikerName??'John Doe',)));
  }

  validatePasskey(String enteredPasskey) async{
    setState(() {
      isCreatingHikeRoom=true;
    });
    try {
      await _firestore.collection('hikes').document(enteredPasskey).get().then((
          value) {
        value.exists?Navigator.push(context,MaterialPageRoute(builder: (context) => HikeScreen(enteredPasskey,isReferred: true,),)):Fluttertoast.showToast(msg: 'Invalid Passkey');
      });
    }
    catch(e){
      print(e);
      Fluttertoast.showToast(msg: 'Invalid Passkey');
    }
    setState(() {
      isCreatingHikeRoom=false;
    });
  }
  double _screenHeight,_screenWidth;
  @override
  void initState() {
    super.initState();
    initDynamicLinks();
  }

  @override
  Widget build(BuildContext context) {
    _screenHeight=MediaQuery.of(context).size.height;
    _screenWidth=MediaQuery.of(context).size.width;
    return SafeArea(
      child: ModalProgressHUD(
        inAsyncCall: isCreatingHikeRoom,
        child: Stack(
          children: <Widget>[
            Scaffold(
              body: Container(
                margin: EdgeInsets.fromLTRB(0,100,0,0),
                child: Center(
                  child: Image(
                    image: AssetImage('images/hikers_group.png'),
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: Size(_screenWidth,_screenHeight),
              painter: ShapePainter(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8,vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  HikeButton(
                    text: 'Create Hike',
                    textColor: Colors.white,
                    borderColor: Colors.white,
                    buttonColor: kYellow,
                    buttonWidth: 64,
                    onTap: (){
                      showDialog(context: context,
                          builder: (context)=> Dialog(
                            child: Container(
                              height: 500,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 16),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: TextFormField(
                                          onChanged: (name){
                                            _hikerName=name;
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Name Here',hintStyle:TextStyle(fontSize: 20,color: kBlack),
                                            labelText: 'Username',labelStyle: TextStyle(fontSize: 14,color: kYellow),
                                          ),
                                        ),
                                      ),
                                      color: kLightBlue,
                                    ),
                                    SizedBox(height: 30,),
                                    Flexible(
                                      flex: 3,
                                      child: Container(
                                        color: kLightBlue,
                                        child: Column(
                                          children: <Widget>[
                                            Text('Select Beacon Duration',style: TextStyle(color: kYellow,fontSize: 12),),
                                            Expanded(
                                              flex: 5,
                                              // Use it from the context of a stateful widget, passing in
                                              // and saving the duration as a state variable.
                                                child: DurationPicker(
                                                  height: 100,
                                                  width: double.infinity,
                                                  duration: _duration,
                                                  onChange: (val) {
                                                    setState(() {
                                                      _duration=val;
                                                      print(_duration);
                                                    });
                                                  },
                                                  snapToMins: 1.0,
                                                ))
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 30,),
                                    Flexible(
                                      flex: 2,
                                      child: HikeButton(
                                        buttonWidth: 48,
                                        text: 'Create',
                                        textColor: Colors.white,
                                        buttonColor: kYellow,
                                        onTap: (){
                                          Navigator.pop(context);
                                          selectedTime=DateTime.now().add(_duration);
                                          createHikeRoom();
                                        }
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ));
                    },
                  ),
                  SizedBox(width: double.infinity,height: 20,),
                  HikeButton(
                    text: 'Join a Hike',
                    textColor: kYellow,
                    borderColor: kYellow,
                    buttonColor: Colors.white,
                    buttonWidth: 64,
                    onTap: (){
                      String enteredPasskey;
                      showDialog(context: context,
                          builder: (context)=> Dialog(
                            child: Container(
                              height: 250,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 16),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: TextFormField(
                                          onChanged: (key){
                                            enteredPasskey=key;
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Passkey Here',hintStyle:TextStyle(fontSize: 20,color: kBlack),
                                            labelText: 'Passkey',labelStyle: TextStyle(fontSize: 14,color: kYellow),
                                          ),
                                        ),
                                      ),
                                      color: kLightBlue,
                                    ),
                                    SizedBox(height: 30,),
                                    Flexible(
                                      child: HikeButton(
                                          buttonWidth: 48,
                                          text: 'Validate',
                                          textColor: Colors.white,
                                          buttonColor: kYellow,
                                          onTap: (){
                                            Navigator.pop(context);
                                            validatePasskey(enteredPasskey);
                                          }
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ));
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}





