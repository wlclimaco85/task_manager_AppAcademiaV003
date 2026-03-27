import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
// Importe o pacote dart:convert

class CheckoutCaller {
  static final Dio _dio = Dio();

  static Future<String> carregarTermos() async {
    String jsonString = "";
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fecthUltimoTermo);

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body?['texto']);
        jsonString = utf8.decode(latin1.encode(jsonString));
        jsonString =
            jsonString.trim().replaceAll(RegExp(r'(\n|\r|\t|\\n|\\r)'), '');
      } else {
        // Trate o caso onde o data é nulo
      }
    } catch (e) {
      return "Erro de conexão: ${e.toString()}";
    }
    return jsonString;
  }

  static Future<double> carregarVlrFrete(
      BuildContext context, Map<String, dynamic> parceiroData) async {
    try {
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.fecthCalcFrete, parceiroData);

      if (response.statusCode == 200 && response.body != null) {
        final List<Map<String, dynamic>> data =
            (response.body?['data']['account'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
        return _calcularMediaFrete(data);
      }
      throw Exception('Erro na resposta: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao calcular frete: $e');
    }
    return 0.0;
  }

  static double _calcularMediaFrete(List<dynamic> data) {
    final filtered = data
        .where((item) =>
            item['tipoCarga'] == 'GRANEL_SOLIDO' &&
            item['lotacao']?['semCargaRetorno'] != null)
        .toList();

    if (filtered.isEmpty) return 0.0;

    final total = filtered.fold<double>(
        0.0,
        (sum, item) =>
            sum + (item['lotacao']['semCargaRetorno'] as num).toDouble());

    return total / filtered.length;
  }

  static Future<String> downloadContract() async {
    const url = 'https://seuservidor.com/api/contract.pdf';
    final response = await Dio().download(url, 'contrato.pdf');
    print('Contrato baixado: ${response.data}');

    return 'Contrato baixado com sucesso!';
  }

  void _uploadContract2() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await Dio()
          .post('https://seuservidor.com/api/upload', data: formData);
      print('Contrato enviado: ${response.data}');
    }
  }

  static Future<void> uploadContract(int vendaID) async {
    // Adicione o parâmetro vendaID
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        File uploadedFile = File(file.path!);

        final dio = Dio();
        final url = ApiLinks.upLoadContrato;

        // Adicione o vendaID ao FormData
        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(uploadedFile.path,
              filename: file.name),
          'vendaID': vendaID
              .toString(), // Envie como String ou int (depende do backend)
        });

        final response = await dio.post(
          url,
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer SEU_TOKEN',
            },
          ),
        );

        if (response.statusCode == 200) {
          print('Contrato enviado com sucesso!');
        } else {
          print('Erro ao enviar o contrato: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Erro ao enviar contrato: $e');
    }
  }

  Future<bool> downloadContrato(int contratoId, BuildContext context) async {
    final url = "${ApiLinks.downloadContrato}/$contratoId";

    // Get the token (replace with your actual AuthUtility method)
    final token =
        AuthUtility.userInfo?.token; // Assuming userInfo.token is available

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Important: Add Accept header
        },
      );

      if (response.statusCode == 200) {
        // ... (rest of your download and open file logic)

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/contrato_$contratoId.pdf');
        await file
            .writeAsBytes(response.bodyBytes); // Write the bytes to the file

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Download concluído! Abrindo o contrato...')),
        );

        OpenFilex.open(file.path); // Open the file
        return true;
      } else {
        print(
            'Error: ${response.statusCode} - ${response.body}'); // Print error details
        // Try to decode the error response body (if it's JSON)
        try {
          final errorData = jsonDecode(response.body);
          print('Error Data: $errorData'); // Print decoded error data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erro ao baixar contrato: ${errorData['message'] ?? 'Erro desconhecido'}')),
          );
          return false;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao baixar contrato')),
          );
          return false;
        }
      }
    } catch (e) {
      print('Error during download: $e'); // Catch and log any exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao baixar contrato')),
      );
      return false;
    }
  }
}
