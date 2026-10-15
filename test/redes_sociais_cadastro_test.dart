import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/utils/redes_sociais_cadastro.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/wizard_aluno_screen.dart';

void main(){
 test('Instagram opcional aceita usuario ou link e rejeita entradas ambiguas',(){
  expect(normalizarInstagramCadastro(' @ana.personal '),'ana.personal');
  expect(normalizarInstagramCadastro('https://www.instagram.com/ana.personal/?igsh=teste#bio'),'ana.personal');
  expect(normalizarInstagramCadastro(''), '');
  for(final entrada in ['ana personal','https://example.com/ana','https://instagram.com.evil/ana','https://senha@instagram.com/ana','https://instagram.com/p/video/']){
   expect(validarInstagramCadastro(entrada),isNotNull,reason:entrada);
  }
 });
 test('Link da bio e opcional e deve ser URL http ou https sem credenciais',(){
  expect(validarLinkBioCadastro(''),isNull);
  expect(validarLinkBioCadastro(' https://example.invalid/minha-bio '),isNull);
  for(final valor in ['javascript:alert(1)','ftp://example.com','https://user:senha@example.com','www.example.com','https://exa mple.com']){
   expect(validarLinkBioCadastro(valor),isNotNull,reason:valor);
  }
 });
 testWidgets('cadastro aluno envia Instagram e bio normalizados junto aos dados', (t)async{
  SharedPreferences.setMockInitialValues({});
  t.view.physicalSize=const Size(800,1500);t.view.devicePixelRatio=1;
  addTearDown(t.view.resetPhysicalSize);addTearDown(t.view.resetDevicePixelRatio);
  Map<String,dynamic>? enviado;
  await http.runWithClient(()async{
   await t.pumpWidget(const MaterialApp(home:WizardAlunoScreen()));await t.pumpAndSettle();
   for(final campo in {'Nome completo':'Ana Aluna','Email':'ana@example.invalid','Senha':'segredo1','Confirmar senha':'segredo1','CPF':'52998224725','Telefone':'34999990000','Instagram (opcional)':'https://instagram.com/ana.aluna/','Link da bio (opcional)':'https://example.invalid/ana'}.entries){
    await t.enterText(find.widgetWithText(TextFormField,campo.key),campo.value);await t.pump();
   }
   await t.tap(find.text('Próximo'));await t.pumpAndSettle();
   await t.tap(find.text('Próximo'));await t.pumpAndSettle();
   await t.enterText(find.widgetWithText(TextFormField,'Objetivo (ex.: Perder peso, Ganhar massa muscular)'),'Objetivo informado');
   await t.enterText(find.widgetWithText(TextFormField,'Peso (kg)'),'70');
   await t.tap(find.text('Concluir cadastro'));await t.pumpAndSettle();
   expect(t.takeException(),isNull);
  },()=>MockClient((r)async{
   if(r.url.path.endsWith('registrar-aluno')){enviado=Map<String,dynamic>.from(jsonDecode(r.body));return http.Response(jsonEncode({'id':1,'loginId':2,'message':'ok'}),201);}
   return http.Response('[]',200);
  }));
  expect(enviado,isNotNull);expect(enviado!['instagram'],'ana.aluna');expect(enviado!['linkBio'],'https://example.invalid/ana');
 });
}
