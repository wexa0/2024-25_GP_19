import 'package:flutter/material.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/welcome_page.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/Classes/User';
import 'guest_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: ProfilePage()));
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUser user = AppUser(); // Instance of AppUser
  bool isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkUserEmail(); // Check if the user has an email
  }

  void _checkUserEmail() async {
    await user.loadUserData();
    if (user.email == null || user.email!.isEmpty) {
      // Redirect to guest profile page if no email is found
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GuestProfilePage()),
      );
    } else {
      setState(() {
        isLoading = false; // Proceed if email exists
      });
    }
  }

Future<void> signOut() async {
  await FirebaseAuth.instance.signOut(); // تسجيل الخروج من Firebase
  setState(() {
    user = AppUser(); // إعادة تعيين بيانات المستخدم لتصبح فارغة
  });
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const WelcomePage()), // توجيه المستخدم إلى صفحة الترحيب (بدلاً من ProfilePage)
  );
}

// Callback to reload data and refresh the interface
void _refreshUserData() {
  setState(() {}); // Trigger a rebuild with updated data
}

  @override
  Widget build(BuildContext context) {
    var selectedIndex = 4 ;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 226, 231, 234),
        elevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor:  Color(0xFFF5F7F8),
      body: SafeArea(
        child: isLoading
             ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    //loading 
                    children: [
                      Image.asset(
                        'assets/images/logo.png', 
                        width: 170,
                        height: 170,
                      ),
                      const SizedBox(height: 0),
                      Lottie.asset(
                        'assets/animations/loading.json',
                        width: 150,
                        height: 150,
                      ),
                    ],
                  ),
                )
            : SingleChildScrollView(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color:  Color(0xFFF5F7F8),
                          padding: EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Profile Information',
                             style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Color(0xFF545454),
                ),
                            ),
                          ),
                        ),Padding(
                          padding: EdgeInsets.only(right:16, left: 16), 
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),  
                              topRight: Radius.circular(16), 
                            ),
                            child: Material(
                              color: Colors.white,
                              child: InkWell(
                                onTap: () => user.showEditDialog(context, 'name', _refreshUserData),
                                child: ListTile(
                                  title: Text('Name',          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
               color: Color(0xFF545454))),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                                              Divider(
                        color:Color(0xFF104A73),          // Set the color of the divider
                        thickness: 0.5,                // Set the thickness of the divider
                        indent: 30,                  // Set the indent on the left
                        endIndent: 30,               // Set the indent on the right
                         height: 0,   
                      ), Padding(
  padding: EdgeInsets.only(right:16, left: 16), 
  child:
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => user.showEditDialog(context, 'email', _refreshUserData),
                            child: ListTile(
                              title: Text('Email',          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
               color: Color(0xFF545454))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(user.email ?? 'Loading...'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        )),
                         Divider(
                        color:Color(0xFF104A73),          // Set the color of the divider
                        thickness: 0.5,                // Set the thickness of the divider
                        indent: 30,                  // Set the indent on the left
                        endIndent: 30,               // Set the indent on the right
                         height: 0,   
                      ), Padding(
  padding: EdgeInsets.only(right:16, left: 16), 
  child:
                        Material(
                          color: Colors.white,
                          child: InkWell(
                                onTap: () => user.showEditDialog(context, 'dateOfBirth', _refreshUserData),
                            child: ListTile(
                              title: Text('Date of Birth' ,   style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
               color: Color(0xFF545454))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(user.dateOfBirth ?? 'Loading...'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        )),
                         Divider(
                        color:Color(0xFF104A73),          // Set the color of the divider
                        thickness: 0.5,                // Set the thickness of the divider
                        indent: 30,                  // Set the indent on the left
                        endIndent: 30,               // Set the indent on the right
                         height: 0,   
                      ), Padding(
  padding: EdgeInsets.only(right:16, left: 16), 
  child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),  
                              bottomRight: Radius.circular(16), 
                            ),
                            child:
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => user.showChangePasswordDialog(context),
                            child: ListTile(
                              title: Text('Change Password', 
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
               color: Color(0xFF545454))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('••••••••'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ))),
                        Container(
                          width: double.infinity,
                          color:   Color(0xFFF5F7F8),
                          padding: EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Others',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                 color: Color(0xFF545454)
                              ),
                            ),
                          ),
                        ),
                        Padding( padding: EdgeInsets.only(right:16, left: 16), 
                          child:
                         ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),  
                              topRight: Radius.circular(16),
                               bottomLeft: Radius.circular(16),  
                              bottomRight: Radius.circular(16), 
                            ),
                            child:
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'AttentionLens@gmail.com',
                                query: 'subject=Contact%20AttentionLens',
                              );
                              launch(emailLaunchUri.toString());
                            },
                            child: ListTile(
                              title: Text('Contact us',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
               color: Color(0xFF545454)),),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Send us an email'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                         ) )),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () => user.logout(context), // استدعاء دالة تسجيل الخروج
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromRGBO(199, 217, 225, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(
                                  MediaQuery.of(context).size.width * 0.9, 52),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.logout,
                                    color: Color.fromRGBO(54, 54, 54, 1)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        color: Color.fromRGBO(54, 54, 54, 1),
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                       SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () => user.delete(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromRGBO(121, 163, 183, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(
                                  MediaQuery.of(context).size.width * 0.9, 52),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.close,
                                    color: Color.fromRGBO(54, 54, 54, 1)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Delete Account',
                                      style: TextStyle(
                                        color: Color.fromRGBO(54, 54, 54, 1),
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
        bottomNavigationBar: CustomNavigationBar(
        selectedIndex: selectedIndex,
  onTabChange: (index) {
    setState(() {
      selectedIndex = index;
    });
  },
      ),
    );
  }
}