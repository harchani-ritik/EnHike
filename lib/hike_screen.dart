import 'dart:async';

import 'package:beacon_share/components/shape_painter.dart';
import 'package:beacon_share/constants.dart';
import 'package:beacon_share/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'components/hike_button.dart';
import 'components/location.dart';

final _firestore = Firestore.instance;
double _lat = 0, _long = 0;

class HikeScreen extends StatefulWidget {
  final String _passkey, hikerName;
  final bool isReferred;
  HikeScreen(this._passkey, {this.isReferred, this.hikerName});
  @override
  _HikeScreenState createState() => _HikeScreenState();
}

//Assuming passkey validation is done previously
class _HikeScreenState extends State<HikeScreen> {
  double _screenHeight,_screenWidth;
  int _numberOfHikers;
  String _hikerName;
  String _linkMessage;
  String _expiringAt;
  bool _isGeneratingLink = false, _isReferred;
  List<String> hikers = [];

  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _kBeaconPosition =
      CameraPosition(target: LatLng(25.3161907, 82.9890129), zoom: 12.0);

  fetchHikersData() async {
    _isReferred = widget.isReferred;
    _hikerName = widget.hikerName;
    try {
      await for (var snapshot in _firestore
          .collection('hikes')
          .document(widget._passkey)
          .snapshots()) {
        print(snapshot.data);
        List<String> newHikers = [];
        _numberOfHikers = snapshot.data['numberOfHikers'];
        _expiringAt = snapshot.data['expiringAt'];
        for (int i = 0; i < _numberOfHikers; i++) {
          newHikers.add(snapshot.data['hiker$i']);
        }
        print('New hikers are ${newHikers.length}');
        setState(() {
          _lat = snapshot.data['lat'] ?? 0.0;
          _long = snapshot.data['long'] ?? 0.0;
        });
        setState(() {
          hikers = newHikers;
        });

        print('There are ${hikers.length} hikers in this room');
        if (hikers[0] == _hikerName) {
          Location location = Location();
          await location.getCurrentLocation();
          print('Sending your location');
          _firestore.collection('hikes').document(widget._passkey).updateData({
            'lat': location.lat,
            'long': location.long,
          });
        }
      }
    } catch (e) {
      print('InvalidPasskeyException: $e');
    }
  }


  void init()=> initState();

  @override
  void initState() {
    super.initState();
    fetchHikersData();
  }

