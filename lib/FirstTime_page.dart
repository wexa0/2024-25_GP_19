import 'package:flutter/material.dart';
import 'package:flutter_application/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstTimePage extends StatelessWidget {
  const FirstTimePage({Key? key}) : super(key: key);

  Future<void> _markAsSeen(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false); // تحديث الحالة
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => HomePage()),
);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // صورة الخلفية
          Positioned.fill(
            child: Image.asset(
              'assets/images/initialPage.png', // مسار الصورة
              fit: BoxFit.cover, // ملء الشاشة بالصورة
            ),
          ),
          // زر "Get Started"
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0), // مسافة من الأسفل
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8, // عرض الزر 80% من الشاشة
                child: ElevatedButton(
                  onPressed: () => _markAsSeen(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF104A73), // لون الزر
                    padding: const EdgeInsets.symmetric(vertical: 14), // ارتفاع الزر
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  )
              ),
            ),
          ),
        ],
      ),
    );
  }
}
