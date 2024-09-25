import 'package:flutter/material.dart';

class catModel {
    String name;
    String time;
    Color boxColor;

    catModel({

      required this.name,
      required this.time,
      required this.boxColor,


    });

    static List<catModel> getCat() {
      List<catModel> category = [];
      
      category.add(
      catModel(
      name:'Go for a walk with friend',
      time:'9:00-10:00 am',
      boxColor: Color.fromARGB(255, 253, 239, 239)
      )
     );

     category.add(
      catModel(
      name:'Class in gym',
      time:'10:00-12:00 am',
      boxColor: Color.fromARGB(255, 237, 244, 254)
      )
     );


      category.add(
      catModel(
      name:'',
      time:'',
      boxColor: Color.fromARGB(0,0,0,0)
      )); 
      
      
      category.add(
      catModel(
      name:' Call with client',
      time:'2:00-3:00 am',
      boxColor: Color.fromARGB(255, 255, 247, 236)
      )
     );

    return category;
    }
    
    
}