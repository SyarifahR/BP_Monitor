import 'package:flutter/material.dart';
import 'package:test_bt/pages/route_generator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'dart:io';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Directory directory = await pathProvider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  // Hive.registerAdapter(NIBPRecordAdapter());
  // Hive.registerAdapter(RawAdapter());
  await Hive.initFlutter();
  await Hive.openBox('boxA');
  await Hive.initFlutter();
  await Hive.openBox('boxB');
  await Hive.initFlutter();
  await Hive.openBox('boxLive');
  await Hive.initFlutter();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/home',
    onGenerateRoute: RouteGenerator.generateRoute
  ));
}


