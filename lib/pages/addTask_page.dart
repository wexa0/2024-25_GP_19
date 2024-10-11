import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

String? selectedCategory;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.abyssinicaSilTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const AddTaskWidget(), // Set the AddTaskWidget as the home
    );
  }
}

class AddTaskWidget extends StatelessWidget {
  const AddTaskWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Use Scaffold for the layout
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            // Add your onTap functionality here
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xffF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/icons/left-arrow.png',
              height: 20,
              width: 20,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        // Allows the content to be scrollable
        child: SizedBox(
          width: 362,
          child: Column( // Use Column instead of Stack
            children: <Widget>[
              // "Add task" at the top
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 20),
                child: Text(
                  'Add task',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromRGBO(33, 150, 243, 1),
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    height: 1.5,
                  ),
                ),
              ),

              // Task name input field
              const SizedBox(
                width: 350,
                height: 52,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Task name',
                    hintStyle: TextStyle(
                      color: Color.fromRGBO(51, 51, 51, 0.7),
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // "+ Add subtasks" with icon
              const Row(
                children: [
                  Icon(
                    Icons.add, // Add icon
                    color: Color.fromRGBO(33, 150, 243, 1),
                    size: 18,
                  ),
                  SizedBox(width: 5), // Space between icon and text
                  Text(
                    'Add subtasks',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color.fromRGBO(33, 150, 243, 1),
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              // "Category" title
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Category',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Color.fromRGBO(33, 150, 243, 1),
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    height: 1.5,
                  ),
                ),
              ),

              // Dropdown for selecting the category
              Container(
                width: 340, // Set width to match other input fields
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButton<String>(
                  isExpanded: true, // Makes the dropdown occupy the full width
                  value: selectedCategory,
                  hint: const Text("Select category"),
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: const SizedBox(), // Removes the default underline
                  onChanged: (String? newValue) {
                    selectedCategory = newValue; // No need for `!` as it might be null
                  },
                  items: <String>[
                    'Work',
                    'Home',
                    'Personal',
                    'Others'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),

              // Date
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today, // Calendar icon
                      color: Color.fromRGBO(33, 150, 243, 1),
                      size: 18,
                    ),
                    SizedBox(width: 10), // Space between icon and text
                    Text(
                      'Date',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Color.fromRGBO(33, 150, 243, 1),
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Priority
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag, // Flag icon for Priority
                      color: Color.fromRGBO(33, 150, 243, 1),
                      size: 18,
                    ),
                    SizedBox(width: 10), // Space between icon and text
                    Text(
                      'Priority',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Color.fromRGBO(33, 150, 243, 1),
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Reminder
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications, // Bell icon for Reminder
                      color: Color.fromRGBO(33, 150, 243, 1),
                      size: 18,
                    ),
                    SizedBox(width: 10), // Space between icon and text
                    Text(
                      'Reminder',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Color.fromRGBO(33, 150, 243, 1),
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // "+ Add timer" with icon
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.add, // Add icon
                      color: Color.fromRGBO(33, 150, 243, 1),
                      size: 18,
                    ),
                    SizedBox(width: 5), // Space between icon and text
                    Text(
                      'Add timer',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Color.fromRGBO(33, 150, 243, 1),
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Description input field
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  width: 349,
                  height: 162,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromRGBO(33, 150, 243, 0.1),
                    border: Border.all(
                      color: const Color.fromRGBO(33, 150, 243, 1),
                      width: 1,
                    ),
                  ),
                  child: const TextField(
                    maxLines: 5, // Allow for multiple lines in the description
                    decoration: InputDecoration(
                      border: InputBorder.none, // No border to match design
                      hintText: 'Enter your description',
                      hintStyle: TextStyle(
                        color: Color.fromRGBO(51, 51, 51, 0.7),
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                      contentPadding: EdgeInsets.all(10), // Padding for the text input
                    ),
                  ),
                ),
              ),

              // Circular button with tick icon at the bottom right corner
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    onPressed: () {
                      // Action to perform when the button is pressed
                    },
                    backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
