<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_application/main.dart';

import 'package:flutter_application/models/catModel.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomePage extends StatelessWidget {
   HomePage({super.key});
   List<catModel> category=[];
List<String> drop=['TimeLine','Category','Urgency'];
String? selectedItem='TimeLine';
   void _getcat(){
     category =  catModel.getCat();

   }

  // @override
  // void initState() {

  // }
  @override
  Widget build(BuildContext context) {
    _getcat();
    return Scaffold(
    resizeToAvoidBottomInset: false,
     appBar: appBar(),
     backgroundColor: Colors.white,
     body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
     calendar(),
      //  Container(
      //   width:40,
      //       padding: const EdgeInsets.only(left:20,bottom:300),
      //      child: Text("Tasks",
      //       style: TextStyle(
      //         color: Colors.black,
      //         fontSize: 18,
      //         fontWeight: FontWeight.w800,
      //       ),),),
        // SizedBox(height:7)  , 
     SizedBox(height: 1, child: Container(
     decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(114, 220, 213, 213)
                  ),)
   ),
   const SizedBox(height:12)  , 
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
               children: [
           TableRow(
            children: <Widget>[
           const Padding(
            padding: EdgeInsets.only(left:20),
           child: Text("Tasks",
            style: TextStyle(
              color: Colors.black, 
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),)
           ), Container(
            margin: const EdgeInsets.only(left:110,right:40),
            child: DropdownButton<String>(
              value: selectedItem,
              items: drop
              .map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, style:const TextStyle(fontSize:12)),
            )
          ).toList(),
          onChanged: (item){
            setState(item!);
            
             } ,
             isExpanded: false,
          )
            ,
            
            )
          //  Padding(
          //   padding: const EdgeInsets.only(left:110),
          //  child: Text("Tasks",
          //   style: TextStyle(
          //     color: Colors.black,
          //     fontSize: 18,
          //     fontWeight: FontWeight.w800,
          //   ),)
          //  )
          ,])]),
          //  SizedBox(height:15,),
      
          Table(
            columnWidths: const {0: const FractionColumnWidth(0.23),1: const FractionColumnWidth(0.77)},
            children: [
           TableRow(
                children: [
                  Table(
                    children:[
                        TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 10,
          width: 10,
          margin: const EdgeInsets.only(left: 12, bottom:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(255, 229, 147, 153)
                  ), 
          child: Text(" "),
                  ),
                  Container(
                    height: 15,
          width: 60,
          margin: const EdgeInsets.only(left: 8,bottom: 0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(0, 229, 147, 153)
                  ),
                    child: Text("9:00 am", style: TextStyle(fontSize: 12.2),),),
                  Container( 
          height: 18,
          width: 18,
          margin: const EdgeInsets.only(left:0 , bottom:0),
          decoration: BoxDecoration(
            border: Border.all(
      width: 2,
      color: const Color.fromARGB(255, 200, 97, 104)
    ),
                   borderRadius: const BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: const Color.fromARGB(255, 255, 255, 255)
                  ), 
          child: Text(" "),
                  ),
        Container(),

      ],),
      ],),
                      TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 80,
          width: 2.5,
          margin: const EdgeInsets.only(left: 16,top:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(255, 229, 147, 153)
                  ), 
          child: Text(" "),
                  ),
        Container(),

      ],),
      ],),
       TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 10,
          width: 10,
          margin: const EdgeInsets.only(left: 12, bottom:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(255, 194, 213, 245)
                  ), 
          child: Text(" "),
                  ),
                  Container(
                    height: 15,
          width: 60,
          margin: const EdgeInsets.only(left: 8,bottom: 0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(0, 194, 213, 245)
                  ),
                    child: Text("10:00 am", style: TextStyle(fontSize: 12.2),),),
                  Container( 
          height: 18,
          width: 18,
          margin: const EdgeInsets.only(left:0 , bottom:0, top:8),
          decoration: BoxDecoration(
            border: Border.all(
      width: 2,
      color: const Color.fromARGB(255, 103, 131, 178)
    ),
                   borderRadius: const BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: const Color.fromARGB(255, 255, 255, 255)
                  ), 
          child: Text(" "),
                  ),
        Container(),

      ],),
      ],),
       TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 80,
          width: 2.5,
          margin: const EdgeInsets.only(left: 16,top:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(255,194, 213, 245)
                  ), 
          child: Text(" "),
                  ),
        Container(),

      ],),
      ],),

      TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 10,
          width: 10,
          margin: const EdgeInsets.only(left: 12, bottom:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(255, 194, 213, 245)
                  ), 
          child: Text(" "),
                  ),
                  Container(
                    height: 15,
          width: 60,
          margin: const EdgeInsets.only(left: 8,bottom: 0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(0, 194, 213, 245)
                  ),
                    child: Text("11:00 am", style: TextStyle(fontSize: 12.2),),),
        Container(),

      ],),
      ],),
      TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 55,
          width: 2.5,
          margin: const EdgeInsets.only(left: 16,top:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(171, 209, 211, 204)
                  ), 
          child: Text(" "),
                  ),
        Container(),

      ],),
      ],),

       TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 10,
          width: 10,
          margin: const EdgeInsets.only(left: 12, bottom:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(171, 209, 211, 204)
                  ), 
          child: Text(" "),
                  ),
                  Container(
                    height: 15,
          width: 55,
          margin: const EdgeInsets.only(left: 8,bottom: 0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(0, 194, 213, 245)
                  ),
                    child: Text("12:00 pm", style: TextStyle(fontSize: 12.2, color: Color.fromARGB(230, 209, 211, 204)),),),
        Container(),

      ],),
      ],),

       TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 50,
          width: 2.5,
          margin: const EdgeInsets.only(left: 16,top:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(171, 209, 211, 204)
                  ), 
          child: Text(" "),
                  ),
        Container(),

      ],),
      ],),

       TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 10,
          width: 10,
          margin: const EdgeInsets.only(left: 12, bottom:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(255, 247, 229, 193)
                  ), 
          child: Text(" "),
                  ),
                  Container(
                    height: 15,
          width: 60,
          margin: const EdgeInsets.only(left: 8,bottom: 0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(0, 194, 213, 245)
                  ),
                    child: Text("1:00 pm", style: TextStyle(fontSize: 12.2),),),
                    Container( 
          height: 18,
          width: 18,
          margin: const EdgeInsets.only(left:0 , bottom:0),
          decoration: BoxDecoration(
            border: Border.all(
      width: 2,
      color: const Color.fromARGB(255, 169, 149, 108)
    ),
                   borderRadius: const BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: const Color.fromARGB(255, 255, 255, 255)
                  ), 
          child: Text(" "),
                  ),
        Container(),

      ],),
      ],),

      TableRow(
children: <Widget>[
  Row(   children: <Widget>[     Container( 
          height: 40,
          width: 2.5,
          margin: const EdgeInsets.only(left: 16,top:0),
          decoration: const BoxDecoration(
                   borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
                                                  topRight:Radius.circular(20),
                                                  bottomRight:Radius.circular(20),
                                                  bottomLeft:Radius.circular(20)),
                    color: Color.fromARGB(255, 247, 229, 193)
                  ), 
          child: Text(" "),
                  ),
        Container(),

      ],),
      ],),

