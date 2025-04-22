import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewMatr extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualizar Veiculos'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matriculas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar Veiculos: ${snapshot.error}', style: TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nenhum Veiculos encontrado.', style: TextStyle(color: Colors.white)));
          }

          final matriculas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: matriculas.length,
            itemBuilder: (context, index) {
              var matriculaData = matriculas[index].data() as Map<String, dynamic>;
              var matricula = matriculaData['matricula'] ?? 'Veiculos não disponível';
              var dono = matriculaData['dono'] ?? 'Dono não disponível';
              var documentId = matriculas[index].id;

              return Card(
                color: Colors.grey[800],
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(matricula, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Dono: $dono', style: TextStyle(color: Colors.grey[400])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _editMatricula(context, documentId, matriculaData);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _removeMatricula(context, documentId); // Passa o context aqui
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editMatricula(BuildContext context, String documentId, Map<String, dynamic> matriculaData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMatrScreen(documentId: documentId, initialData: matriculaData),
      ),
    );
  }

  void _removeMatricula(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir esta matrícula?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar o diálogo
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('matriculas').doc(documentId).delete().then((_) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Matrícula excluída com sucesso.')));
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir matrícula: $error')));
              });
              Navigator.of(context).pop(); // Fechar o diálogo
            },
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class EditMatrScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> initialData;

  EditMatrScreen({required this.documentId, required this.initialData});

  @override
  _EditMatrScreenState createState() => _EditMatrScreenState();
}

class _EditMatrScreenState extends State<EditMatrScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _ano;
  late String _marca;
  late String _matricula;
  late int _mes;
  late String _modelo;
  late String _dono;

  @override
  void initState() {
    super.initState();
    _ano = widget.initialData['ano']?.toString() ?? '';
    _marca = widget.initialData['marca'] ?? '';
    _matricula = widget.initialData['matricula'] ?? '';
    _mes = widget.initialData['mes'] ?? 1; // Valor padrão
    _modelo = widget.initialData['modelo'] ?? '';
    _dono = widget.initialData['dono'] ?? '';
  }

  void _updateMatricula() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      FirebaseFirestore.instance.collection('matriculas').doc(widget.documentId).update({
        'ano': _ano,
        'marca': _marca,
        'matricula': _matricula,
        'mes': _mes,
        'modelo': _modelo,
        'dono': _dono,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Matrícula atualizada com sucesso!')));
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar matrícula: $error')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Matrícula'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _ano,
                decoration: InputDecoration(
                  labelText: 'Ano',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um ano';
                  }
                  int? anoValue = int.tryParse(value);
                  if (anoValue == null || anoValue < 1950 || anoValue > DateTime.now().year) {
                    return 'Ano deve estar entre 1950 e ${DateTime.now().year}';
                  }
                  return null;
                },
                onSaved: (value) {
                  _ano = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _marca,
                decoration: InputDecoration(
                  labelText: 'Marca',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma marca';
                  }
                  return null;
                },
                onSaved: (value) {
                  _marca = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _matricula,
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma matrícula';
                  }
                  return null;
                },
                onSaved: (value) {
                  _matricula = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _mes.toString(),
                decoration: InputDecoration(
                  labelText: 'Mês',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um mês';
                  }
                  int? mesValue = int.tryParse(value);
                  if (mesValue == null || mesValue < 1 || mesValue > 12) {
                    return 'Mês deve estar entre 1 e 12';
                  }
                  return null;
                },
                onSaved: (value) {
                  _mes = int.parse(value!);
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _modelo,
                decoration: InputDecoration(
                  labelText: 'Modelo',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um modelo';
                  }
                  return null;
                },
                onSaved: (value) {
                  _modelo = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _dono,
                decoration: InputDecoration(
                  labelText: 'Dono',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um dono';
                  }
                  return null;
                },
                onSaved: (value) {
                  _dono = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateMatricula,
                child: Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Cor de fundo do botão
                  foregroundColor: Colors.white, // Cor do texto do botão
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}