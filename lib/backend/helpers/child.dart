import 'package:attendly/backend/enums/genders.dart';

//it is a helper class to make insertion easier
class Child{
  final String name;
  final String birthday;
  final Genders gender; 
  final bool migration;
  final String migrationBackground;

   Child({
    required this.name,
    required this.birthday,
    required this.gender,
    required this.migration,
    required this.migrationBackground
  });

  List<Object?> toList(){
    return[
      name,
      birthday,
      gender.name,
      migration ? 1 : 0,
      migrationBackground == "" ? null : migrationBackground
    ];
  }

  Map<String, dynamic> toMap(){
    return{
      "id" : null,
      "name": name,
      "birthday": birthday,
      "gender": gender.name,
      "migration":migration ? 1 : 0,
      "migration_background":migrationBackground == "" ? null : migrationBackground
    };
  }
}