//       TableRow(
// children: <Widget>[
//   Row(   children: <Widget>[     Container( 
//           child: Text(" "),
//           height: 10,
//           width: 10,
//           margin: EdgeInsets.only(left: 12, bottom:0),
//           decoration: BoxDecoration(
//                    borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
//                                                   topRight:Radius.circular(20),
//                                                   bottomRight:Radius.circular(20),
//                                                   bottomLeft:Radius.circular(20)),
//                     color: Color.fromARGB(255, 247, 229, 193)
//                   ),
//                   ),
//                   Container(
//                     child: Text("12:00 pm", style: TextStyle(fontSize: 12.2),),
//           height: 15,
//           width: 60,
//           margin: EdgeInsets.only(left: 8,bottom: 0),
//           decoration: BoxDecoration(
//                    borderRadius: BorderRadius.only(topLeft:Radius.circular(20),
//                                                   topRight:Radius.circular(20),
//                                                   bottomRight:Radius.circular(20),
//                                                   bottomLeft:Radius.circular(20)),
//                     color: Color.fromARGB(0, 194, 213, 245)
//                   ),),
//         Container(),

//       ],),
//       ],),
      ]),
                      Column(
            children: [
           SizedBox(
            height: 399,
            child: ListView.builder(
              itemCount: category.length,
              itemBuilder: (context, index){
                return Container(
                  height: 90,
                  width: 130,
                  margin:const EdgeInsets.only(left:15, right:10, top:10, bottom: 10) ,
                   decoration: BoxDecoration(
                   borderRadius: const BorderRadius.only(topLeft:Radius.circular(0),
                                                  topRight:Radius.circular(15),
                                                  bottomRight:Radius.circular(15),
                                                  bottomLeft:Radius.circular(15)),
                    color: category[index].boxColor
                  ),
                  
                  child: Column(
                    children: [
    
                      SizedBox(
                        
                        width: 600,
                        child: Padding(
                          padding: const EdgeInsets.only( left:10.0, top:8.8 ),
                          child:   Text( category[index].name,
                   style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 16
                   ),
                   
                  ),
                          ),
                          

                      ), 
                      SizedBox (
                        width:600,
                        child: Padding(
                          padding: const EdgeInsets.only( left:15.0, top:1.5 ),
                          child:   Text( category[index].time,
                   style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Color.fromARGB(255, 81, 81, 81),
                    fontSize: 14.6
                   ),
                   
                  ),
                          ),),
//                           Container (
//                        child:LayoutBuilder(builder: (context, constraints) { 
//         if(category[index].time=="" ){
//             return Text("");
//         }else{
//             return Row(
//   children: <Widget>[
//     Container(
//       margin:EdgeInsets.only(left:300) ,
//       child: Image.asset('assets/icons/bin.png',
//         height: 15,
//         width: 15,
//         ),
//     ),
//     Container(
// margin:EdgeInsets.only(left:3) ,
//       child: Image.asset('assets/icons/edit-text.png',
//         height: 15,
//         width: 15,
//         ),    ),
   
//   ],
// );
//         }  
//     }),),
                     
                 ],
                 ),
                 
                );    
              },
              ),
              
            ),
            ],
          ),

               
                ]),

            ],
          ),
           
          ],
        ),
        
      ],
     ),
    
   bottomNavigationBar: const GNav(
    tabs: [
              GButton(icon: Icons.home, text:'Home'),
        GButton(icon: Icons.sms, text:'Chatbot'),
        GButton(icon: Icons.calendar_today, text:'Calendar'),
         GButton(icon: Icons.person, text:'Profile'),
        GButton(icon: Icons.poll, text:'Progress'),



    ],
   ),
    );
  }
  
