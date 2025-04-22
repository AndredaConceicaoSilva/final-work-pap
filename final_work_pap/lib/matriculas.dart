import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Dark theme as default
      home: Matriculas(),
    );
  }
}

class Matriculas extends StatefulWidget {
  @override
  _MatriculasState createState() => _MatriculasState();
}

class _MatriculasState extends State<Matriculas> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _donoController = TextEditingController();

  int? _mesSelecionado;
  int? _anoSelecionado;
  bool _isLoading = false;

  void _formatarMatricula(String value) {
    final cursorPosition = _matriculaController.selection.baseOffset;
    final isDeleting = value.length < _matriculaController.text.length;

    String cleaned = value.replaceAll(RegExp(r'[-\s]'), '').toUpperCase();

    if (cleaned.length > 6) {
      cleaned = cleaned.substring(0, 6);
    }

    String formatted = '';
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 2 == 0) {
        formatted += '-';
      }
      formatted += cleaned[i];
    }

    int newCursorPosition = cursorPosition;
    if (!isDeleting && cursorPosition >= 0) {
      int hyphensBeforeCursor = formatted
          .substring(0, min(cursorPosition, formatted.length))
          .split('-')
          .length - 1;
      newCursorPosition = cursorPosition + hyphensBeforeCursor;
    }

    newCursorPosition = newCursorPosition.clamp(0, formatted.length);

    _matriculaController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPosition,
      ),
    );
  }

  Future<void> _salvarMatricula() async {
    if (_isLoading) return;
    
    if (!_formKey.currentState!.validate()) return;
    if (_mesSelecionado == null || _anoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione mês e ano de registro')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String matricula = _matriculaController.text.replaceAll('-', '').toUpperCase();
      
      var query = await FirebaseFirestore.instance
          .collection('matriculas')
          .where('matricula', isEqualTo: matricula)
          .get();

      if (query.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matrícula já cadastrada!')),
        );
        return;
      }

      DateTime now = DateTime.now();
      String dataEuropeia = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      await FirebaseFirestore.instance.collection('matriculas').add({
        'matricula': matricula,
        'marca': _marcaController.text,
        'modelo': _modeloController.text,
        'dono': _donoController.text,
        'mes': _mesSelecionado,
        'ano': _anoSelecionado,
        'data_cadastro': FieldValue.serverTimestamp(),
        'data_europeia': dataEuropeia,
      });

      // Clear form after successful submission
      _matriculaController.clear();
      _marcaController.clear();
      _modeloController.clear();
      _donoController.clear();
      setState(() {
        _mesSelecionado = null;
        _anoSelecionado = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matrícula cadastrada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int anoAtual = DateTime.now().year;
    List<int> anos = List.generate(anoAtual - 1950 + 1, (index) => 1950 + index).reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Matrícula', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              // License Plate Field
              TextFormField(
                controller: _matriculaController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  hintText: 'Ex: AA-11-22 ou 11-AA-22',
                  hintStyle: const TextStyle(color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                onChanged: _formatarMatricula,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe a matrícula';
                  
                  String cleaned = value.replaceAll('-', '');
                  
                  if (cleaned.length != 6) {
                    return 'Deve ter 6 caracteres (ex: AA-11-22)';
                  }
                  
                  if (!RegExp(r'^[A-Z]{2}\d{4}$').hasMatch(cleaned) && 
                      !RegExp(r'^\d{2}[A-Z]{2}\d{2}$').hasMatch(cleaned)) {
                    return 'Formato inválido (ex: AA-11-22 ou 11-AA-22)';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Brand and Model Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _marcaController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Informe a marca' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _modeloController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Informe o modelo' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Owner Field
              TextFormField(
                controller: _donoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Proprietário',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Informe o proprietário' : null,
              ),
              const SizedBox(height: 16),
              
              // Month and Year Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _mesSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Mês',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey[900],
                      items: List.generate(12, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                      )),
                      onChanged: (value) => setState(() => _mesSelecionado = value),
                      validator: (value) => value == null ? 'Selecione' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _anoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey[900],
                      items: anos.map((ano) => DropdownMenuItem(
                        value: ano,
                        child: Text('$ano', style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (value) => setState(() => _anoSelecionado = value),
                      validator: (value) => value == null ? 'Selecione' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarMatricula,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar matricula', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}