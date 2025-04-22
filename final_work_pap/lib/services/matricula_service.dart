import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MatriculaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para verificar as matrículas e enviar notificações
  Future<void> verificarMatriculas() async {
    final DateTime agora = DateTime.now();
    final DateTime inicioProximoMes = DateTime(agora.year, agora.month + 1, 1);
    final DateTime limite = inicioProximoMes.subtract(Duration(days: 15));

    // Busca todas as matrículas na coleção
    QuerySnapshot matriculas = await _firestore.collection('matriculas').get();

    for (var doc in matriculas.docs) {
      final String anoString = doc['ano']; // Ano como string
      final int mes = doc['mes']; // Mês como número
      final int ano = int.parse(anoString); // Converte o ano para inteiro

      // Cria a data da matrícula (primeiro dia do mês)
      final DateTime dataMatricula = DateTime(ano, mes, 1);

      // Verifica se a data da matrícula está dentro do período de 15 dias antes do início do próximo mês
      if (dataMatricula.isAfter(limite) && dataMatricula.isBefore(inicioProximoMes)) {
        final String dono = doc['dono']; // Nome do dono
        final String matricula = doc['matricula']; // Número da matrícula

        // Envia uma notificação para o dono
        await enviarNotificacao(dono, matricula, ano, mes);
      }
    }
  }

  // Função para enviar notificações
  Future<void> enviarNotificacao(String dono, String matricula, int ano, int mes) async {
    // Busca o token FCM do dono (assumindo que você armazena o token na coleção 'users')
    final QuerySnapshot userQuery = await _firestore
        .collection('users')
        .where('nome', isEqualTo: dono)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final String? token = userQuery.docs.first['fcm_token']; // Token FCM do usuário

      if (token != null) {
        final String mensagem = "Olá $dono! Faltam 15 dias para o início da matrícula $matricula ($mes/$ano).";

        // Envia a notificação via FCM
        await _firestore.collection('notificacoes').add({
          'to': token,
          'notification': {
            'title': 'Lembrete de Matrícula',
            'body': mensagem,
          },
        });

        print("Notificação enviada para $dono: $mensagem");
      } else {
        print("Token FCM não encontrado para $dono.");
      }
    } else {
      print("Usuário $dono não encontrado.");
    }
  }

  // Função para salvar o token FCM do usuário
  Future<void> salvarTokenFCM(String userId) async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    final String? token = await _firebaseMessaging.getToken();

    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcm_token': token,
      });
      print("Token FCM salvo para o usuário $userId: $token");
    }
  }
}