Container calendar(){
 return Container(
        child: TableCalendar(
          calendarFormat: CalendarFormat.week,
  firstDay: DateTime.utc(2010, 10, 16),
  lastDay: DateTime.utc(2030, 3, 14),
  focusedDay: DateTime.now(),
     calendarStyle: CalendarStyle(
   defaultTextStyle:const TextStyle(color: Color.fromARGB(255, 178, 183, 188)),
   weekNumberTextStyle:const TextStyle(color: Color.fromARGB(255, 197, 189, 189)),
   weekendTextStyle:const TextStyle(color: Color.fromARGB(255, 193, 184, 187)),
   todayDecoration: BoxDecoration(color: const Color.fromARGB(255, 226, 226, 226), borderRadius: BorderRadius.circular(30))

 ),
),
      );

}

  Widget content(){
   return Column(
    children: [
      Container(
        
      ),
    ],
   );

  }
  

AppBar appBar() {
return AppBar(
      title: const Text(
        'Today\'s task',
=======
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/pages/addTaskForm.dart';
import 'package:flutter_svg/svg.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(HomePage());
}
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  String? imageUrl; //iamge url
  User? _user = FirebaseAuth.instance.currentUser; // get current user
  String? fName; // first name to print
  String? lName; //last name to print
  int _currentIndex = 0; // Current index for carousel
  int _navcurrentIndex = 0; //current index of navigation bar
  var now = DateTime.now(); //current date
  var formatter =DateFormat.yMMMMd('en_US'); //format date as specified
  
  final List<String> imgList = [
    'assets/images/mainCrousel.png',
    'assets/images/managaTasksCrousel.png',
    'assets/images/setRemindersCrousel.png',
    'assets/images/chatCrousel.png',

  ]; //carousel list


  @override
  Widget build(BuildContext context) {
    return Scaffold(
    resizeToAvoidBottomInset: false,
     appBar: appBar(),
     backgroundColor: const Color.fromARGB(255, 245, 247, 248),
     body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        SizedBox(height:30), 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Table(
                  children: [
                     TableRow(
                      children: <Widget>[
                        Padding(
                        padding: const EdgeInsets.only(left:25),
                        child: Text("Hello,",
                        style: TextStyle(
                          color: Colors.black, 
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                        ),)
                        ),
                      ]),


                      TableRow(
                        children: <Widget>[
                         Row(   children: <Widget>[     Padding(
                        padding: const EdgeInsets.only(left:25, top:8),
                        child: Text("",
                        style: TextStyle(
                          color: Colors.black, 
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),)
                      ),
                      Expanded(
                      child: FutureBuilder(
                       future: _fetch(),
                       builder:(context, snapshot){
                        //onyl run(load) once 
                        if (snapshot.connectionState != ConnectionState.done && fName== null)
                          return Text("Loading data ... Please wait");

                        return Text ("$fName $lName",
                        style: TextStyle(
                          color: Colors.black, 
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                        ),);
                      },) ),
            ],),
                ]), 

                      TableRow(
                        children: <Widget>[
                        Padding(
                        padding: const EdgeInsets.only(left:25),
                        child: Text(formatter.format(now),
                        style: TextStyle(
                          color: const Color.fromARGB(255, 144, 147, 147), 
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),)
                      ),
                        ]),
            ]), 
              SizedBox(height:15)  , 
              Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          // autoPlay: _currentIndex == 1,
                          // autoPlayInterval: Duration(milliseconds: 10500),
                          enlargeCenterPage: true,
                          aspectRatio: 16.3/ 8.5,
                          viewportFraction: 0.9,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentIndex = index; // Update current index
                            });
                          },
                        ),
                        items: imgList.map((item) {
                          return Container(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(25, 203, 203, 203).withOpacity(0.9),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(item, fit: BoxFit.cover),
                            ),
                          );
                        }).toList(),
                      ),
                      // this is the indicator in top of image
                      Positioned(
                        bottom: 10, //make it at the bottom of image
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: imgList.asMap().entries.map((entry) {
                            int index = entry.key;
                            bool isSelected = _currentIndex == index;
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 3.0),
                              width: isSelected? 25: 8.0,
                              height: 4.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(2),
                                color: _currentIndex == index ? const Color.fromARGB(255, 238, 238, 238) : Colors.grey,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),] ), 
                  SizedBox(height:15),
                  Column(
                        children: [
                          Container(  
                            height: 240,
                            child: Table(
                              children: [
                                TableRow(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 17, top:10, right:6),
                                      child: GestureDetector(
                                      onTap: () {
                                        /////////////////////////////////// Today's Task Page ////////////////////////////////
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(builder: (context) => SecondPage()),
                                        // );
                                      },
                                        child:Container( 
                                        height: 110,
                                        width: 100,
                                        decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(95, 203, 203, 203).withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(10),
                                        color:  const Color.fromARGB(255, 255, 255, 255) ,
                                      ),


                          child: Table(
                          columnWidths: {0: FractionColumnWidth(0.3)},
                              children: [
                                TableRow(
                                  children: [
                                    Container(
                            margin: EdgeInsets.only(top: 3,left: 3), 
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/todayTask.png',
                                  height: 45,
                                  width: 45,
                                ),
                                
                              ],
                            ),
                          ),

                                Container(
                            margin: EdgeInsets.only(right: 40), 
                            child:Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  
                                  SizedBox(height: 30),
                                  Text("Today\'s Tasks",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                        color: Colors.black, 
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),), 
                                ],
                              ),)
                                  
                                 ], ),
                                
                              ], ),
                                ),) ), 

                              Padding(
                                padding: const EdgeInsets.only(left: 6, top:10, right:17),
                                child: GestureDetector(
                                onTap: () {
                                  /////////////////////////////////// Add Task Page ////////////////////////////////
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => addTask()),
                                  );
                              },
                              child:Container( 
                                                
                                                height: 110,
                                                width: 100,
                                                decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color.fromARGB(95, 203, 203, 203).withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                        borderRadius: BorderRadius.circular(10),
                                        color:  const Color.fromARGB(255, 255, 255, 255) ,
                                      ),
                                      

      child: Table(
      columnWidths: {0: FractionColumnWidth(0.3)},
          children: [
            TableRow(
              children: [
                Container(
        margin: EdgeInsets.only(top: 3,left: 3), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/addTask.png',
              height: 45,
              width: 45,
            ),
            
          ],
        ),
      ),
            Container(
        margin: EdgeInsets.only(right: 40), 
        child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              SizedBox(height: 30), 
              Text("Add a Task",
              textAlign: TextAlign.center,
              style: TextStyle(
                    color: Colors.black, 
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),), 
            ],
          ),)      
              ], ), 
          ], ),        
                                ),)
                              ) ],
                          ),
                          

        TableRow(
                            children: <Widget>[
                              Padding(
                                
                                padding: const EdgeInsets.only(left: 17, top:10, right:6),
                                child:GestureDetector(
                                onTap: () {
                                  /////////////////////////////////// Progress Page ////////////////////////////////
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(builder: (context) => SecondPage()),
                                  // );
                                },
                                child: Container( 
                                                  
                                                  height: 110,
                                                  width: 100,
                                                  decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(95, 203, 203, 203).withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                          borderRadius: BorderRadius.circular(10),
                                          color:  const Color.fromARGB(255, 255, 255, 255) ,
                                        ),
                                        

      child: Table(
      columnWidths: {0: FractionColumnWidth(0.3)},
          children: [
            TableRow(
              children: [
                Container(
        margin: EdgeInsets.only(top: 3,left: 3), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/viewProgress.png',
              height: 45,
              width: 45,
            ),
            
          ],
        ),
      ),
            Container(
        margin: EdgeInsets.only(right: 30), 
        child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              SizedBox(height: 28),
              Text("View Progress",
              textAlign: TextAlign.center,
              style: TextStyle(
                    color: Colors.black, 
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),), 
            ],
          ),)
              
              ],
            ),
            
          ],
        ), ),
        ) ), 
         Padding(
           padding: const EdgeInsets.only(left: 6, top:10, right:17),
           child: GestureDetector(
           onTap: () {
                  /////////////////////////////////// Attena (chatbot) Page ////////////////////////////////
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => SecondPage()),
                  // );
                },
                child:Container( 
                       height: 110,
                       width: 100,
                       decoration: BoxDecoration(
                       boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(95, 203, 203, 203).withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 0),
                          ),
                        ],
                          borderRadius: BorderRadius.circular(10),
                          color:  const Color.fromARGB(255, 255, 255, 255) ,
                        ),
                        

      child: Table(
      columnWidths: {0: FractionColumnWidth(0.3)},
          children: [
            TableRow(
              children: [
                Container(
        margin: EdgeInsets.only(top: 3,left: 3), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/chatWithAttena.png',
              height: 45,
              width: 45,
            ),
            
          ],
        ),
      ),
            Container(
        margin: EdgeInsets.only(right: 24), 
        child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              SizedBox(height: 28),
              Text("Chat with Attena",
              textAlign: TextAlign.center,
              style: TextStyle(
                    color: Colors.black, 
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),), 
            ],
          ),)
              
              ],
            ),
            
          ],
        ),

                        
                                ),)
                              )
                            ],
                          ),

                          ]
                      ),
                    )
                  ],
            )] ,
            
            ),
            
         //navigation bar    
        bottomNavigationBar: const CustomBottomNavigationBar(),
          ) ;
        }
  



