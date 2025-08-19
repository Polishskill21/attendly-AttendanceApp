import 'package:flutter/widgets.dart';

class StateManager {

  static List<Map<String, dynamic>> _temporaryDataFirstPage = [];

  static List<Map<String, dynamic>> getChildrenList(){
    return _temporaryDataFirstPage;
  }

  static void setChildrenList(List<Map<String, dynamic>> newList){
    debugPrint("Updating static");
    //passing immutable list
    _temporaryDataFirstPage = List<Map<String, dynamic>>.from(newList);
  }

  static void updateChildAtIndex(int index, Map<String, dynamic> newPerson){
    _temporaryDataFirstPage[index] = newPerson;
  }

  static void delteChildAtIndex(int index){
    _temporaryDataFirstPage.removeAt(index);
  }

  static void clearChildrenList(){
    _temporaryDataFirstPage.clear();
  }
}