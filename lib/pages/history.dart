import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';


class History extends StatefulWidget {
  Box itemlist;
  History({Key? key, required this.itemlist}) : super(key: key);

  @override
  State<History> createState() => _HistoryState(itemlist);
}

class _HistoryState extends State<History> {
  int timestamp = DateTime.now().millisecondsSinceEpoch;
  // List<Map<String,dynamic>> month_list = [];
  List<Map<String,dynamic>> Current_ItemList = [];
  late Box itemlist;
  late Box monthSelected;
  _HistoryState(this.itemlist);
  bool sort = false;

  @override
  initState() {
    super.initState();
    refresh_itemlist(itemlist);
  }

  refresh_itemlist(Box<dynamic> itemlist){
    final final_itemlist = itemlist.keys.map((key) {
      final value = itemlist.get(key);
      // return {"key": key, "no": value['no'], "date": value['date'], "time": value['time'], "sys": value["sys"], "dia": value['dia'], "mean": value['mean'], "pr": value['pr']};
      return {"key": key, "date": value['date'], "time": value['time'], "sys": value["sys"], "dia": value['dia'], "mean": value['mean'], "pr": value['pr']};
    }).toList();
    if (sort == false){
      setState(() {
        // Current_ItemList = final_itemlist.toList();
        Current_ItemList = final_itemlist.reversed.toList();
      });
    }else if (sort == true){
      setState(() {
        Current_ItemList = final_itemlist.toList();
        // Current_ItemList = final_itemlist.reversed.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);

    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        toolbarHeight: 60,
        title: Text('HISTORY',style: TextStyle(color: Colors.white,letterSpacing:1.0,fontWeight: FontWeight.bold,fontSize: 20.0)),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 30.0,
      ),
      body: Padding(padding: EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 20.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        !sort?
                        IconButton(
                          icon: const Icon(
                            Icons.undo_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              sort = true;
                              refresh_itemlist(itemlist);
                            });
                          },
                        )
                        :IconButton(
                          icon: const Icon(
                            Icons.redo_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              sort = false;
                              refresh_itemlist(itemlist);
                            });
                          },
                        ),
                      ]
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              Center(
                child: Text(
                  'NIBP RECORDS\t',
                  style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Center(
                    child:
                    Container(
                      height: 350,
                      padding: const EdgeInsets.all(10),
                      color: Colors.blueGrey[50],
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 20.0),
                      child:
                      SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child:
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Center(
                            child:
                            DataTable(
                              columnSpacing: 8,
                              horizontalMargin: 0,
                              dataRowHeight: 40,
                              showCheckboxColumn: false,

                              columns: [
                                // DataColumn(label: Expanded(child: Center(child: Text('NO.',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),)),
                                DataColumn(label: Expanded(child: Center(child: Text('DATE',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),)),
                                DataColumn(label: Expanded(child: Center(child: Text('TIME',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),)),
                                DataColumn(label: Expanded(child: Center(child: Text('SYSTOLIC\n/mmHG',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),)),
                                DataColumn(label: Expanded(child: Center(child: Text('DIASTOLIC\n/mmHG',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),)),
                                DataColumn(label: Expanded(child: Center(child: Text('MEAN',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),)),
                                DataColumn(label: Expanded(child: Center(child: Text('PULSE RATE\n/min',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),)),
                              ],
                              rows: Current_ItemList.map((e) => DataRow(
                                cells: [
                                  // DataCell(Container(width:25,child:Text(e['no'].toString(),style: TextStyle(fontSize: 12),textAlign: TextAlign.center))),
                                  DataCell(Container(width:70,child:Text(e['date'].toString(),style: TextStyle(fontSize: 12)))),
                                  DataCell(Container(width:70,child:Text(e['time'].toString(),style: TextStyle(fontSize: 12),textAlign: TextAlign.center))),
                                  DataCell(Container(width:80,child:Text(e['sys'].toString(),style: TextStyle(fontSize: 12),textAlign: TextAlign.center))),
                                  DataCell(Container(width:80,child:Text(e['dia'].toString(),style: TextStyle(fontSize: 12),textAlign: TextAlign.center))),
                                  DataCell(Container(width:70,child:Text(e['mean'].toString(),style: TextStyle(fontSize: 12),textAlign: TextAlign.center))),
                                  DataCell(Container(width:80,child:Text(e['pr'].toString(),style: TextStyle(fontSize: 12),textAlign: TextAlign.center))),
                                ],
                              ),).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [Text('Total Results: '+Current_ItemList.length.toString(),style: TextStyle(fontSize: 12),textAlign: TextAlign.center)]
                  )
                ],
              ),
            ]
        ),
      ),
    );
  }
}
