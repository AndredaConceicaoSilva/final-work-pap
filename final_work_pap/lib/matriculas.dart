import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Matriculas extends StatefulWidget {
  @override
  _MatriculasState createState() => _MatriculasState();
}

class _MatriculasState extends State<Matriculas> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _donoController = TextEditingController(); // Novo controlador

  int? _mesSelecionado;
  int? _anoSelecionado;

  final RegExp matriculaRegex =
      RegExp(r'^\d{2}-[A-Z]{2}-\d{2}$|^\d{2}-\d{2}-[A-Z]{2}$|^[A-Z]{2}-\d{2}-\d{2}$');

  void _formatarMatricula(String value) {
    String cleaned = value.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    if (cleaned.length > 6) {
      cleaned = cleaned.substring(0, 6);
    }

    String formatted = '';
    for (int i = 0; i < cleaned.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '-';
      }
      formatted += cleaned[i];
    }

    _matriculaController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _salvarMatricula() async {
    String matricula = _matriculaController.text.toUpperCase();

    if (_formKey.currentState!.validate() &&
        _mesSelecionado != null &&
        _anoSelecionado != null) {
      
      try {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('matriculas')
            .where('matricula', isEqualTo: matricula)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Essa matrícula já está cadastrada!')),
          );
          return;
        }

        Map<String, dynamic> novaMatricula = {
          "matricula": matricula,
          "marca": _marcaController.text,
          "modelo": _modeloController.text,
          "ano": _anoSelecionado,
          "mes": _mesSelecionado,
          "dono": _donoController.text, // Adicionando o campo "Dono"
        };

        await FirebaseFirestore.instance.collection('matriculas').add(novaMatricula);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Matrícula salva com sucesso!')),
        );

        // Limpar todos os campos
        _matriculaController.clear();
        _marcaController.clear();
        _modeloController.clear();
        _donoController.clear(); // Limpa o campo "Dono"
        setState(() {
          _mesSelecionado = null;
          _anoSelecionado = null;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int anoAtual = DateTime.now().year;
    List<int> anos = List.generate(anoAtual - 1950 + 1, (index) => 1950 + index);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastrar Matrículas'),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _matriculaController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Matrícula (00-XX-00, 00-00-XX, XX-00-00)',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      _formatarMatricula(value.toUpperCase());
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a matrícula';
                      }
                      if (!matriculaRegex.hasMatch(value)) {
                        return 'Formato inválido! Use 00-XX-00, 00-00-XX ou XX-00-00';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _marcaController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Marca',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Informe a marca do veículo' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _modeloController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Modelo',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Informe o modelo do veículo' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _donoController, // Novo campo
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Dono',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Informe o nome do dono do veículo' : null,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _mesSelecionado,
                    style: TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey[900],
                    decoration: InputDecoration(
                      labelText: 'Mês',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _mesSelecionado = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Selecione um mês' : null,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _anoSelecionado,
                    style: TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey[900],
                    decoration: InputDecoration(
                      labelText: 'Ano',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    items: anos.map((ano) {
                      return DropdownMenuItem(
                        value: ano,
                        child: Text(
                          '$ano',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _anoSelecionado = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Selecione um ano' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _salvarMatricula,
                    child: Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