// method of header: app bar 
AppBar appBar() {
return AppBar(
      title: Text(
        'Home',
>>>>>>> 40c024b6aa0f3812a741458929487d182c99554a
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold
          ),),
<<<<<<< HEAD
          backgroundColor: Colors.white,
=======
          backgroundColor: const Color.fromARGB(255, 226, 231, 234),
>>>>>>> 40c024b6aa0f3812a741458929487d182c99554a
          elevation: 0.0,
      centerTitle: true,
      leading:  GestureDetector(
          onTap: (){
            
          },
      child: Container(
<<<<<<< HEAD
        margin: const EdgeInsets.all(10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xffF7F8F8),
          borderRadius: BorderRadius.circular(10)

        ),
        child: Image.asset('assets/icons/left-arrow.png',
        height: 20,
        width: 20,),
      ),),
      actions: [
        GestureDetector(
          onTap: (){

          },
          child: Container(
        margin: const EdgeInsets.all(10),
        alignment: Alignment.center,
        width: 37,
        decoration: BoxDecoration(
          color: const Color(0xffF7F8F8),
          borderRadius: BorderRadius.circular(10)

        ),
        child: Image.asset('assets/icons/dots.png',
        height: 20,
        width: 20,),
      ),
      ) ],

     );

}

  void setState(String? item) {
     selectedItem = item;
  }
