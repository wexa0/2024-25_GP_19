import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gphomepage/main.dart';
import 'package:gphomepage/models/catModel.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';


class calendarpage extends StatelessWidget {
   calendarpage({super.key});
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
        SizedBox(height:7)  , 
      ],
      
     ),
      
   bottomNavigationBar: GNav(
    tabs: const [
        GButton(icon: Icons.sms, text:'Chatbot'),
        GButton(icon: Icons.calendar_today, text:'Calendar'),
        GButton(icon: Icons.home, text: 'Home',),
         GButton(icon: Icons.person, text:'Profile'),
        GButton(icon: Icons.poll, text:'Progress'),



    ],
   ),

    );
  }
  
Container calendar(){
 return Container(
        child: TableCalendar(
          
  firstDay: DateTime.utc(2010, 10, 16),
  lastDay: DateTime.utc(2030, 3, 14),
  focusedDay: DateTime.now(),
     calendarStyle: CalendarStyle(
   defaultTextStyle:TextStyle(color: const Color.fromARGB(255, 111, 151, 191)),
   weekNumberTextStyle:TextStyle(color: const Color.fromARGB(255, 111, 151, 191)),
   weekendTextStyle:TextStyle(color: const Color.fromARGB(255, 111, 151, 191)),
   todayDecoration: BoxDecoration(color: const Color.fromARGB(255, 100, 86, 113), borderRadius: BorderRadius.circular(30))

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
      title: Text(
        'Calendar',
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
        margin: EdgeInsets.all(10),
        alignment: Alignment.center,
        child: Image.asset('assets/icons/left-arrow.png',
        height: 20,
        width: 20,),
        decoration: BoxDecoration(
          color: Color(0xffF7F8F8),
          borderRadius: BorderRadius.circular(10)

        ),
      ),),
      actions: [
        GestureDetector(
          onTap: (){

          },
          child: Container(
        margin: EdgeInsets.all(10),
        alignment: Alignment.center,
        width: 37,
        child: Image.asset('assets/icons/dots.png',
        height: 20,
        width: 20,),
        decoration: BoxDecoration(
          color: Color(0xffF7F8F8),
          borderRadius: BorderRadius.circular(10)

        ),
      ),
      ) ],

     );

}

  void setState(String? item) {
     this.selectedItem = item;
  }
}