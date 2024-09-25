import 'package:flutter/material.dart';

class dropdown {
    String name;
 

    dropdown({

      required this.name,
    


    });

    static List<dropdown> getCat() {
      List<dropdown> drop = [];
      
      drop.add(
      dropdown(
      name:'TimeLine',
       
      )
     );

    drop.add(
      dropdown(
      name:'Category',
       
      )
     );


      drop.add(
      dropdown(
      name:'Urgency',
       
      )
     );

    

    return drop;
    }
    
    
}