=======
         margin: EdgeInsets.only( left:6 ),
        alignment: Alignment.center,
        child: FutureBuilder(
      future: _fetchImage(), // Call the method to fetch the image URL
      builder: (context, snapshot) {
        //onyl run(load) once 
        if ( imageUrl==null &&( snapshot.connectionState == ConnectionState.waiting)) {
          return CircularProgressIndicator(); // Show a loader while fetching
        } else if (snapshot.hasError) {
          return Image.network(
              'https://cdn.pixabay.com/photo/2017/03/02/19/18/mystery-man-973460_960_720.png'); // Fallback on error
        }

       // Check if the image URL is available
      if (imageUrl == null || imageUrl!.isEmpty) {
        return Image.network(
          'https://cdn.pixabay.com/photo/2017/03/02/19/18/mystery-man-973460_960_720.png', // Default online image
        );
      } else if (imageUrl!.startsWith('assets/')) {
        return Image.asset(imageUrl!); // Use the local asset image
      } else {
        return Image.network(imageUrl!); // Use the fetched image URL
      }
      },
    ),
    decoration: BoxDecoration(
      color: Color.fromARGB(83, 255, 255, 255),
      borderRadius: BorderRadius.circular(100),
    ),
      ),),
     

     );
}



// method to get fisrt and last name drom firebase
_fetch() async {
 final User? _user = FirebaseAuth.instance.currentUser;

  if (_user != null) {
    try {
      DocumentSnapshot ds = await FirebaseFirestore.instance
          .collection('User')
          .doc(_user.uid)
          .get();

      if (ds.exists) {
        // Safely access data
        var data = ds.data() as Map<String, dynamic>?; // Cast to Map
        if (data != null && data.containsKey('firstName')&& data.containsKey('lastName')) {
          fName = data['firstName'];
          lName = data['lastName'];
          
        } else {
          print('firstName and lastName field does not exist');
        }
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching data: $e'); 
    }
  } else {
    print('No user is logged in');
  }
}


// method to get profile picture from firbase
_fetchImage() async {
 final User? _user = FirebaseAuth.instance.currentUser;

  if (_user != null) {
    try {
      DocumentSnapshot ds = await FirebaseFirestore.instance
          .collection('User')
          .doc(_user.uid)
          .get();

      if (ds.exists) {
        // Safely access data
        var data = ds.data() as Map<String, dynamic>?; 
        if (data != null && data.containsKey('profilePhoto')) {
          imageUrl = data['profilePhoto'];
        } else {
          print('firstName field does not exist');
        }
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  } else {
    print('No user is logged in');
  }
}
// only run once
void _loadFnameLname() {
  if (fName == null && lName == null) {
    _fetch();
}
}

>>>>>>> 40c024b6aa0f3812a741458929487d182c99554a
}