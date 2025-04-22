import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditarManutencao extends StatefulWidget {
  final String matriculaId;
  final String registroId;
  final Map<String, dynamic> dados;

  const EditarManutencao({
    Key? key,
    required this.matriculaId,
    required this.registroId,
    required this.dados,
  }) : super(key: key);

  @override
  _EditarManutencaoState createState() => _EditarManutencaoState();
}

class _EditarManutencaoState extends State<EditarManutencao> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dataController;
  late final TextEditingController _pontoController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _custoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataController = TextEditingController(
      text: widget.dados['data'] is Timestamp
          ? DateFormat('dd/MM/yyyy').format(widget.dados['data'].toDate())
          : '',
    );
    _pontoController = TextEditingController(text: widget.dados['ponto']?.toString() ?? '');
    _descricaoController = TextEditingController(text: widget.dados['descricao']?.toString() ?? '');
    _custoController = TextEditingController(text: widget.dados['custo']?.toString() ?? '');
  }

  @override
  void dispose() {
    _dataController.dispose();
    _pontoController.dispose();
    _descricaoController.dispose();
    _custoController.dispose();
    super.dispose();
  }

  Future<void> _salvarEdicao() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance
            .collection('aut_consum')
            .doc(widget.matriculaId)
            .collection('manut')
            .doc(widget.registroId)
            .update({
          'ponto': _pontoController.text,
          'descricao': _descricaoController.text,
          'custo': double.tryParse(_custoController.text),
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
        title: const Text('Editar Manutenção'),
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
                controller: _pontoController,
                decoration: const InputDecoration(labelText: 'Ponto'),
                validator: (value) => value?.isEmpty ?? true ? 'Informe o ponto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Informe a descrição' : null,
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
