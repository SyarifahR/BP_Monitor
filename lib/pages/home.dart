import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Home extends StatefulWidget{
  Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  String stateText = 'Connecting';
  String connectButtonText = 'Disconnect';
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription<BluetoothDeviceState>? _stateListener;
  List<BluetoothService> bluetoothService = [];
  Map <String, List<int>> notifyDatas = {};
  final boxA = Hive.box('boxA');
  final boxB = Hive.box('boxB');
  final boxLive = Hive.box('boxLive');
  List<ScanResult> scanResultList = [];
  late BluetoothDevice device;
  List<Map<String, dynamic>> itemsA = [];
  List<Map<String, dynamic>> itemsB = [];
  String device_name = '';
  String device_channel = '';
  String device_characteristic = '';
  bool _isScanning = false;
  bool record = false;
  bool record_again = true;
  bool duplicate = false;
  bool reset = true;
  bool increment = true;
  late FToast fToast;

  @override
  initState() {
    super.initState();
    initBle();
    refreshA();
    refreshB();
    fToast = FToast();
    fToast.init(context);
  }

  void initBle() {
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      setState(() {});
    });
  }

  scan() async {
    if (!_isScanning) {
      scanResultList.clear();
      flutterBlue.startScan(timeout: Duration(seconds: 4));
      flutterBlue.scanResults.listen((results) {
        scanResultList = results;
        setState(() {});
        for(ScanResult item in scanResultList){
          String name = 'BP_01000019';
          if(item.device.name == name){
            device_name = item.device.name;
            device = item.device;
            connect();
            _stateListener = device.state.listen((event) {
              debugPrint('event :  $event');
              if (deviceState == event) {
                return;
              }
            });
          }
        }
      });
    } else {
      flutterBlue.stopScan();
    }
  }

  void refreshA() {
    final data_A = boxA.keys.map((key) {
      final value = boxA.get(key);
      return {"key": key, "device": value['device'], "date": value['date'], "time": value['time'], "sys": value["sys"], "dia": value['dia'], "mean": value['mean'], "pr": value['pr']};
    }).toList();
    int last_index = boxA.length - 1;
    // Map<String, dynamic> last_item = data_A.toList()[last_index];
    // Map<String, dynamic> sec_last_item = data_A.toList()[last_index-1];
    // if (last_item[3] != sec_last_item[3] && last_item[4] != sec_last_item[4]){
    //   boxA.deleteAt(last_index);
    //   print(boxA.toMap());
    // }
    setState(() {
      itemsA = data_A.toList();
      // items = data_bp.reversed.toList();
    });
  }

  void refreshB() {
    final data_B = boxB.keys.map((key) {
      final value = boxB.get(key);
      return {"key": key, "device": value['device'], "date": value['date'], "time": value['time'], "hex_data": value['hex_data']};
    }).toList();
    // int last_index = boxB.length -1;
    // Map<String, dynamic> last_item = data_B.toList()[last_index];
    // Map<String, dynamic> sec_last_item = data_B.toList()[last_index-1];
    // if (last_item[3] != sec_last_item[3] && last_item[4] != sec_last_item[4]){
    //   boxB.deleteAt(last_index);
    //   print(boxB.toMap());
    // }
    setState(() {
      itemsB = data_B.toList();
      // items = data_bp.reversed.toList();
    });
  }

  Future<void> InjectA (Map<String, dynamic> newItemA) async {
    record = false;
    record_again = false;

    // int old_lengthA = boxA.length;
    // print(old_lengthA);

    if(!duplicate){
      await boxA.add(newItemA);
      // int new_lengthA = boxA.length;
      // print(new_lengthA);
      refreshA();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data has been added')));
      duplicate = true;
    }else if (duplicate){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already added before')));
    }

    // ## Clearing the Database
    // await boxA.deleteAll(boxA.keys);
    // print(boxA.toMap());
    // ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Databases has been cleared')));
  }

  Future<void> InjectB(Map<String, dynamic> newItemB) async {

    await boxB.add(newItemB);
    refreshB();

    // ## Clearing the Database
    // await boxB.deleteAll(boxB.keys);
    // print(boxB.toMap());
  }

  @override
  void dispose() {
    _stateListener?.cancel();
    disconnect();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  setBleConnectionState(BluetoothDeviceState event) {
    switch (event) {
      case BluetoothDeviceState.disconnected:
        stateText = 'Disconnected';
        break;
      case BluetoothDeviceState.disconnecting:
        stateText = 'Disconnecting';
        break;
      case BluetoothDeviceState.connected:
        stateText = 'Connected';
        break;
      case BluetoothDeviceState.connecting:
        stateText = 'Connecting';
        break;
    }
    deviceState = event;
    setState(() {});
  }

  Future<bool> connect() async {

    Future<bool>? returnValue;
    setState(() {
      stateText = 'Connecting';
    });

    await device
        .connect(autoConnect: false)
        .timeout(Duration(milliseconds: 15000),
        onTimeout: () {
      returnValue = Future.value(false);
      debugPrint('timeout failed');
      setBleConnectionState(BluetoothDeviceState.disconnected);
    }).then((data) async {
      bluetoothService.clear();
      if (returnValue == null) {
        debugPrint('connection successful');
        print('start discover service');
        List<BluetoothService> bleServices = await device.discoverServices();
        setState((){
          bluetoothService = bleServices;
          for(BluetoothService item in bluetoothService){
            String channel = '00001810-0000-1000-8000-00805f9b34fb';
            if(item.uuid.toString() == channel){
              device_channel = item.uuid.toString();
              bluetoothService = [item];
              showToast();
            }
          }
        });
        for (BluetoothService service in bluetoothService){
          print('============================================');
          print('Service UUID: ${service.uuid}');
          if (device_channel.isNotEmpty){
            for (BluetoothCharacteristic c in service.characteristics){
              if (c.properties.notify && c.descriptors.isNotEmpty){
                for (BluetoothDescriptor d in c.descriptors){
                  print('BluetoothDescriptor uuid ${d.uuid}');
                  if (d.uuid == BluetoothDescriptor.cccd){
                    print('d.lastValue: ${d.lastValue}');
                  }
                }
                if (!c.isNotifying){
                  try {
                    await c.setNotifyValue(true);
                    notifyDatas[c.uuid.toString()] = List.empty();
                    c.value.listen((value){
                      print('${c.uuid}: $value');
                      setState(() {
                        notifyDatas[c.uuid.toString()] = value;
                      });
                    });
                    await Future.delayed(const Duration(milliseconds: 500));
                  } catch (e){
                    print('error ${c.uuid} $e');
                  }
                }
              }
            }
          }
        }
        returnValue = Future.value(true);
      }
    });
    return returnValue ?? Future.value(false);
  }

  void disconnect() {
    try {
      setState(() {
        stateText = 'Disconnecting';
      });
      device.disconnect();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {

    String service = '';
    for(BluetoothService r in bluetoothService){
      setState(() {
        service = reading(r).toString();
      });
    }
    final List<String> dataList = service.split(",");
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String device = device_name;
    String date = DateFormat('yyyy-MM-dd').format(tsdate);
    String time = DateFormat('HH:mm:ss').format(tsdate);
    String sys = '0';
    String dia = '0';
    String mean = '0';
    String pr = '0';
    var sys_ = 0;
    var dia_ = 0;
    if (service.isNotEmpty){
      setState(() {
        sys = dataList[1];
        dia = dataList[3];
        mean = dataList[5];
        pr = dataList[14];
        sys_ = int.parse(sys);
        dia_ = int.parse(dia);
      });
    }
    String level = '';
    if(sys_ == 0 || dia_ == 0){
      level = 'scanning..';
    }else if(sys_ < 90 || dia_ < 60){
      level = 'LOW';
    }else if(sys_ < 120 && dia_ < 80){
      level = 'NORMAL';
    }else if(sys_ < 140 || dia_ < 90){
      level = 'PREHYPERTENSION';
    }else if(sys_ < 140 || dia_ < 89){
      level = 'HYPERTENSION \n(Stage 1)';
    }else if(sys_ > 140 || dia_ >= 90){
      level = 'HYPERTENSION \n(Stage 2)';
    }else if(sys_ > 180 || dia_ > 120){
      level = 'HYPERTENSION \n(Emergency)';
    }else{
      level = '-------';
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[800],
      body:
      device_channel.isEmpty?
      SafeArea(
        child:
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Text(
                  'BLOOD',
                  style: TextStyle(color: Colors.white,
                      fontSize: 40.0,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(2.0, 2.0),
                          blurRadius: 6.0,
                          color: Colors.grey.withOpacity(0.8),
                        ),
                      ]),
                ),
              ),
              SizedBox(height: 10.0),
              Center(
                child: Text(
                  'PRESSURE',
                  style: TextStyle(color: Colors.white,
                      fontSize: 40.0,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(2.0, 2.0),
                          blurRadius: 6.0,
                          color: Colors.grey.withOpacity(0.8),
                        ),
                      ]),
                ),
              ),
              SizedBox(height: 10.0),
              Center(
                child: Text(
                  'MONITOR',
                  style: TextStyle(color: Colors.white,
                      fontSize: 40.0,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(2.0, 2.0),
                          blurRadius: 6.0,
                          color: Colors.grey.withOpacity(0.8),
                        ),
                      ]),
                ),
              ),
            ],
          ),
        ),
      )
      :
      Padding(
        padding: EdgeInsets.fromLTRB(40.0, 80.0, 40.0, 0.0),
        child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Date: ' + date,
                  style: TextStyle(
                    color: Colors.grey[50],
                    letterSpacing: 1.0,
                    fontSize: 14.0,
                  ),
                ),
                Text('Time: ' + time,
                  style: TextStyle(
                    color: Colors.grey[50],
                    letterSpacing: 1.0,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 80.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                          color: Colors.white,
                          letterSpacing: 2.0,
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              offset: Offset(2.0, 2.0),
                              blurRadius: 6.0,
                              color: Colors.grey.withOpacity(0.8),
                            ),
                          ]
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 80.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              children: <Widget>[
                                Text(
                                  'SYS',
                                  style: TextStyle(
                                    color: Colors.grey[100],
                                    fontSize: 18.0,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                Text(
                                  'mmHG',
                                  style: TextStyle(
                                    color: Colors.grey[100],
                                    fontSize: 12.0,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 60.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  sys,
                                  style: TextStyle(
                                    color: Colors.yellow[400],
                                    fontSize: 46.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              children: <Widget>[
                                Text(
                                  'DIA',
                                  style: TextStyle(
                                    color: Colors.grey[100],
                                    fontSize: 18.0,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                Text(
                                  'mmHG',
                                  style: TextStyle(
                                    color: Colors.grey[100],
                                    fontSize: 12.0,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 60.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  dia,
                                  style: TextStyle(
                                    color: Colors.yellow[400],
                                    fontSize: 46.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 40.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              children: <Widget>[
                                Text(
                                  'PUL',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    letterSpacing: 2.0,
                                    fontSize: 18.0,
                                  ),
                                ),
                                Text(
                                  '/min ',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    letterSpacing: 2.0,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 60.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  pr,
                                  style: TextStyle(
                                    color: Colors.purple[200],
                                    letterSpacing: 2.0,
                                    fontSize: 32.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 24.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              children: <Widget>[
                                Text(
                                  'MEAN',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    letterSpacing: 2.0,
                                    fontSize: 15.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 60.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  mean,
                                  style: TextStyle(
                                    color: Colors.purple[200],
                                    letterSpacing: 2.0,
                                    fontSize: 32.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey[700],
        // this creates a notch in the center of the bottom bar
        shape: const CircularNotchedRectangle(),
        notchMargin: 14,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => _buildPopupDialog(context),
                );
              },
            ),
            const SizedBox(
              width: 80,
            ),
            IconButton(
              icon: const Icon(
                Icons.list_alt_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/history', arguments: boxA);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(

        onPressed: scan,
        label: _isScanning? Text('\t\t\t\t\t\t\t\t$stateText\t\t\t\t\t\t\t\t') : Text('\t\t\t\t\t\t\t\tSCAN\t\t\t\t\t\t\t\t'),
        backgroundColor: Colors.blue[400],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void showToast() {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[50],
      ),
      child: Text("Succesfully paired with BP Monitor"),
    );

    fToast.showToast(
      child: toast,
      toastDuration: Duration(seconds: 3),
        positionedToastBuilder: (context, child) {
          return Positioned(
            child: child,
            top: 680.0,
            left: 76.0,
          );
        }
    );
  }

  Widget _buildPopupDialog(BuildContext context) {
    return new AlertDialog(
      title: const Text('Before start:'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("1. Turn on your phone`s Bluetooth \n\t\t\t\t\t& BP Scanner.\n\n2. Scan until the pairing success."),
        ],
      ),
      actions: <Widget>[
        new TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.black),
          // textColor: Theme.of(context).primaryColor,
          child: const Text('Close'),
        ),
      ],
    );
  }

  String reading (BluetoothService r){
    String name ='';
    name = characteristicInfo(r).toString();
    return name;
  }

  String characteristicInfo(BluetoothService r) {
    String name = '';
    String data = '';

    for (BluetoothCharacteristic c in r.characteristics) {
      data = '';
      if (c.properties.notify) {
        // properties += 'Notify ';
        if (notifyDatas.containsKey(c.uuid.toString())){
          if (notifyDatas[c.uuid.toString()]!.isNotEmpty){
            data = notifyDatas[c.uuid.toString()].toString();
          }
        }
      }
      if (data.isNotEmpty){
        final List<String> dataList = data.split(",");
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        String device = device_name;
        String date = DateFormat('yyyy-MM-dd').format(tsdate);
        String time = DateFormat('HH:mm:ss').format(tsdate);
        String sys = dataList[1];
        String dia = dataList[3];
        String mean = dataList[5];
        String pr = dataList[14];
        name += data;

        if (sys != dia){
          record = true;

          if (record && record_again && sys != dia ){
            InjectA({
              "device": device,
              "date": date,
              "time": time,
              "sys": sys,
              "dia": dia,
              "mean": mean,
              "pr": pr,
            });
            InjectB({
              "device": device,
              "date": date,
              "time": time,
              "hex_data": data,
            });
          }
        }else if(sys==dia){
          record_again = true;
          duplicate = false;
        }
      }
    }
    return name;
  }
}
