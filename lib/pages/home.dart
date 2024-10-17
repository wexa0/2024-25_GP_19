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
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold
          ),),
          backgroundColor: Colors.white,
          elevation: 0.0,
      centerTitle: true,
      leading:  GestureDetector(
          onTap: (){
            
          },
      child: Container(
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
}