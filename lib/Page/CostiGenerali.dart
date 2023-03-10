import 'package:car_control/Widgets/Tile.dart';
import 'package:car_control/models/recapCosti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:d_chart/d_chart.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CostiGenerali extends StatefulWidget{

  @override
  CostiGeneraliState createState() => CostiGeneraliState();
}

class CostiGeneraliState extends State<CostiGenerali>{

  //String uid = FirebaseAuth.instance.currentUser!.uid;

  static List months =
  ['gen', 'feb', 'mar', 'apr', 'mag','giu','lug','ago','set','ott','nov','dic'];

  static var now = DateTime.now();
  //var current_month = now.month;

  String? month = months[now.month - 1]; //Il mese iniziale di visualizzazione dei recap è quello corrente
  String? year = now.year.toString(); //L'anno iniziale di visualizzazione dei recap è quello corrente
  String? fullNameMonth;
  String? checkFuel;


  readCheckFuel() async {
    await SharedPreferences.getInstance().then((value) { checkFuel = value.getString('checkFuel');});
  }


  @override
  final streamChart = FirebaseFirestore.instance.collection('CostiGenerali')
      .doc('2023').collection(FirebaseAuth.instance.currentUser!.uid).orderBy('index', descending: false)
      .snapshots(includeMetadataChanges: true);

