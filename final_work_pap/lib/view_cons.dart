import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewCons extends StatelessWidget {
  const ViewCons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Consumos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('aut_consum').snapshots(),
        builder: (context, matriculasSnapshot) {
          if (matriculasSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          if (matriculasSnapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar veículos: ${matriculasSnapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!matriculasSnapshot.hasData || matriculasSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum veículo encontrado no sistema.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView(
            children: matriculasSnapshot.data!.docs.map((matriculaDoc) {
              return FutureBuilder<QuerySnapshot>(
                future: matriculaDoc.reference
                    .collection('registros')
                    .orderBy('data_de_abastecimento', descending: true)
                    .get(),
                builder: (context, consumosSnapshot) {
                  if (consumosSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard(matriculaDoc.id);
                  }

                  if (consumosSnapshot.hasError) {
                    return _buildErrorCard(matriculaDoc.id, consumosSnapshot.error.toString());
                  }

                  final consumos = consumosSnapshot.data?.docs ?? [];
                  return _buildVehicleCard(matriculaDoc.id, consumos);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard(String matricula) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(16),
      child: ListTile(
        title: Text(
          'Carregando dados de $matricula...',
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String matricula, String error) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(16),
      child: ListTile(
        title: Text(
          'Erro em $matricula',
          style: const TextStyle(color: Colors.red),
        ),
        subtitle: Text(
          error.length > 50 ? '${error.substring(0, 50)}...' : error,
          style: const TextStyle(color: Colors.redAccent),
        ),
        leading: const Icon(Icons.error_outline, color: Colors.red),
      ),
    );
  }

  Widget _buildVehicleCard(String matricula, List<QueryDocumentSnapshot> consumos) {
    final stats = _calculateStats(consumos);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  matricula,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    '${consumos.length} abast.',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blue[800],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Estatísticas com fallback para valores inválidos
            _buildStatRow('Total gasto:', stats['totalGasto'] ?? '0.00 €'),
            _buildStatRow('Total litros:', stats['totalLitros'] ?? '0.00 L'),
            _buildStatRow('Média km/L:', stats['mediaKmL'] ?? '0.00'),
            const SizedBox(height: 12),
            
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            
            const Text(
              'Registros recentes:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            if (consumos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Nenhum abastecimento registrado',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              ...consumos.take(3).map((doc) => _buildConsumoItem(doc)).toList(),
            
            if (consumos.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '... mais ${consumos.length - 3} abastecimentos',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _calculateStats(List<QueryDocumentSnapshot> consumos) {
    try {
      double totalGasto = 0;
      double totalLitros = 0;
      double totalKm = 0;
      int validRecords = 0;

      for (var doc in consumos) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          final custo = _parseDoubleSafe(data['custo']);
          final litros = _parseDoubleSafe(data['litros_abastecidos']);
          final km = _parseDoubleSafe(data['quilometragem']);

          // Só conta se tiver pelo menos litros e km válidos
          if (litros > 0 && km > 0) {
            totalGasto += custo;
            totalLitros += litros;
            totalKm += km;
            validRecords++;
          }
        } catch (e) {
          debugPrint('Erro ao processar registro ${doc.id}: $e');
        }
      }

      // Cálculo da média apenas com registros válidos
      final mediaKmPorLitro = validRecords > 0 && totalLitros > 0 
          ? totalKm / totalLitros 
          : 0;

      // Formatação dos valores
      final format = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);
      final litrosFormat = NumberFormat.decimalPattern('pt_BR');

      return {
        'totalGasto': '${format.format(totalGasto)} €',
        'totalLitros': '${litrosFormat.format(totalLitros)} L',
        'mediaKmL': mediaKmPorLitro.toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('Erro ao calcular estatísticas: $e');
      return {
        'totalGasto': '0.00 €',
        'totalLitros': '0.00 L',
        'mediaKmL': '0.00',
      };
    }
  }

  double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildConsumoItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Tratamento seguro da data
    String dataFormatada;
    try {
      final timestamp = data['data_de_abastecimento'] as Timestamp?;
      dataFormatada = timestamp != null 
          ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
          : '--/--/----';
    } catch (e) {
      dataFormatada = '--/--/----';
    }

    // Tratamento seguro dos valores
    final quilometragem = _formatNumber(data['quilometragem'], '0');
    final litros = _formatNumber(data['litros_abastecidos'], '0.0');
    final custo = _formatNumber(data['custo'], '0.00', isCurrency: true);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dataFormatada, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text('$quilometragem km', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$litros L', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text('$custo €', style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic value, String fallback, {bool isCurrency = false}) {
    if (value == null) return fallback;
    
    try {
      final numValue = value is num ? value : num.tryParse(value.toString());
      if (numValue == null) return fallback;

      return isCurrency
          ? NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(numValue)
          : NumberFormat.decimalPattern('pt_BR').format(numValue);
    } catch (e) {
      return fallback;
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}