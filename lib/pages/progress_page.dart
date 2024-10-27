import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';  
import 'package:google_nav_bar/google_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProgressPage(),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataMap = <String, double>{
      "No Category": 3,
      "Routine": 3,
      "Home": 2,
    };

    final colorList = <Color>[
      Color(0xFF2F5496),  // Deep blue for "No Category"
      Color(0xFFA5BBE3),  // Light blue for "Routine"
      Color(0xFF3C6ABE),  // Light blue for "Home"
    ];

    // Get the current date in the desired format
    final currentDate = DateFormat('EEE, dd/MM/yyyy').format(DateTime.now());

    // Apply the Google font to the entire page
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFEAEAEA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(  
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 1),
                  Text(currentDate, style: TextStyle(fontSize: 16, color: Colors.grey)),  // Display the current date in gray
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTaskCard("Complete Task", "3"),
                      _buildTaskCard("Pending Task", "5"),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),  // 'Today' inside the rectangle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: dataMap.keys.map((key) => _buildLegend(key, colorList[dataMap.keys.toList().indexOf(key)])).toList(),
                              ),
                            ),
                            PieChart(
                              dataMap: dataMap,
                              animationDuration: const Duration(milliseconds: 800),
                              chartLegendSpacing: 32,
                              chartRadius: MediaQuery.of(context).size.width / 3.7,
                              colorList: colorList,
                              initialAngleInDegree: 0,
                              chartType: ChartType.ring,
                              ringStrokeWidth: 29,
                              centerText: "",
                              legendOptions: LegendOptions(
                                showLegends: false, // Hide default legends as we are custom rendering on the left
                              ),
                              chartValuesOptions: ChartValuesOptions(
                                showChartValues: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Coming Soon overlay for the bar chart section
            Positioned.fill(
              child: Container(
                color: Colors.grey.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.hourglass_empty, size: 80, color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'This feature is not available yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GNav(
            selectedIndex: 3,  // Set index to the Progress page
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gap: 8,
            tabs: const [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.task, text: 'Tasks'),
              GButton(icon: Icons.sms, text: 'Chatbot'),
              GButton(icon: Icons.poll, text: 'Progress'),
              GButton(icon: Icons.person, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFD1D1D1),  // Light grey for task card
        borderRadius: BorderRadius.circular(15),  // More rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 1,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLegend(String key, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 14),  // Circle color indicator
        SizedBox(width: 5),  // Space between circle and text
        Text(key, style: TextStyle(fontSize: 15)),
      ],
    );
  }
}
