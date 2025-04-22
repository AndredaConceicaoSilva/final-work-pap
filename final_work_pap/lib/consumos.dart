import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Consumos extends StatefulWidget {
  final String matricula;

  const Consumos({required this.matricula, Key? key}) : super(key: key);

  @override
  _ConsumosState createState() => _ConsumosState();
}

class _ConsumosState extends State<Consumos> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _litrosController = TextEditingController();
  final _custoController = TextEditingController();
  final _dataController = TextEditingController();
  final _combustivelController = TextEditingController();
  DateTime? _dataSelecionada;
  DateTime? _ultimaData;
  int? _ultimaQuilometragem;

  // Cores definidas como constantes
  static const _darkGrey = Color(0xFF212121);
  static const _white70 = Color(0xB3FFFFFF);
  static const _white54 = Color(0x8AFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadLastRecord();
    _combustivelController.text = 'Gasolina'; // Valor inicial
  }

  @override
  void dispose() {
    _kmController.dispose();
    _litrosController.dispose();
    _custoController.dispose();
    _dataController.dispose();
    _combustivelController.dispose();
    super.dispose();
  }

  Future<void> _loadLastRecord() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('aut_consum')
          .doc(widget.matricula)
          .collection('registros')
          .orderBy('data_de_abastecimento', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final lastRecord = querySnapshot.docs.first;
        setState(() {
          _ultimaData = (lastRecord['data_de_abastecimento'] as Timestamp).toDate();
          _ultimaQuilometragem = lastRecord['quilometragem'] as int;
        });
      }
    } catch (e) {
      _showError('Erro ao carregar último registro: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ultimaData ?? DateTime.now(),
      firstDate: _ultimaData ?? DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataSelecionada = picked;
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveConsumo() async {
    if (!_formKey.currentState!.validate()) return;

    final double? litros = double.tryParse(_litrosController.text.trim());
    final int? km = int.tryParse(_kmController.text.trim());
    final double? custo = double.tryParse(_custoController.text.trim());

    if (litros == null || km == null || custo == null || _dataSelecionada == null) {
      _showError('Por favor, preencha todos os campos corretamente!');
      return;
    }

    if (litros <= 0 || km <= 0 || custo <= 0) {
      _showError('Todos os valores devem ser maiores que zero!');
      return;
    }

    if (_ultimaData != null && _dataSelecionada!.isBefore(_ultimaData!)) {
      _showError('Data não pode ser anterior a ${DateFormat('dd/MM/yyyy').format(_ultimaData!)}');
      return;
    }

    if (_ultimaQuilometragem != null && km <= _ultimaQuilometragem!) {
      _showError('Quilometragem deve ser maior que $_ultimaQuilometragem km');
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('aut_consum')
          .doc(widget.matricula)
          .collection('registros');

      await docRef.add({
        'data_de_abastecimento': Timestamp.fromDate(_dataSelecionada!),
        'quilometragem': km,
        'litros_abastecidos': litros,
        'custo': custo,
        'tipo_combustivel': _combustivelController.text,
        'created_at': FieldValue.serverTimestamp(),
      });

      _clearForm();
      await _loadLastRecord();
      _showSuccess('Consumo registrado com sucesso!');
    } catch (e) {
      _showError('Erro ao salvar: ${e.toString()}');
    }
  }

  void _clearForm() {
    _kmController.clear();
    _litrosController.clear();
    _custoController.clear();
    _dataController.clear();
    setState(() {
      _dataSelecionada = null;
      _combustivelController.text = 'Gasolina';
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Consumo - ${widget.matricula}'),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_ultimaData != null && _ultimaQuilometragem != null)
                _buildLastRecordInfo(),
              _buildDateField(),
              const SizedBox(height: 20),
              _buildKmField(),
              const SizedBox(height: 20),
              _buildLitrosField(),
              const SizedBox(height: 20),
              _buildCustoField(),
              const SizedBox(height: 20),
              _buildCombustivelDropdown(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastRecordInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: _white70, fontSize: 16),
          children: [
            const TextSpan(text: 'Último registro: '),
            TextSpan(
              text: DateFormat('dd/MM/yyyy').format(_ultimaData!),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' - '),
            TextSpan(
              text: '$_ultimaQuilometragem km',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dataController,
      decoration: InputDecoration(
        labelText: 'Data de Abastecimento (dd/mm/aaaa)',
        labelStyle: const TextStyle(color: _white70),
        filled: true,
        fillColor: _darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          onPressed: () => _selectDate(context),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      readOnly: true,
      validator: (value) => value == null || value.isEmpty ? 'Selecione a data' : null,
    );
  }

  Widget _buildKmField() {
    return TextFormField(
      controller: _kmController,
      decoration: InputDecoration(
        labelText: 'Quilometragem (km)',
        labelStyle: const TextStyle(color: _white70),
        filled: true,
        fillColor: _darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintText: _ultimaQuilometragem != null
            ? 'Mínimo: ${_ultimaQuilometragem! + 1} km'
            : null,
        hintStyle: const TextStyle(color: _white54),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Informe a quilometragem';
        final km = int.tryParse(value);
        if (km == null || km <= 0) return 'Valor inválido';
        if (_ultimaQuilometragem != null && km <= _ultimaQuilometragem!) {
          return 'Mínimo: ${_ultimaQuilometragem! + 1} km';
        }
        return null;
      },
    );
  }

  Widget _buildLitrosField() {
    return TextFormField(
      controller: _litrosController,
      decoration: InputDecoration(
        labelText: 'Litros Abastecidos (L)',
        labelStyle: const TextStyle(color: _white70),
        filled: true,
        fillColor: _darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Informe os litros';
        final litros = double.tryParse(value);
        if (litros == null || litros <= 0) return 'Valor inválido';
        return null;
      },
    );
  }

  Widget _buildCustoField() {
    return TextFormField(
      controller: _custoController,
      decoration: InputDecoration(
        labelText: 'Custo Total (€)',
        labelStyle: const TextStyle(color: _white70),
        filled: true,
        fillColor: _darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Informe o custo';
        final custo = double.tryParse(value);
        if (custo == null || custo <= 0) return 'Valor inválido';
        return null;
      },
    );
  }

  Widget _buildCombustivelDropdown() {
    return DropdownButtonFormField<String>(
      value: _combustivelController.text.isNotEmpty ? _combustivelController.text : 'Gasolina', // Valor inicial
      items: ['Gasolina', 'Diesel', 'Elétrico', 'GPL', 'Híbrido']
          .map((combustivel) => DropdownMenuItem<String>(
                value: combustivel,
                child: Text(combustivel, style: const TextStyle(color: Colors.black)),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _combustivelController.text = value;
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'Tipo de Combustível',
        labelStyle: const TextStyle(color: _white70),
        filled: true,
        fillColor: _darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: Colors.grey[200],
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveConsumo,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Salvar Consumo',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
