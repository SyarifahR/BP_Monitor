import 'package:flutter/material.dart';
import 'package:test_bt/pages/home.dart';
import 'package:test_bt/pages/history.dart';
import 'package:hive/hive.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings){
    final args = settings.arguments;

    switch (settings.name){
      case '/home':
        return MaterialPageRoute(builder: (context) => Home());
      case '/history':
        return MaterialPageRoute(builder: (context) => History(itemlist: args as Box<dynamic>));
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute(){
    return MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('ERROR'),
          centerTitle: true,
        ),
        body: Center(
          child: Text('Page not found!'),
        ),
      );
    });
  }
}
