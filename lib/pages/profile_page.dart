import 'package:flutter/material.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/pages/appBlocker_page';
import 'package:flutter_application/welcome_page.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/Classes/User';
import 'guest_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/services/notification_service.dart';


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
    await FirebaseAuth.instance.signOut();
    setState(() {
      user = AppUser();
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
    );
  }

// Callback to reload data and refresh the interface
  void _refreshUserData() {
    setState(() {}); // Trigger a rebuild with updated data
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: NotificationTimePicker(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var selectedIndex = 4;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
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
      backgroundColor: Color(0xFFF5F7F8),
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
                          color: Color(0xFFF5F7F8),
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
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 16, left: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Material(
                              color: Colors.white,
                              child: InkWell(
                                onTap: () => user.showEditDialog(
                                    context, 'name', _refreshUserData),
                                child: ListTile(
                                  title: Text('Name',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF545454))),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${user.name ?? ''} '.trim()),
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
                          color: Color.fromRGBO(16, 74, 115,
                              0.377), // Set the color of the divider
                          thickness: 0.5, // Set the thickness of the divider
                          indent: 30, // Set the indent on the left
                          endIndent: 30, // Set the indent on the right
                          height: 1,
                        ),
                        Padding(
                            padding: EdgeInsets.only(right: 16, left: 16),
                            child: Material(
                              color: Colors.white,
                              child: InkWell(
                                onTap: () => user.showEditDialog(
                                    context, 'email', _refreshUserData),
                                child: ListTile(
                                  title: Text('Email',
                                      style: TextStyle(
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
                          color: Color.fromRGBO(16, 74, 115,
                              0.377), // Set the color of the divider
                          thickness: 0.5, // Set the thickness of the divider
                          indent: 30, // Set the indent on the left
                          endIndent: 30, // Set the indent on the right
                          height: 0,
                        ),
                        Padding(
                            padding: EdgeInsets.only(right: 16, left: 16),
                            child: Material(
                              color: Colors.white,
                              child: InkWell(
                                onTap: () => user.showEditDialog(
                                    context, 'dateOfBirth', _refreshUserData),
                                child: ListTile(
                                  title: Text('Date of Birth',
                                      style: TextStyle(
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
                          color: Color.fromRGBO(16, 74, 115,
                              0.377), // Set the color of the divider
                          thickness: 0.5, // Set the thickness of the divider
                          indent: 30, // Set the indent on the left
                          endIndent: 30, // Set the indent on the right
                          height: 0,
                        ),
                        Padding(
                            padding: EdgeInsets.only(right: 16, left: 16),
                            child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () =>
                                        user.showChangePasswordDialog(context),
                                    child: ListTile(
                                      title: Text('Password',
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
                          color: Color(0xFFF5F7F8),
                          padding: EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'App Preferences',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF545454)),
                            ),
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(right: 16, left: 16),
                            child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AppBlockerPage()),
                                      );
                                    },
                                    child: ListTile(
                                      title: Text(
                                        'App Blocker',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF545454)),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(''),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_ios),
                                        ],
                                      ),
                                    ),
                                  ),
                                ))),
                        Divider(
                          color: Color.fromRGBO(16, 74, 115,
                              0.377), // Set the color of the divider
                          thickness: 0.5, // Set the thickness of the divider
                          indent: 30, // Set the indent on the left
                          endIndent: 30, // Set the indent on the right
                          height: 0,
                        ),
                        Padding(
                            padding: EdgeInsets.only(right: 16, left: 16),
                            child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () =>
                                        _showNotificationSettingsDialog(
                                            context),
                                    child: ListTile(
                                      title: Text(
                                        'Notifications',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF545454)),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(''),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_ios),
                                        ],
                                      ),
                                    ),
                                  ),
                                ))),
                        Container(
                          width: double.infinity,
                          color: Color(0xFFF5F7F8),
                          padding: EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Others',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF545454)),
                            ),
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(right: 16, left: 16),
                            child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () {
                                      final Uri emailLaunchUri = Uri(
                                        scheme: 'mailto',
                                        path: 'AttentionLens@gmail.com',
                                        query:
                                            'subject=Contact%20AttentionLens',
                                      );
                                      launch(emailLaunchUri.toString());
                                    },
                                    child: ListTile(
                                      title: Text(
                                        'Contact us',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF545454)),
                                      ),
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
                                ))),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () => user
                                .logout(context), // استدعاء دالة تسجيل الخروج
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
                                SizedBox(width: 0),
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
                            onPressed: () => user.deleteUser(context),
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
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 20.0, bottom: 10.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/greyLogo.png',
                                width: 120,
                                height: 80,
                              ),
                              Text(
                                "AttentionLens INC © 2025",
                                style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 186, 186, 186),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
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

