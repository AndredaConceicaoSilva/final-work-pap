import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditarConsumo extends StatefulWidget {
  final String matriculaId;
  final String registroId;
  final Map<String, dynamic> dados;

  const EditarConsumo({
    Key? key,
    required this.matriculaId,
    required this.registroId,
    required this.dados,
  }) : super(key: key);

  @override
  _EditarConsumoState createState() => _EditarConsumoState();
}

class _EditarConsumoState extends State<EditarConsumo> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dataController;
  late final TextEditingController _kmController;
  late final TextEditingController _litrosController;
  late final TextEditingController _custoController;
  late final TextEditingController _combustivelController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataController = TextEditingController(
      text: widget.dados['data_de_abastecimento'] is Timestamp
          ? DateFormat('dd/MM/yyyy').format(widget.dados['data_de_abastecimento'].toDate())
          : '',
    );
    _kmController = TextEditingController(text: widget.dados['quilometragem']?.toString() ?? '');
    _litrosController = TextEditingController(text: widget.dados['litros_abastecidos']?.toString() ?? '');
    _custoController = TextEditingController(text: widget.dados['custo']?.toString() ?? '');
    _combustivelController = TextEditingController(text: widget.dados['tipo_combustivel']?.toString() ?? 'Gasolina');
  }

  @override
  void dispose() {
    _dataController.dispose();
    _kmController.dispose();
    _litrosController.dispose();
    _custoController.dispose();
    _combustivelController.dispose();
    super.dispose();
  }

  Future<void> _salvarEdicao() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance
            .collection('aut_consum')
            .doc(widget.matriculaId)
            .collection('registros')
            .doc(widget.registroId)
            .update({
          'quilometragem': double.tryParse(_kmController.text),
          'litros_abastecidos': double.tryParse(_litrosController.text),
          'custo': double.tryParse(_custoController.text),
          'tipo_combustivel': _combustivelController.text,
          'ultima_atualizacao': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Consumo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dataController,
                decoration: const InputDecoration(labelText: 'Data'),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmController,
                decoration: const InputDecoration(labelText: 'Quilometragem'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe a quilometragem';
                  if (double.tryParse(value) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _litrosController,
                decoration: const InputDecoration(labelText: 'Litros Abastecidos'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe os litros';
                  if (double.tryParse(value) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _custoController,
                decoration: const InputDecoration(labelText: 'Custo (€)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe o custo';
                  if (double.tryParse(value) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _combustivelController.text,
                items: ['Gasolina', 'Diesel', 'Elétrico', 'GPL', 'Híbrido']
                    .map((combustivel) => DropdownMenuItem(
                          value: combustivel,
                          child: Text(combustivel),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _combustivelController.text = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Tipo de Combustível'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarEdicao,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('SALVAR ALTERAÇÕES'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
