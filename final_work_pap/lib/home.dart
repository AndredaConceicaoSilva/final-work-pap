import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'matriculas.dart';
import 'view_matr.dart';
import 'consumos.dart';
import 'manag.dart';
import 'editar_consumo.dart';
import 'editar_manutencao.dart';
import 'view_cons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  String? _selectedMatricula;
  DateTimeRange? _selectedDateRange;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _parseFirestoreDate(dynamic dateValue) {
    try {
      if (dateValue == null) return 'Data não informada';
      
      if (dateValue is Timestamp) {
        return _dateTimeFormat.format(dateValue.toDate());
      }
      
      if (dateValue is DateTime) {
        return _dateTimeFormat.format(dateValue);
      }
      
      if (dateValue is String) {
        final parsedDate = DateTime.tryParse(dateValue);
        if (parsedDate != null) {
          return _dateTimeFormat.format(parsedDate);
        }
      }
      
      return 'Formato inválido';
    } catch (e) {
      debugPrint('Erro ao parsear data: $e');
      return 'Erro na data';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _showMatriculaSelectionDialog();
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Matriculas()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ViewMatr()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ViewCons()));
    }
  }

  Future<void> _showMatriculaSelectionDialog() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('matriculas').get();
      List<String> matriculas = querySnapshot.docs.map((doc) => doc['matricula'] as String).toList();

      if (matriculas.isEmpty) {
        _showCustomSnackBar('Nenhuma matrícula disponível.');
        return;
      }

      String? selected = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[800],
            title: const Text('Selecione a Matrícula', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: matriculas.map((matricula) {
                  return ListTile(
                    title: Text(matricula, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context, matricula);
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      );

      if (selected != null) {
        setState(() {
          _selectedMatricula = selected;
          _selectedDateRange = null;
        });
      }
    } catch (e) {
      _showCustomSnackBar('Erro ao carregar matrículas: $e');
    }
  }

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _removeFilter() {
    setState(() {
      _selectedMatricula = null;
      _selectedDateRange = null;
    });
    _showCustomSnackBar('Filtro removido.');
  }

  Future<void> _showDateRangePicker() async {
    try {
      final DateTimeRange? pickedDateRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        currentDate: DateTime.now(),
        saveText: 'Confirmar',
        helpText: 'Selecione o intervalo',
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark(),
            child: child!,
          );
        },
      );

      if (pickedDateRange != null) {
        if (pickedDateRange.start.isAfter(pickedDateRange.end)) {
          _showCustomSnackBar('Data inicial deve ser anterior à data final');
          return;
        }

        setState(() {
          _selectedDateRange = pickedDateRange;
        });

        _showCustomSnackBar(
          'Intervalo selecionado: ${_dateFormat.format(pickedDateRange.start)} - ${_dateFormat.format(pickedDateRange.end)}'
        );
      }
    } catch (e) {
      _showCustomSnackBar('Erro ao selecionar datas: $e');
    }
  }

  Future<void> _navigateWithMatriculaCheck() async {
    await _showMatriculaSelectionDialog();
    
    if (_selectedMatricula == null) {
      _showCustomSnackBar('Selecione uma matrícula primeiro');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _tabController.index == 0
            ? Consumos(matricula: _selectedMatricula!)
            : Manag(matricula: _selectedMatricula!),
      ),
    );

    if (mounted) {
      setState(() {
        _selectedMatricula = null;
      });
    }
  }

  Widget _buildConsumoCard(String matricula, QueryDocumentSnapshot consumoDoc) {
    final data = consumoDoc.data() as Map<String, dynamic>;
    final dataAbastecimento = _parseFirestoreDate(data['data_de_abastecimento']);
    final quilometragem = data['quilometragem']?.toString() ?? 'N/I';
    final litrosAbastecidos = data['litros_abastecidos']?.toString() ?? 'N/I';
    final custo = data['custo']?.toString() ?? 'N/I';

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('$matricula - $dataAbastecimento', style: const TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Quilometragem: $quilometragem km', style: const TextStyle(color: Colors.white)),
            Text('Litros: $litrosAbastecidos L', style: const TextStyle(color: Colors.white)),
            Text('Custo: € $custo', style: const TextStyle(color: Colors.white)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditarConsumo(
                matriculaId: matricula,
                registroId: consumoDoc.id,
                dados: data,
              ),
            ),
          ).then((atualizado) {
            if (atualizado == true) {
              _showCustomSnackBar('Consumo atualizado com sucesso!');
            }
          });
        },
      ),
    );
  }

  Widget _buildManutencaoCard(String matricula, QueryDocumentSnapshot manutencaoDoc) {
    final data = manutencaoDoc.data() as Map<String, dynamic>;
    final dataManutencao = _parseFirestoreDate(data['data']);
    final ponto = data['ponto']?.toString() ?? 'N/I';
    final descricao = data['descricao']?.toString() ?? 'N/I';
    final custo = data['custo']?.toString() ?? 'N/I';

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('$matricula - $dataManutencao', style: const TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Ponto: $ponto', style: const TextStyle(color: Colors.white)),
            Text('Descrição: $descricao', style: const TextStyle(color: Colors.white)),
            Text('Custo: € $custo', style: const TextStyle(color: Colors.white)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditarManutencao(
                matriculaId: matricula,
                registroId: manutencaoDoc.id,
                dados: data,
              ),
            ),
          ).then((atualizado) {
            if (atualizado == true) {
              _showCustomSnackBar('Manutenção atualizada com sucesso!');
            }
          });
        },
      ),
    );
  }

  Widget _buildConsumosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedMatricula != null
          ? FirebaseFirestore.instance
              .collection('aut_consum')
              .where(FieldPath.documentId, isEqualTo: _selectedMatricula)
              .snapshots()
          : FirebaseFirestore.instance.collection('aut_consum').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          _showCustomSnackBar('Erro ao carregar consumos: ${snapshot.error}');
          return const SizedBox();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum consumo encontrado.', style: TextStyle(color: Colors.white)));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return StreamBuilder<QuerySnapshot>(
              stream: doc.reference.collection('registros')
                  .orderBy('data_de_abastecimento', descending: true)
                  .snapshots(),
              builder: (context, consumoSnapshot) {
                if (consumoSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (consumoSnapshot.hasError) {
                  _showCustomSnackBar('Erro ao carregar registros: ${consumoSnapshot.error}');
                  return const SizedBox();
                }
                if (!consumoSnapshot.hasData || consumoSnapshot.data!.docs.isEmpty) {
                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text('Nenhum registro para ${doc.id}', style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }

                return Column(
                  children: consumoSnapshot.data!.docs.where((consumo) {
                    var data = consumo.data() as Map<String, dynamic>;
                    
                    if (_selectedDateRange != null) {
                      var dateValue = data['data_de_abastecimento'];
                      DateTime? date;
                      
                      if (dateValue is Timestamp) {
                        date = dateValue.toDate();
                      } else if (dateValue is DateTime) {
                        date = dateValue;
                      } else if (dateValue is String) {
                        date = DateTime.tryParse(dateValue);
                      }
                      
                      if (date == null) return false;
                      
                      return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                    }
                    return true;
                  }).map((consumo) {
                    return _buildConsumoCard(doc.id, consumo);
                  }).toList(),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildManutencaoTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedMatricula != null
          ? FirebaseFirestore.instance
              .collection('aut_consum')
              .where(FieldPath.documentId, isEqualTo: _selectedMatricula)
              .snapshots()
          : FirebaseFirestore.instance.collection('aut_consum').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          _showCustomSnackBar('Erro ao carregar manutenções: ${snapshot.error}');
          return const SizedBox();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhuma matrícula encontrada.', style: TextStyle(color: Colors.white)));
        }

        return ListView(
          children: snapshot.data!.docs.map((matriculaDoc) {
            return StreamBuilder<QuerySnapshot>(
              stream: matriculaDoc.reference.collection('manut')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, manutencaoSnapshot) {
                if (manutencaoSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (manutencaoSnapshot.hasError) {
                  _showCustomSnackBar('Erro ao carregar manutenções: ${manutencaoSnapshot.error}');
                  return const SizedBox();
                }
                if (!manutencaoSnapshot.hasData || manutencaoSnapshot.data!.docs.isEmpty) {
                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text('Nenhuma manutenção para ${matriculaDoc.id}', style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }

                return Column(
                  children: manutencaoSnapshot.data!.docs.where((manutencaoDoc) {
                    var data = manutencaoDoc.data() as Map<String, dynamic>;
                    
                    if (_selectedDateRange != null) {
                      var dateValue = data['data'];
                      DateTime? date;
                      
                      if (dateValue is Timestamp) {
                        date = dateValue.toDate();
                      } else if (dateValue is DateTime) {
                        date = dateValue;
                      } else if (dateValue is String) {
                        date = DateTime.tryParse(dateValue);
                      }
                      
                      if (date == null) return false;
                      
                      return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                    }
                    return true;
                  }).map((manutencaoDoc) {
                    return _buildManutencaoCard(matriculaDoc.id, manutencaoDoc);
                  }).toList(),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ManageCar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Consumo'),
            Tab(text: 'Manutenção'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          if (_selectedMatricula != null || _selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _removeFilter,
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          if (_selectedMatricula != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _showDateRangePicker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Selecionar Intervalo de Datas', style: TextStyle(color: Colors.white)),
                  ),
                  if (_selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Intervalo: ${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConsumosTab(),
                _buildManutencaoTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateWithMatriculaCheck,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.filter_list),
              label: 'Filtro',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
              label: 'Matrículas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_list),
              label: 'Ver Matrículas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_gas_station),
              label: 'Ver Consumos',
            ),
          ],
        ),
      ),
    );
  }
}