class NotificationTimePicker extends StatefulWidget {
  @override
  _NotificationTimePickerState createState() => _NotificationTimePickerState();
}

class _NotificationTimePickerState extends State<NotificationTimePicker> {
  TimeOfDay? motivationalTime;
  TimeOfDay? taskReminderTime;
  bool isMotivationEnabled = true;
  bool isTaskReminderEnabled = true;


  @override
  void initState() {
    super.initState();
    _loadSavedTimes();
  }

  Future<void> _loadSavedTimes() async {
  final prefs = await SharedPreferences.getInstance();

  // Load saved times or fallback to default
  setState(() {
    motivationalTime = _parseTime(prefs.getString('motivational_time')) ?? TimeOfDay(hour: 8, minute: 0);
    taskReminderTime = _parseTime(prefs.getString('task_reminder_time')) ?? TimeOfDay(hour: 21, minute: 0);

    // 🟢 Load ON/OFF switch values (true if not saved yet)
    isMotivationEnabled = prefs.getBool('motivation_enabled') ?? true;
    isTaskReminderEnabled = prefs.getBool('task_reminder_enabled') ?? true;
  });
}


  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

Future<void> _pickTime(String type) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: type == 'motivation' ? motivationalTime! : taskReminderTime!,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF104A73),
            onPrimary: Color(0xFFF5F7F8),
            onSurface: Color(0xFF545454),
            secondary: Color(0xFF79A3B7),
          ),
          dialogBackgroundColor: Color(0xFFF5F7F8),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final prefs = await SharedPreferences.getInstance();
    final timeKey = type == 'motivation' ? 'motivational_time' : 'task_reminder_time';
    await prefs.setString(timeKey, '${picked.hour}:${picked.minute}');

    if (type == 'motivation') {
      setState(() {
        motivationalTime = picked;
      });

      if (isMotivationEnabled) {
        await NotificationService.cancelMotivationalNotification();
        await NotificationService.scheduleDailyMotivationalNotification();
      }
    } else {
      setState(() {
        taskReminderTime = picked;
      });

      if (isTaskReminderEnabled) {
        await NotificationService.cancelTaskReminderNotification();
        await NotificationService.scheduleCombinedReminderForIncompleteTasks();
      }
    }
  }
}

Future<void> _toggleNotification(String type, bool value) async {
  final prefs = await SharedPreferences.getInstance();
  if (type == 'motivation') {
    setState(() => isMotivationEnabled = value);
    prefs.setBool('motivation_enabled', value);

    if (value) {
      await NotificationService.scheduleDailyMotivationalNotification();
    } else {
      await NotificationService.cancelMotivationalNotification();
    }
  } else {
    setState(() => isTaskReminderEnabled = value);
    prefs.setBool('task_reminder_enabled', value);

    if (value) {
      await NotificationService.scheduleCombinedReminderForIncompleteTasks();
    } else {
      await NotificationService.cancelTaskReminderNotification();
    }
  }
}



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFFF5F7F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Notification Preferences",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Color(0xFF545454),
            ),
          ),
          const SizedBox(height: 20),

          // Motivation Time + Switch
          ListTile(
            leading: Icon(Icons.wb_sunny_outlined, color: Color(0xFF545454)),
            title: Text(
              "Daily Motivation",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF545454),
              ),
            ),
            subtitle: Text(
              "${motivationalTime?.format(context) ?? 'Not Set'}",
              style: TextStyle(
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
            trailing: Switch(
              value: isMotivationEnabled,
              onChanged: (val) => _toggleNotification('motivation', val),
              activeColor: Color(0xFF3B7292),
            ),
            onTap: () => _pickTime('motivation'),
          ),
          Divider(indent: 20, endIndent: 20, color: Colors.grey[400]),

          // Task Reminder Time + Switch
          ListTile(
            leading: Icon(Icons.check_circle_outline, color: Color(0xFF545454)),
            title: Text(
              "Unfinished tasks Reminders",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF545454),
              ),
            ),
            subtitle: Text(
              "${taskReminderTime?.format(context) ?? 'Not Set'}",
              style: TextStyle(
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
            trailing: Switch(
              value: isTaskReminderEnabled,
              onChanged: (val) => _toggleNotification('taskReminder', val),
              activeColor: Color(0xFF3B7292),
            ),
            onTap: () => _pickTime('taskReminder'),
          ),
          const SizedBox(height: 20),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(199, 217, 225, 1),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Close",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF363636),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}