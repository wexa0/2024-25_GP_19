//updated
import 'package:flutter/material.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatbotpageWidget(),
    );
  }
}

class ChatbotpageWidget extends StatelessWidget {
  const ChatbotpageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;
    // Figma Flutter Generator ChatbotpageWidget - FRAME
     return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      bottomNavigationBar: const CustomBottomNavigationBar(),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 39,
            left: 72,
            child: Container(
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      decoration: const BoxDecoration(),
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            decoration: const BoxDecoration(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(),
                                    child: Stack(children: <Widget>[
                                      Positioned(
                                          top: 0,
                                          left: 0,
                                          child: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: const BoxDecoration(
                                                color: Color.fromRGBO(
                                                    242, 248, 255, 1),
                                                borderRadius: BorderRadius.all(
                                                    Radius.elliptical(44, 44)),
                                              ))),
                                      Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(),
                                              child: Stack(children: <Widget>[
                                                Positioned(
                                                    top: 1.4399999380111694,
                                                    left: 0.9599999785423279,
                                                    child: SvgPicture.asset(
                                                        'assets/images/vector.svg',
                                                        semanticsLabel:
                                                            'vector')),
                                              ]))),
                                    ])),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: const BoxDecoration(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Text(
                                        'AtenaBot',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color:
                                                Color.fromRGBO(32, 35, 37, 1),
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            letterSpacing:
                                                0 /*percentages not used in flutter. defaulting to zero*/,
                                            fontWeight: FontWeight.normal,
                                            height: 1.4285714285714286),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        decoration: const BoxDecoration(),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      124, 222, 134, 1),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.elliptical(
                                                              8, 8)),
                                                )),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Always active',
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                  color: Color.fromRGBO(
                                                      114, 119, 122, 1),
                                                  fontFamily: 'DM Sans',
                                                  fontSize: 12,
                                                  letterSpacing:
                                                      0 /*percentages not used in flutter. defaulting to zero*/,
                                                  fontWeight: FontWeight.normal,
                                                  height: 1.3333333333333333),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          Positioned(
              top: 133,
              left: 16,
              child: Container(
                decoration: const BoxDecoration(),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      decoration: const BoxDecoration(),
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Wed 8:21 AM',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: Color.fromRGBO(114, 119, 122, 1),
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                letterSpacing:
                                    0 /*percentages not used in flutter. defaulting to zero*/,
                                fontWeight: FontWeight.normal,
                                height: 1.3333333333333333),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: const BoxDecoration(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(),
                                    child: Stack(children: <Widget>[
                                      Positioned(
                                          top: 0,
                                          left: 0,
                                          child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: const BoxDecoration(
                                                color: Color.fromRGBO(
                                                    242, 248, 255, 1),
                                                borderRadius: BorderRadius.all(
                                                    Radius.elliptical(32, 32)),
                                              ))),
                                      Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: const BoxDecoration(),
                                              child: Stack(children: <Widget>[
                                                Positioned(
                                                    top: 0.9599999785423279,
                                                    left: 0.6399999856948853,
                                                    child: SvgPicture.asset(
                                                        'assets/images/vector.svg',
                                                        semanticsLabel:
                                                            'vector')),
                                              ]))),
                                    ])),
                                const SizedBox(width: 8),
                                Container(
                                  width: screenWidth *
                                      0.85, // Set width to 85% of screen width
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(0),
                                      topRight: Radius.circular(24),
                                      bottomLeft: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                    ),
                                    color: Color.fromRGBO(242, 243, 244, 1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Expanded(
                                        // Use Expanded to allow text to take available space
                                        child: Text(
                                          'Hello, I’m Atena! 👋 I’m your personal ADHD time management assistant. How can I help you?',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            color:
                                                Color.fromRGBO(48, 52, 55, 1),
                                            fontFamily: 'DM Sans',
                                            fontSize: 16,
                                            letterSpacing:
                                                0, // percentages not used in flutter. defaulting to zero
                                            fontWeight: FontWeight.normal,
                                            height: 1.5,
                                          ),
                                          softWrap:
                                              true, // Optional: softWrap is true by default
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          Positioned(
              top: 377,
              left: 16,
              child: Container(
                decoration: const BoxDecoration(),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      decoration: const BoxDecoration(),
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(),
                              child: Stack(children: <Widget>[
                                Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color:
                                              Color.fromRGBO(242, 248, 255, 1),
                                          borderRadius: BorderRadius.all(
                                              Radius.elliptical(32, 32)),
                                        ))),
                                Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(),
                                        child: Stack(children: <Widget>[
                                          Positioned(
                                              top: 0.9599999785423279,
                                              left: 0.6399999856948853,
                                              child: SvgPicture.asset(
                                                  'assets/images/vector.svg',
                                                  semanticsLabel: 'vector')),
                                        ]))),
                              ])),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              color: Color.fromRGBO(242, 243, 244, 1),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'you only have “going to gym” task at 5pm',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      color: Color.fromRGBO(48, 52, 55, 1),
                                      fontFamily: 'DM Sans',
                                      fontSize: 16,
                                      letterSpacing:
                                          0 /*percentages not used in flutter. defaulting to zero*/,
                                      fontWeight: FontWeight.normal,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          Positioned(
            top: 288,
            right: 16, // Set the distance from the right edge
            //left: (MediaQuery.of(context).size.width - 200) / 2, // Center the button based on width
            child: Container(
              // Remove fixed width to allow the box to fit the text
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(0),
                ),
                color: Color.fromRGBO(47, 84, 150, 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: const Row(
                  mainAxisSize: MainAxisSize.min, // Use min to fit the text
                  children: <Widget>[
                    Text(
                      'Show me today’s tasks',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                  ]),
            ),
          ),
          Positioned(
              top: 709,
              left: -8,
              child: SizedBox(
                  width: 375,
                  height: 67,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0),
                              topRight: Radius.circular(0),
                              bottomLeft: Radius.circular(48),
                              bottomRight: Radius.circular(0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Color.fromRGBO(
                                      0, 0, 0, 0.03999999910593033),
                                  offset: Offset(0, -2),
                                  blurRadius: 100)
                            ],
                            color: Color.fromRGBO(255, 255, 255, 1),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                decoration: const BoxDecoration(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(48),
                                          topRight: Radius.circular(48),
                                          bottomLeft: Radius.circular(48),
                                          bottomRight: Radius.circular(48),
                                        ),
                                        color: const Color.fromRGBO(255, 255, 255, 1),
                                        border: Border.all(
                                          color:
                                              const Color.fromRGBO(151, 156, 158, 1),
                                          width: 1.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ]))),
          Positioned(
              top: 43,
              left: 13,
              child: SizedBox(
                  width: 27,
                  height: 42,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: SvgPicture.asset('assets/images/vector.svg',
                            semanticsLabel: 'vector')),
                  ]))),
          Positioned(
              top: 721,
              left: 293,
              child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(),
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(97, 98, 101, 1),
                              borderRadius:
                                  BorderRadius.all(Radius.elliptical(44, 44)),
                            ))),
                    Positioned(
                        top: 5,
                        left: 5,
                        child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage('assets/images/Menu.png'),
                                  fit: BoxFit.fitWidth),
                            ))),
                  ]))),
          Positioned(
              top: 721,
              left: 246,
              child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(),
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(97, 98, 101, 1),
                              borderRadius:
                                  BorderRadius.all(Radius.elliptical(44, 44)),
                            ))),
                    Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                            width: 29,
                            height: 29,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/Emailsend.png'),
                                  fit: BoxFit.fitWidth),
                            ))),
                  ]))),
        ]));
  }
}
