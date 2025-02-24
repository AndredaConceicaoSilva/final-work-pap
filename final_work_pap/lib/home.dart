import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'matriculas.dart';
import 'consumos.dart';
import 'view_matr.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  String? _selectedMatricula;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    }
  }

  void _onAddButtonPressed() {
    _showMatriculaSelectionForAdd();
  }

  Future<void> _showMatriculaSelectionForAdd() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('matriculas').get();
      List<String> matriculas = querySnapshot.docs.map((doc) => doc['matricula'] as String).toList();

      if (matriculas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhuma matrícula disponível.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Selecione a Matrícula'),
            content: SingleChildScrollView(
              child: Column(
                children: matriculas.map((matricula) {
                  return ListTile(
                    title: Text(matricula),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Consumos(matricula: matricula)),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar matrículas: $e')),
      );
    }
  }

  void _showMatriculaSelectionDialog() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('matriculas').get();
      List<String> matriculas = querySnapshot.docs.map((doc) => doc['matricula'] as String).toList();

      if (matriculas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhuma matrícula disponível.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Selecione a Matrícula'),
            content: SingleChildScrollView(
              child: Column(
                children: matriculas.map((matricula) {
                  return ListTile(
                    title: Text(matricula),
                    onTap: () {
                      setState(() {
                        _selectedMatricula = matricula;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar matrículas: $e')),
      );
    }
  }

  void _removeFilter() {
    setState(() {
      _selectedMatricula = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ManageCar'),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Consumo'),
            Tab(text: 'Manutenção'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      backgroundColor: Colors.black,
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('aut_consum').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro ao carregar consumos: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('Nenhum consumo encontrado.', style: TextStyle(color: Colors.white)));
              }

              final matriculas = snapshot.data!.docs;

              return ListView(
                children: matriculas.where((doc) {
                  var matriculaId = doc.id;
                  return _selectedMatricula == null || _selectedMatricula == matriculaId;
                }).expand((doc) {
                  return [
                    ListTile(
                      title: Text('Matrícula: ${doc.id}', style: TextStyle(color: Colors.white)),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: doc.reference.collection('registros').snapshots(),
                      builder: (context, consumoSnapshot) {
                        if (consumoSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (consumoSnapshot.hasError) {
                          return Center(child: Text('Erro ao carregar registros: ${consumoSnapshot.error}'));
                        }
                        if (!consumoSnapshot.hasData || consumoSnapshot.data!.docs.isEmpty) {
                          return ListTile(
                            title: Text('Nenhum registro encontrado', style: TextStyle(color: Colors.grey)),
                          );
                        }

                        return Column(
                          children: consumoSnapshot.data!.docs.map((consumo) {
                            var data = consumo.data() as Map<String, dynamic>?;
                            final nome = data?['nome'] ?? 'Nome indisponível';
                            final valor = data?['valor']?.toString() ?? 'Valor não informado';
                            final dataRegistro = data?['data'] is Timestamp
                                ? (data?['data'] as Timestamp).toDate().toString()
                                : 'Data não disponível';
                            return ListTile(
                              title: Text(nome, style: TextStyle(color: Colors.white)),
                              subtitle: Text(
                                'Valor: $valor\nData: $dataRegistro',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ];
                }).toList(),
              );
            },
          ),
          Center(child: Text('Conteúdo de Manutenção', style: TextStyle(color: Colors.white, fontSize: 18))),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_selectedMatricula != null)
            FloatingActionButton(
              onPressed: _removeFilter,
              backgroundColor: Colors.grey,
              child: Icon(Icons.clear, color: Colors.white),
              heroTag: 'removeFilter',
            ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _onAddButtonPressed,
            backgroundColor: Colors.red,
            child: Icon(Icons.add, color: Colors.white, size: 30),
            heroTag: 'add',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.filter_list), label: 'Filtro'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Matrículas'),
          BottomNavigationBarItem(icon: Icon(Icons.view_list), label: 'Ver Matrículas'),
        ],
      ),
    );
  }
}