  Stream<List<RecapCosti>> readRecapRifornimenti() =>
      FirebaseFirestore.instance
          .collection('CostiTotali')
          .doc('$year')
          .collection(FirebaseAuth.instance.currentUser!.uid)
          .where('mese', isEqualTo: month)
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => RecapCosti.fromJson(doc.data())).toList()
      );

  Stream<List<RecapCosti>> readRecapManutenzioni() =>
      FirebaseFirestore.instance
          .collection('CostiTotaliManutenzione')
          .doc('$year')
          .collection(FirebaseAuth.instance.currentUser!.uid)
          .where('mese', isEqualTo: month)
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => RecapCosti.fromJson(doc.data())).toList()
      );

  Stream<List<RecapCosti>> readRecapScadenze() =>
      FirebaseFirestore.instance
          .collection('CostiTotaliScadenze')
          .doc('$year')
          .collection(FirebaseAuth.instance.currentUser!.uid)
          .where('mese', isEqualTo: month)
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => RecapCosti.fromJson(doc.data())).toList()
      );

  ActivityListTile buildCardRecapRifornimenti(RecapCosti recapCosti) => ActivityListTile(
      title: 'Recap rifornimenti',
      subtitle:'Totale spese: ${recapCosti.rifornimento} €',
      subtitle2: checkFuel == 'Elettrica' ? 'Totale Kw/h: ${recapCosti.litri}' : 'Totale litri: ${recapCosti.litri}',
      trailingImage:
      Image.asset('images/CarFuelImage.png', height: 110),
      color: Colors.white,
      onTab: () {}
  );

  ActivityListTile buildCardRecapManutenzioni(RecapCosti recapCosti) => ActivityListTile(
      title: 'Recap manutenzioni',
      subtitle: 'Totale spese: ${recapCosti.manutenzione}  €',
      subtitle2: '',
      trailingImage:
      Image.asset('images/ImageManutenzione2.png', height: 110),
      color: Colors.white,
      onTab: () {}
  );

  ActivityListTile buildCardRecapScadenze(RecapCosti recapCosti) => ActivityListTile(
      title: 'Recap scadenze',
      subtitle: 'Totale spese: ${recapCosti.costoScadenze}  €',
      subtitle2: '',
      trailingImage:
      Image.asset('images/RecapScadenze.png', height: 110),
      color: Colors.white,
      onTab: () {}
  );

  Widget build(BuildContext context) {
    readCheckFuel();
    return Scaffold(
      body:
      Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF90CAF9), Colors.white],
            )
        ),

        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 200, horizontal: 10),
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              decoration: BoxDecoration(
                  //border: Border.all(color: Colors.blueAccent),
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                  ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey,
                    blurRadius: 2.0,
                    spreadRadius: 0.0,
                    offset: Offset(2.0, 2.0), // shadow direction: bottom right
                  )
                ],
              ),
              child: StreamBuilder(
                  stream: streamChart,
                  builder: (context, AsyncSnapshot<
                      QuerySnapshot<Map<String, dynamic>>> snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }
                    if (snapshot.data == null) {
                      //return const Text("Empty");
                      return Center(child: CircularProgressIndicator());
                    }
                    List<Map<String, dynamic>> listChart = snapshot.data!.docs
                        .map((e) {
                      return {
                        'domain': e.data()['mese'],
                        'measure': e.data()['costo'],
                      };
                    }).toList();
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DChartBar(
                        data: [
                          {
                            'id': 'Bar',
                            'data': listChart,
                          },
                        ],
                        axisLineColor: Colors.lightBlue,
                        barColor: (barData, index, id) => Colors.lightBlue,
                        showBarValue: true,
                      ),
                    );
                  }
              ),
            ),
            Container(
                margin: const EdgeInsets.symmetric(vertical: 22.0,horizontal: 25.0),
                alignment: Alignment.center,
                child:
                TextButton.icon(
                  icon: Icon(Icons.filter_alt_outlined, color: Colors.white,),
                  label: (month != null && year != null && fullNameMonth == null) ? Text('Filtra per mese ed anno', style: TextStyle(color: Colors.white),) : Text('$fullNameMonth \t $year', style: TextStyle(color: Colors.white),),
                  style: TextButton.styleFrom(
                    elevation: 10.0,
                    backgroundColor: Colors.lightBlue.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    DatePicker.showPicker(context, showTitleActions: true,
                        onChanged: (date) {
                        }, onConfirm: (date) {
                          int selectedMonth = date.month;
                          month = months[selectedMonth - 1];
                          setState(() {
                            month = months[selectedMonth - 1];
                            year = date.year.toString();
                            fullNameMonth = generateFullNameMonth(month);
                            //print(month);
                          });
                        },
                        onCancel: (){
                          /*setState(() {
                            month = null;
                            year = null;
                          });*/
                        },
                        pickerModel: CustomMonthPicker(
                            currentTime: DateTime.now(),
                            minTime: DateTime(2022,1),
                            maxTime: DateTime(2023,12),
                            locale: LocaleType.it),
                        locale: LocaleType.it);
                  },
                )
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
              child:
                  Column(
                  children: [
                    //Rifornimenti
                  StreamBuilder<List<RecapCosti>> (
                  stream: readRecapRifornimenti(),
                  builder: (context,snapshot) {
                    if (snapshot.hasData) {
                      final recap = snapshot.data!;
                      if(recap.isNotEmpty) {
                        return Column(
                            //padding: EdgeInsets.symmetric(vertical: 0),
                            //shrinkWrap: true,
                            children: recap.map(buildCardRecapRifornimenti).toList()
                        );
                      }
                      else {
                        return Column(
                            children: [
                              ActivityListTile(
                                  title: 'Recap rifornimenti',
                                  subtitle: 'Totale spese:  €',
                                  subtitle2: checkFuel == 'Elettrica' ? 'Totale Kw/h: ' : 'Totale litri: ',
                                  trailingImage:
                                  Image.asset('images/CarFuelImage.png', height: 110),
                                  color: Colors.white,
                                  onTab: () {
                                  }
                              ),

                            ]
                        );
                      }
                    }
                    else {
                      //return Center(child: CircularProgressIndicator());
                      return Column(
                          children: [
                            ActivityListTile(
                                title: 'Recap rifornimenti',
                                subtitle: 'Totale spese:  €',
                                subtitle2: checkFuel == 'Elettrica' ? 'Totale Kw/h: ' : 'Totale litri: ',
                                trailingImage:
                                Image.asset('images/CarFuelImage.png', height: 110),
                                color: Colors.white,
                                onTab: () {
                                }
                            ),

                          ]
                      ); 
                    }
                  }
                  ),
                    //Manutenzioni
                  StreamBuilder<List<RecapCosti>> (
                        stream: readRecapManutenzioni(),
                        builder: (context,snapshot) {
                          if (snapshot.hasData) {
                            final recap = snapshot.data!;
                            if(recap.isNotEmpty) {
                              return Column(
                                  //padding: EdgeInsets.symmetric(vertical: 0),
                                  //shrinkWrap: true,
                                  children: recap.map(buildCardRecapManutenzioni).toList()
                              );
                            }
                            else {
                              return Column(
                                  children: [
                                    ActivityListTile(
                                        title: 'Recap manutenzioni',
                                        subtitle: 'Totale spese:  €',
                                        subtitle2: '',
                                        trailingImage:
                                        Image.asset('images/ImageManutenzione2.png', height: 110),
                                        color: Colors.white,
                                        onTab: () {}
                                    ),
                                  ]
                              );
                            }
                          }
                          else {
                            //return Center(child: CircularProgressIndicator());
                            return Column(
                                children: [
                                  ActivityListTile(
                                      title: 'Recap manutenzioni',
                                      subtitle: 'Totale spese:  €',
                                      subtitle2: '',
                                      trailingImage:
                                      Image.asset('images/ImageManutenzione2.png', height: 110),
                                      color: Colors.white,
                                      onTab: () {}
                                  ),
                                ]
                            );
                          }
                        }
                    ),
                    //Scadenze
                  StreamBuilder<List<RecapCosti>> (
                        stream: readRecapScadenze(),
                        builder: (context,snapshot) {
                          if (snapshot.hasData) {
                            final recap = snapshot.data!;
                            if(recap.isNotEmpty) {
                              return Column(
                                  //padding: EdgeInsets.symmetric(vertical: 0),
                                  //shrinkWrap: true,
                                  children: recap.map(buildCardRecapScadenze).toList()
                              );
                            }
                            else {
                              return Column(
                                  children: [
                                    ActivityListTile(
                                        title: 'Recap Scadenze',
                                        subtitle: 'Totale spese:  €',
                                        subtitle2: '',
                                        trailingImage:
                                        Image.asset('images/RecapScadenze.png', height: 110),
                                        color: Colors.white,
                                        onTab: () {}
                                    ),
                                  ]
                              );
                            }
                          }
                          else {
                            //return Center(child: CircularProgressIndicator());
                            return Column(
                                children: [
                                  ActivityListTile(
                                      title: 'Recap Scadenze',
                                      subtitle: 'Totale spese:  €',
                                      subtitle2: '',
                                      trailingImage:
                                      Image.asset('images/RecapScadenze.png', height: 110),
                                      color: Colors.white,
                                      onTab: () {}
                                  ),
                                ]
                            );
                          }
                        }
                    ),

              ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  String? generateFullNameMonth(String? month) {

    if(month == 'gen'){
      return 'Gennaio';
    }
    if(month == 'feb'){
      return 'Febbraio';
    }
    if(month == 'mar'){
      return 'Marzo';
    }
    if(month == 'apr'){
      return 'Aprile';
    }
    if(month == 'mag'){
      return 'Maggio';
    }
    if(month == 'giu'){
      return 'Giugno';
    }
    if(month == 'lug'){
      return 'Luglio';
    }
    if(month == 'ago'){
      return 'Agosto';
    }
    if(month == 'set'){
      return 'Settembre';
    }
    if(month == 'ott'){
      return 'Ottobre';
    }
    if(month == 'nov'){
      return 'Novembre';
    }
    if(month == 'dic'){
      return 'Dicembre';
    }
    return null;

  }
}

class CustomMonthPicker extends DatePickerModel {
  CustomMonthPicker({required DateTime currentTime, required DateTime minTime, required DateTime maxTime,
    required LocaleType locale}) : super(locale: locale, minTime: minTime, maxTime:
  maxTime, currentTime: currentTime);

  @override
  List<int> layoutProportions() {
    return [1, 1, 0];
  }
}