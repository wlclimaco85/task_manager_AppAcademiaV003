import 'package:task_manager_flutter/data/models/user_abstract.dart';
import 'package:task_manager_flutter/data/models/user_trainer.dart';

class UserAdm extends AbstractUser {
  String gymName = "";
  String gymLogoImg = "";

  List<int> listTrainerIds = [];
  List<UserTrainer> listUserTrainers = [];
}
