import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/home_list_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/ui/screens/suplemento_list.dart';
import 'package:task_manager_flutter/ui/screens/suplemento_add.dart';

class SuplementoScreen extends StatefulWidget {
  const SuplementoScreen({
    super.key,
    this.canInsert = true,
  });

  final bool canInsert;

  @override
  State<SuplementoScreen> createState() => _SuplementoScreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _SuplementoScreenState extends State<SuplementoScreen> {
  @override
  void initState() {
    findAllAcademia();
    super.initState();
  }

  bool standardSelected = false;
  bool filledSelected = false;
  bool tonalSelected = false;
  bool outlinedSelected = false;
  int count = 0;
  final List<String> modalidadeList = ['Musculação'];

  void log(String message) => print(message);

  bool _addNewTaskLoading = false;

  void _openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SuplementoModalAdd()),
    );
  }

  List<String> getList(List<dynamic> newMap) {
    late List<String> modList = [];
    for (var v in newMap) {
      Map<String, dynamic> request = v;
      modList.add(v['nome']);
    }

    return modList;
  }

  Future<void> findAllAcademia() async {
    _isLoading = true;
    _addNewTaskLoading = true;
    if (mounted) {
      setState(() {});
    }
    final alunoId = AuthUtility.userInfo.data?.id ?? 1;
    Map<String, dynamic> requestBody = {
      "codAluno": {"id": alunoId},
    };

    final NetworkResponse response = await NetworkCaller()
        .postRequest(ApiLinks.allSuplementoAluno, requestBody);
    _addNewTaskLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      _taskNameController.clear();
      _taskDescriptionController.clear();
      if (mounted) {
        dynamic data = response.body?['data'];
        List<dynamic> datas = data;
        mywidgets = [];
        for (var element in datas) {
          mywidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListItensSuplemento(
                    nome: element['nome'] ?? "",
                    marca: element['marca'] ?? "",
                    dataIni: element['dtInicio'] ?? "",
                    dataFin: element['dtFinal'] ?? "",
                    dataVal: element['dtVal'] ?? "",
                    porcao: element['dosagem'] ?? "",
                    foto: element['foto'],
                    id: element['id'],
                    valor: element['valor'] ?? "",
                    sabor: element['sabor'] ?? "",
                    tamanho: element['tamanho'] ?? ""),
              ],
            ),
          );
        }
        _isLoading = false;
      }
    } else {
      if (mounted) {
        mywidgets = [];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nenhuma suplemento cadastrado!"),
          ),
        );
        _isLoading = false;
      }
    }
  }

  List<HomeListModel> listModels = [
    HomeListModel(
      title: "Academia - O Club",
      assetIcon: "assets/icons/gym_icon.png",
    ),
    HomeListModel(
      title: "Biometa Academia",
      assetIcon: "assets/icons/gym_icon.png",
    ),
    HomeListModel(
      title: "Academia Titanium Core",
      assetIcon: "assets/icons/gym_icon.png",
    )
  ];
  refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  floatingActionButton: getHomeFab(context, listModels, refreshPage),
      backgroundColor: const Color(0xFF340A9C),
      floatingActionButton: widget.canInsert
          ? FloatingActionButton(
              onPressed: _openAdd,
              backgroundColor: const Color(0xFFFA903A),
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
            )
          : null,
      appBar: UserBannerAppBar(
        screenTitle: 'Suplementos',
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen()));
        },
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: mywidgets,
          ),
        ),
      ),
    );
  }
}
