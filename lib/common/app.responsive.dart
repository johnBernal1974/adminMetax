import 'package:flutter/material.dart';


class AppResponsive extends StatelessWidget {

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const AppResponsive({super.key, required this.mobile, required this.tablet, required this.desktop});

  static bool isMobile(context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(context) => MediaQuery.of(context).size.width < 1100 && MediaQuery.of(context).size.width >= 600;
  static bool isDesktop(context) => MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    if(isDesktop(context)){
      return desktop;
    }
    else if(isTablet(context) && tablet != null){
      return tablet;
    }else{
      return mobile;
    }
  }
}
