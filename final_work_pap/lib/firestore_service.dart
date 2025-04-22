import 'package:cloud_firestore/cloud_firestore.dart';

/// Verifica se a coleção 'notificacoes_agendadas' existe.
/// Se não existir, cria um documento vazio para inicializá-la.
Future<void> _verificarOuCriarColecao() async {
  final collectionRef = FirebaseFirestore.instance.collection('notificacoes_agendadas');

  // Tenta buscar um documento da coleção
  final snapshot = await collectionRef.limit(1).get();

  // Se a coleção estiver vazia, cria um documento inicial
  if (snapshot.docs.isEmpty) {
    await collectionRef.doc('inicial').set({
      'mensagem': 'Coleção notificacoes_agendadas inicializada.',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('Coleção notificacoes_agendadas criada com sucesso.');
  } else {
    print('Coleção notificacoes_agendadas já existe.');
  }
}

/// Agenda uma notificação para 15 dias antes do mês selecionado.
Future<void> agendarNotificacao({
  required String matricula,
  required String marca,
  required String modelo,
  required int mes,
  required int ano,
  required String dono,
  required String token,
}) async {
  try {
    // Verifica ou cria a coleção 'notificacoes_agendadas'
    await _verificarOuCriarColecao();

    // 1. Calcula a data de notificação (15 dias antes do início do mês selecionado)
    final dataNotificacao = DateTime.utc(ano, mes, -14); // -14 dias do início do mês

    // 2. Cria um documento na coleção 'notificacoes_agendadas'
    await FirebaseFirestore.instance.collection('notificacoes_agendadas').add({
      "titulo": "Lembrete de Matrícula", // Título da notificação
      "mensagem": "Faltam 15 dias para o mês da matrícula $matricula.", // Mensagem da notificação
      "token": token, // Token FCM do dispositivo
      "dataNotificacao": dataNotificacao.toIso8601String(), // Data da notificação no formato ISO
    });

    print('Notificação agendada para: $dataNotificacao');
  } catch (e) {
    print('Erro ao agendar notificação: $e');
  }
}