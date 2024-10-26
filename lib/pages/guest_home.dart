import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application/models/GuestBottomNavigationBar.dart';
import 'package:flutter_application/pages/addTaskForm.dart';
import 'package:flutter_application/welcome_page.dart';
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
  runApp(GuestHomePage());
}
class GuestHomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<GuestHomePage> {
  String? imageUrl; //iamge url
  User? _user = FirebaseAuth.instance.currentUser; // get current user
  String? fName; // first name to print
  String? lName; //last name to print
  int _currentIndex = 0; // Current index for carousel
  int _navcurrentIndex = 0; //current index of navigation bar
  var now = DateTime.now(); //current date
 var formatter =DateFormat.yMMMMd('en_US'); //format date as specified
  final List<String> imgList = [
    'assets/images/signUpForFeatures.png',
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
      
        SizedBox(height:36)  , 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Table(
                    children: [
                TableRow(
                  children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left:25),
                 child: Text("Welcome to,",
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
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),)
           )
          
          ,Padding(
            padding: const EdgeInsets.only(left:0, top:2),
           child: Text("AttentionLens!",
            style: TextStyle(
              color: Colors.black, 
              fontSize: 29,
              fontWeight: FontWeight.w700,
            ),)
           )
          
          ,
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
      ]),   SizedBox(height:18)  , 

          Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: _currentIndex == 1,
                    autoPlayInterval: Duration(milliseconds: 10500),
                    enlargeCenterPage: true,
                    aspectRatio: 16/ 8.5,
                    viewportFraction: 0.9,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index; // Update current index
                      });
                    },
                  ),
                  items:  imgList.asMap().entries.map((entry) {
    int index = entry.key;
    String item = entry.value;

    // Wrap the first image with GestureDetector
    return GestureDetector(
      onTap: () {
        if (index == 0) {
           Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomePage()));
        }
      },
      child: Container(
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
      ),
    );
  }).toList(),
),
                // Indicator on top of the image
                Positioned(
                  bottom: 10, // Position it at the bottom of the image
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
              
              ],
            ),
            
          ],
        ),

                        
                                ),)
                              ), 
                              Padding(
                                
                                padding: const EdgeInsets.only(left: 6, top:10, right:17),
                                child: GestureDetector(
                onTap: () {
                  /////////////////////////////////// Add Task Page ////////////////////////////////
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
              
              ],
            ),
            
          ],
        ),

                        
                                ),)
                              )
                            ],
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
        ),

                        
                                ),)
                              ),  Padding(
                                
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
            
            )
            ,  bottomNavigationBar: const GuestCustomBottomNavigationBar(),
          ) ;
        }
  




AppBar appBar() {
return AppBar(
      title: Text(
        'Home',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold
          ),),
          backgroundColor: const Color.fromARGB(255, 226, 231, 234),
          elevation: 0.0,
      centerTitle: true,
      leading:  GestureDetector(
          onTap: (){
            
          },
      child: Container(
         margin: EdgeInsets.only( left:6 ),
        alignment: Alignment.center,
        child:
          Image.asset('assets/logo/profilePIC.png',
          // $imageUrl
        height: 45,
        width: 45,),
        decoration: BoxDecoration(
          color: Color.fromARGB(83, 255, 255, 255),
          borderRadius: BorderRadius.circular(100)

        ),
      ),),
     

     );
}



}

