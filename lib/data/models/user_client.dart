import 'package:task_manager_flutter/data/models/training_block.dart';
import 'package:task_manager_flutter/data/models/user_abstract.dart';

class UserClient extends AbstractUser {
  String uniqueCodeClient = "";
  List<TrainingBlock> listTrainingBlock = [];
}
