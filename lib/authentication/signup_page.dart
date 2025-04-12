import 'package:flutter/material.dart';
import 'package:flutter_application/authentication/EmailVerificationPage';
import 'package:flutter_application/authentication/Signin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController  = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  DateTime? _selectedDate;
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  void _showTopNotification(String message) {
    final overlayState =
        Navigator.of(context).overlay; // Access the root navigator's overlay
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.1, // Top position
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlayState?.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF3b7292), // Header color
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF3b7292)), // Selected date color
            buttonTheme: const ButtonThemeData(
                textTheme: ButtonTextTheme.primary), // Button text color
          ),
          child: child ?? Container(),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day}/${picked.month}/${picked.year}"; // Format as DD/MM/YYYY
      });
    }
  }

  // Function to handle form submission and Firebase registration
  void signUp() async {
  if (_formKey.currentState!.validate()) {
    final DateTime today = DateTime.now();
    final int age = today.year - _selectedDate!.year;
    print(age);

    if (_selectedDate!.isAfter(today)) {
      _showTopNotification('The date of birth is invalid.');
      return;
    } else if (age < 13) {
      // الأطفال تحت 13 سنة ممنوعون تمامًا
      _showTopNotification('You must be at least 13 years old to sign up.');
      return;
    } else if (age < 18) {
      //for ten between 13 and 17
      _showTeenagerDialog();
      return;
    }

    // متابعة التسجيل إذا كان العمر 18 أو أكبر
    _registerUser();
  }
}



// تسجيل المستخدم بعد التحقق من العمر
void _registerUser() async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    User? user = userCredential.user;
    if (user != null) {
    

      if (!user.emailVerified) {
        await user.sendEmailVerification();

        Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => EmailVerificationPage(
      user: user,
      userData: {
        'name': _nameController.text.trim(),
        'email': user.email,
        'dateOfBirth': _dobController.text.trim(), 
        'password': _passwordController.text.trim(), 
      },
    ),
  ),
);

      }
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      _showTopNotification('This email is already registered.');
    } else {
      _showTopNotification('Registration failed: ${e.message}');
    }
  } catch (e) {
    print('Error: $e');
    _showTopNotification('Something went wrong. Please try again.');
  }
}

// نافذة تأكيد للمراهقين
Future<void> _showTeenagerDialog() async {

  
  bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Age Restriction',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'This app is intended for users 18 years or older. Do you want to Continue?',
          style: TextStyle(color: Color(0xFF545454)), // darkGray color
        ),
        backgroundColor: const Color(0xFFF5F7F8), // lightGray color
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false); // User doesn't want to proceed
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF79A3B7)), // lightBlue
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF79A3B7)), // lightBlue
            ),
          ),
          
          ElevatedButton(
            
           onPressed: () {
    _registerUser();
  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF79A3B7), // lightBlue
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

}

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height; 
    final bottomsize = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              // Background image
              top: bottomsize > 0 ? 0 : 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/signup.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: screenHeight, // Keep the height for the image
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child:TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name *',
                                  filled: true,
                                  fillColor: Colors.white70,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE6EBEF),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3b7292),
                                    ),
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: Color(0xFF3b7292),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Name is required'; // إذا كان الحقل فارغًا
                                  } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                    return 'Name must contain only letters and spaces'; // إذا كان الحقل يحتوي على أرقام أو رموز
                                  }
                                  return null; 
                                },
                              ),

                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email *',
                              filled: true,
                              fillColor: Colors.white70,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE6EBEF),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3b7292),
                                ),
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Color(0xFF3b7292),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'Date of Birth *',
                              filled: true,
                              fillColor: Colors.white70,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE6EBEF),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3b7292),
                                ),
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Color(0xFF3b7292),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Date of Birth is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password *',
                              filled: true,
                              fillColor: Colors.white70,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE6EBEF),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3b7292),
                                ),
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Color(0xFF3b7292),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color:
                                      const Color.fromARGB(255, 122, 137, 146),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              } else if (value.length < 8) {
                                return 'Password must be at least 8 characters long';
                              } else if (!RegExp(
                                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#]).{8,}$')
                                  .hasMatch(value)) {
                                return 'Password must contain upper, lower, number, and symbol';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B7292),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                minimumSize: const Size(0, 40),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54, // Optional color
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to login page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SigninPage()),
                                  );
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF3b7292),
                                    fontWeight: FontWeight.bold,
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

}
