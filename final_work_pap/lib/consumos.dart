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

    if (litros <= 0 || km <= 0 || custo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos corretamente!')),
      );
      return;
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference registrosRef = firestore.collection('aut_consum').doc(matricula).collection('registros');
      QuerySnapshot querySnapshot = await registrosRef.where('quilometragem', isEqualTo: km).get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Essa quilometragem já foi registrada!')),
        );
        return;
      }

      DocumentReference matriculaRef = firestore.collection('aut_consum').doc(matricula);

      await matriculaRef.set({
        'matricula': matricula,
        'data_criacao': Timestamp.now(),
      }, SetOptions(merge: true));

      await registrosRef.add({
        'data_de_abastecimento': Timestamp.now(),
        'quilometragem': km,
        'litros_abastecidos': litros,
        'custo': custo,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consumo salvo com sucesso!')),
      );

      _litrosController.clear();
      _kmController.clear();
      _custoController.clear();
    } catch (e) {
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
              _buildTextField('Matrícula', widget.matricula, readOnly: true),
              SizedBox(height: 20),
              _buildTextField('Litros Abastecidos', '', controller: _litrosController, isNumeric: true),
              SizedBox(height: 20),
              _buildTextField('Quilometragem', '', controller: _kmController, isNumeric: true),
              SizedBox(height: 20),
              _buildTextField('Custo do Abastecimento', '', controller: _custoController, isNumeric: true),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveConsumo,
                  child: Text('Salvar Consumo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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

  Widget _buildTextField(String label, String initialValue, {TextEditingController? controller, bool readOnly = false, bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(),
      ),
      style: TextStyle(color: Colors.white),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
      validator: (value) {
        if (value == null || value.isEmpty || (isNumeric && double.tryParse(value) == null) || (isNumeric && double.parse(value) <= 0)) {
          return 'Por favor, insira um valor válido.';
        }
        return null;
      },
    );
  }
}
