import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

class Manag extends StatefulWidget {
  final String matricula;

  Manag({required this.matricula});

  @override
  _ManagState createState() => _ManagState();
}

class _ManagState extends State<Manag> {
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _custoController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _pontoSelecionado;
  String _custo = "";
  DateTime? _dataSelecionada;

  final List<String> _pontosDeManutencao = [
    'Troca de Óleo',
    'Verificação de Freios',
    'Alinhamento e Balanceamento',
    'Substituição de Pneus',
    'Manutenção de Suspensão',
    'Verificação do Sistema Elétrico',
  ];

  Future<void> _saveManut() async {
    String descricao = _descricaoController.text.trim();
    String custo = _custo.trim();
    String? dataFormatada = _dataSelecionada != null
        ? DateFormat('yyyy-MM-dd').format(_dataSelecionada!)
        : null;

    if (_pontoSelecionado != null && descricao.isNotEmpty &&
        custo.isNotEmpty && dataFormatada != null) {
      try {
        await _firestore
            .collection('aut_consum')
            .doc(widget.matricula)
            .collection('manut')
            .add({
          'ponto': _pontoSelecionado,
          'descricao': descricao,
          'custo': double.tryParse(custo) ?? 0.0,
          'data': dataFormatada,
          'matricula': widget.matricula,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manutenção salva com sucesso!')),
        );

        setState(() {
          _pontoSelecionado = null;
          _descricaoController.clear();
          _custoController.clear();
          _custo = "";
          _dataSelecionada = null;
          _dataController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: Colors.black,
            hintColor: Colors.white,
            colorScheme: ColorScheme.dark(primary: Colors.white),
            dialogBackgroundColor: Colors.black,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dataSelecionada = picked;
        _dataController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manutenção - ${widget.matricula}'),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              readOnly: true,
              controller: _dataController,
              decoration: InputDecoration(
                labelText: 'Data',
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Ponto de Manutenção',
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white),
              ),
              dropdownColor: Colors.black,
              value: _pontoSelecionado,
              onChanged: (String? newValue) {
                setState(() {
                  _pontoSelecionado = newValue;
                });
              },
              items: _pontosDeManutencao.map((String ponto) {
                return DropdownMenuItem<String>(
                  value: ponto,
                  child: Text(ponto, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _custoController,
              decoration: InputDecoration(
                labelText: 'Custo (€)',
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveManut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Salvar Manutenção'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}