  @override
  Widget build(BuildContext context) {
    _screenHeight=MediaQuery.of(context).size.height;
    _screenWidth=MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ModalProgressHUD(
        inAsyncCall: _isGeneratingLink,
        child: Stack(
          children: <Widget>[
            Scaffold(
              body: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kBeaconPosition,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
            CustomPaint(
              size: Size(_screenWidth,_screenHeight),
              painter: ShapePainter(),
            ),
            _isReferred?
                Container(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: HikeButton(
                        buttonHeight: 25,
                        buttonColor: kYellow,
                        buttonWidth: 64,
                        text: 'Add Me',
                        onTap: (){
                            showDialog(context: (context),
                            builder: (context)=>Dialog(
                              child: Container(
                                height: 200,
                                child: Scaffold(
                                  body: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: <Widget>[
                                        Flexible(
                                          child: TextFormField(
                                            onChanged: (key){
                                              _hikerName=key;
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'Username Here',hintStyle:TextStyle(fontSize: 20,color: kBlack),
                                              labelText: 'Username',labelStyle: TextStyle(fontSize: 14,color: kYellow),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10,),
                                        HikeButton(
                                          text: 'Done',
                                          buttonWidth: 48,
                                          onTap: (){
                                            bool isUsernameUnique=true;
                                            for(int i=0;i<hikers.length;i++){
                                              if(hikers[i]==_hikerName){
                                                isUsernameUnique=false;
                                                break;
                                               }
                                            }
                                              if(isUsernameUnique){
                                                _firestore.collection('hikes').document(widget._passkey).updateData({
                                                  'hiker$_numberOfHikers': _hikerName,
                                                  'numberOfHikers': _numberOfHikers + 1
                                                });
                                                SchedulerBinding.instance.addPostFrameCallback((_) {
                                                  setState(() {
                                                    _isReferred=false;
                                                  });
                                                  Navigator.pop(context);
                                                });
                                              }
                                              else{
                                                Fluttertoast.showToast(msg: 'Username already taken, please take any other name');
                                              }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ));
                        },
                      ),
                    ),
                  ),
                )
              :Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(topRight: Radius.circular(10),topLeft:Radius.circular(10) )
                      ),
                      height: 250,
                      child: Scaffold(
                        body: Column(
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    children: [
                                      TextSpan(text: 'Beacon expiring at ${_expiringAt==null?'<Fetching data>':DateFormat("hh:mm a").format(DateTime.fromMillisecondsSinceEpoch(int.parse(_expiringAt))).toString()}\n',style: TextStyle(fontSize: 16)),
                                      TextSpan(text: 'Beacon holder at: ${_lat.toStringAsFixed(4)}, ${_long.toStringAsFixed(4)}\n',style: TextStyle(fontSize: 14)),
                                      TextSpan(text: '\nLong press on any hiker to hand over the beacon\n',style: TextStyle(fontSize: 12)),
                                    ]
                                  ),
                                ),
                              ),
                                  decoration: BoxDecoration(
                                  color: kBlue,
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(10),topLeft:Radius.circular(10) )
                              ),
                              height: 80,
                            ),
                            Container(
                              height: 170,
                              child: ListView.builder(
                                itemCount: hikers.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Container(
                                    child: GestureDetector(
                                      onLongPress: (){
                                        hikers[index]==_hikerName?Fluttertoast.showToast(msg: 'Yeah, that\'s you'):hikers[0]==_hikerName?relayBeacon(hikers[index], index):Fluttertoast.showToast(msg: 'You dont have beacon to relay');
                                      },
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: kYellow,
                                          radius: 18,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Icon(Icons.person_outline,color: Colors.white,)                                          ),
                                        ),
                                        title: Text(hikers[index],style: TextStyle(color: Colors.black,fontSize: 18),
                                        ),
                                        trailing: index==0?Icon(
                                          Icons.room,
                                          color: kYellow,
                                          size: 40,
                                      ):Container(width: 10,),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment(1,-0.8),
              child: FloatingActionButton(
                onPressed: (){
                  showDialog(context: context,
                  builder: (context)=>Dialog(
                    child: Container(
                      height: 400,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 16),
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text('Invite Friends',style: TextStyle(fontSize: 24),),
                              ),
                            ),
                            SizedBox(height: 30,),
                            Flexible(
                              child: HikeButton(
                                  textSize: 20,
                                  text: 'Generate URL',
                                  textColor: Colors.white,
                                  buttonColor: kYellow,
                                  onTap: ()async{
                                    generateUrl();
                                    Navigator.pop(context);
                                  }
                              ),
                            ),
                            SizedBox(height: 10,),
                            Flexible(
                              child: HikeButton(
                                  textSize: 20,
                                  text: 'Copy Passkey',
                                  textColor: Colors.white,
                                  buttonColor: kYellow,
                                  onTap: copyPasskey,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ));
                },
                backgroundColor: kYellow,
                child: Icon(Icons.person_add),
              ),
            ),
            Align(
              alignment: Alignment(-0.8,-0.8),
              child: GestureDetector(
                onTap: (){
                  if(widget.isReferred) {
                    Navigator.pop(context);
                  }
                  else{
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>WelcomeScreen()));
                  }
                },
                child: Icon(
                  Icons.arrow_back,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  copyPasskey() {
    Clipboard.setData(ClipboardData(text: widget._passkey));
    Fluttertoast.showToast(msg: 'PASSKEY: ${widget._passkey}  COPIED');
  }

  generateUrl() async {
    if (!_isGeneratingLink) {
      await _createDynamicLink(true);
      Clipboard.setData(ClipboardData(text: _linkMessage));
      Fluttertoast.showToast(msg: 'URL COPIED');
    }
  }

  Future<void> _createDynamicLink(bool short) async {
    setState(() {
      _isGeneratingLink = true;
    });
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://harchanibeaconshare.page.link',
      link: Uri.parse(
          'https://dynamic.link.example/hikeScreen?${widget._passkey}'),
      androidParameters: AndroidParameters(
        packageName: 'com.harchani.beacon_share',
        minimumVersion: 0,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      iosParameters: IosParameters(
        bundleId: 'com.google.FirebaseCppDynamicLinksTestApp.dev',
        minimumVersion: '0',
      ),
    );

    Uri url;
    if (short) {
      final ShortDynamicLink shortLink = await parameters.buildShortLink();
      url = shortLink.shortUrl;
    } else {
      url = await parameters.buildUrl();
    }
    setState(() {
      _linkMessage = url.toString();
      _isGeneratingLink = false;
    });
  }

  void relayBeacon(String newBeaconHolderName,int hikerNumber){
    _firestore.collection('hikes').document(widget._passkey).updateData({
      'hiker0':newBeaconHolderName,
      'hiker$hikerNumber':_hikerName,
    });
    Fluttertoast.showToast(msg: 'Beacon handed over to $newBeaconHolderName');
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => showExitDialog(context),
    )) ?? false;
  }

  AlertDialog showExitDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Exit App',style: TextStyle(fontSize: 25,color: kYellow),),
      content: Text('Are you sure you wanna stop sending and receiving location?',style: TextStyle(fontSize: 16,color: kBlack),),
      actions: <Widget>[
        HikeButton(
          buttonHeight: 20,
          buttonWidth: 40,
          onTap: () => Navigator.of(context).pop(false),
          text: 'No',
        ),
        HikeButton(
          buttonHeight: 20,
          buttonWidth: 40,
          onTap: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
          text: 'Yes',
        ),
      ],
    );
  }
}
