import 'package:beacon_share/constants.dart';
import 'package:flutter/material.dart';

class HikeButton extends StatelessWidget {

  final Function onTap;
  final String text;
  final double textSize;
  final Color textColor;
  final Color borderColor;
  final Color buttonColor;
  final double buttonWidth;
  final double buttonHeight;
  HikeButton({this.onTap,this.borderColor,this.buttonColor,this.text,this.textColor,this.buttonWidth,this.buttonHeight,this.textSize});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: buttonColor??kYellow,
      shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(50.0),
          side: BorderSide(color: borderColor??Colors.white)
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: buttonWidth??32,vertical: buttonHeight??32),
        child: Text(text,style: TextStyle(color: textColor??Colors.white,fontSize: textSize??18),),
      ),
      onPressed: onTap,
    );
  }
}