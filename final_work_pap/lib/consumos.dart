import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Consumos extends StatefulWidget {
  final String matricula;

  Consumos({required this.matricula});

  @override
  _ConsumosState createState() => _ConsumosState();
}

class _ConsumosState extends State<Consumos> {
  final _formKey = GlobalKey<FormState>();
  final _litrosController = TextEditingController();
  final _kmController = TextEditingController();
  final _custoController = TextEditingController();

  Future<void> _saveConsumo() async {
    if (!_formKey.currentState!.validate()) return;

    String matricula = widget.matricula;
    double litros = double.tryParse(_litrosController.text.trim()) ?? 0;
    int km = int.tryParse(_kmController.text.trim()) ?? 0;
    double custo = double.tryParse(_custoController.text.trim()) ?? 0;

    // Validação para garantir que os valores não sejam 0 ou nulos
    if (litros <= 0 || km <= 0 || custo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos corretamente!')),
      );
      return;
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Verificar se a quilometragem já existe na subcoleção de registros
      CollectionReference registrosRef = firestore.collection('aut_consum').doc(matricula).collection('registros');
      QuerySnapshot querySnapshot = await registrosRef.where('quilometragem', isEqualTo: km).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Se já houver um registro com a mesma quilometragem, mostramos um erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Essa quilometragem já foi registrada!')),
        );
        return;
      }

      // Acessa a coleção 'aut_consum' e o documento da matrícula
      DocumentReference matriculaRef = firestore.collection('aut_consum').doc(matricula);

      // Adiciona ou atualiza a matrícula
      await matriculaRef.set({
        'matricula': matricula,
        'data_criacao': Timestamp.now(),
      }, SetOptions(merge: true));

      print("Matrícula $matricula criada/atualizada com sucesso!");

      // Criando a subcoleção 'registros' dentro do documento da matrícula
      // Adiciona o consumo como um novo documento dentro da subcoleção 'registros'
      await registrosRef.add({
        'data_de_abastecimento': Timestamp.now(),
        'quilometragem': km,
        'litros_abastecidos': litros,
        'custo': custo,
      });

      print("Consumo salvo com sucesso!");

      // Exibe uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consumo salvo com sucesso!')),
      );

      // Limpa os campos após salvar o consumo
      _litrosController.clear();
      _kmController.clear();
      _custoController.clear();

    } catch (e) {
      print("Erro ao salvar consumo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consumo - ${widget.matricula}'),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.matricula,
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                readOnly: true,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _litrosController,
                decoration: InputDecoration(
                  labelText: 'Litros Abastecidos',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Por favor, insira um valor válido para os litros.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _kmController,
                decoration: InputDecoration(
                  labelText: 'Quilometragem',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Por favor, insira uma quilometragem válida.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _custoController,
                decoration: InputDecoration(
                  labelText: 'Custo do Abastecimento',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Por favor, insira um custo válido.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveConsumo,
                  child: Text('Salvar Consumo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
