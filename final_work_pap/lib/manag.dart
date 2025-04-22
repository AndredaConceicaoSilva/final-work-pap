import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Manag extends StatefulWidget {
  final String matricula;
  
  Manag({required this.matricula});

  @override
  _ManagState createState() => _ManagState();
}

class _ManagState extends State<Manag> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _descricaoController = TextEditingController();
  TextEditingController _custoController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedPonto;

  final List<String> _pontosManutencao = [
    'Óleo do Motor',
    'Filtro de Óleo',
    'Filtro de Ar',
    'Filtro de Combustível',
    'Pneus',
    'Travões',
    'Correia de Distribuição',
    'Velas de Ignição',
    'Bateria',
    'Sistema de Refrigeração',
    'Alinhamento e Balanceamento',
    'Suspensão',
    'Escapamento',
    'Faróis e Iluminação',
    'Ar Condicionado',
    'Outros'
  ];

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _salvarManutencao() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedPonto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, selecione a data e o ponto de manutenção')),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('aut_consum')
            .doc(widget.matricula)
            .collection('manut')
            .add({
          'descricao': _descricaoController.text,
          'custo': double.tryParse(_custoController.text) ?? 0.0,
          'ponto': _selectedPonto,
          'data': DateFormat('dd-MM-yyyy').format(_selectedDate!),
        });

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar manutenção: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adicionar Manutenção')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Nenhuma data selecionada'
                          : 'Data: ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selecionarData(context),
                    child: Text('Selecionar Data'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Ponto de Manutenção'),
                value: _selectedPonto,
                items: _pontosManutencao.map((String ponto) {
                  return DropdownMenuItem<String>(
                    value: ponto,
                    child: Text(ponto),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPonto = newValue;
                  });
                },
                validator: (value) => value == null ? 'Selecione um ponto' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(labelText: 'Descrição'),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Informe a descrição' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _custoController,
                decoration: InputDecoration(labelText: 'Custo (€)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Informe o custo' : null,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _salvarManutencao,
                  child: Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
