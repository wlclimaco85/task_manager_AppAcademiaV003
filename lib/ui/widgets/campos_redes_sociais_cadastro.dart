import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/redes_sociais_cadastro.dart';

class CamposRedesSociaisCadastro extends StatelessWidget {
  final TextEditingController instagram;
  final TextEditingController linkBio;
  const CamposRedesSociaisCadastro(
      {super.key, required this.instagram, required this.linkBio});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
            controller: instagram,
            autocorrect: false,
            keyboardType: TextInputType.url,
            validator: validarInstagramCadastro,
            decoration: const InputDecoration(
                labelText: 'Instagram (opcional)',
                hintText: '@seuusuario ou link do perfil')),
        const SizedBox(height: 12),
        TextFormField(
            controller: linkBio,
            autocorrect: false,
            keyboardType: TextInputType.url,
            validator: validarLinkBioCadastro,
            decoration: const InputDecoration(
                labelText: 'Link da bio (opcional)', hintText: 'https://...')),
        const SizedBox(height: 12),
      ]);
}
