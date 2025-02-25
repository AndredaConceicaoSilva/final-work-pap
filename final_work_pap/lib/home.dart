import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'matriculas.dart';
import 'consumos.dart';
import 'view_matr.dart';
import 'manag.dart';

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

  void _showMatriculaSelectionDialog({bool goToConsumo = false, bool goToManutencao = false}) async {
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
            backgroundColor: Colors.grey[800],
            title: Text('Selecione a Matrícula', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                children: matriculas.map((matricula) {
                  return ListTile(
                    title: Text(matricula, style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        _selectedMatricula = matricula;
                      });
                      Navigator.pop(context);
                      
                      if (goToConsumo) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Consumos(matricula: _selectedMatricula!),
                          ),
                        ).then((_) {
                          setState(() {
                            _selectedMatricula = null;
                          });
                        });
                      } else if (goToManutencao) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Manag(matricula: _selectedMatricula!),
                          ),
                        ).then((_) {
                          setState(() {
                            _selectedMatricula = null;
                          });
                        });
                      }
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
      _selectedMatricula = null; // Limpa a matrícula selecionada
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filtro removido.')),
    );
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
        actions: [
          if (_selectedMatricula != null) // Verifica se há um filtro ativo
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _removeFilter, // Chamando a função para remover o filtro
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: TabBarView(
        controller: _tabController,
        children: [
          // ✅ CONSUMOS TAB
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
                            var data = consumo.data() as Map<String, dynamic>;
                            var dataAbastecimentoValue = data['data_de_abastecimento'];
                            final dataAbastecimento = dataAbastecimentoValue is Timestamp
                                ? DateFormat('dd/MM/yyyy').format(dataAbastecimentoValue.toDate())
                                : 'Data não disponível';
                            final quilometragem = data['quilometragem']?.toString() ?? 'Quilometragem não informada';
                            final litrosAbastecidos = data['litros_abastecidos']?.toString() ?? 'Litros não informados';
                            final custo = data['custo']?.toString() ?? 'Custo não informado';

                            return ListTile(
                              title: Text('Data: $dataAbastecimento', style: TextStyle(color: Colors.white)),
                              subtitle: Text(
                                'Quilometragem: $quilometragem\nLitros: $litrosAbastecidos\nCusto: € $custo',
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

          // ✅ MANUTENÇÃO TAB
          Center(child: Text('Conteúdo de Manutenção', style: TextStyle(color: Colors.white, fontSize: 18))),
        ],
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomCenter, // Para centralizar os botões
        children: [
          // Botão para remover filtro
          if (_selectedMatricula != null) // Botão aparece apenas se há um filtro ativo
            Positioned(
              bottom: 80, // Ajusta a posição do botão para cima do botão de adicionar
              child: FloatingActionButton(
                onPressed: _removeFilter,
                backgroundColor: Colors.blue, // Cor azul para o botão de remover filtro
                child: Icon(Icons.clear, color: Colors.white), // Ícone para remover filtro
              ),
            ),
          // Botão de adicionar
          FloatingActionButton(
            onPressed: () {
              if (_tabController.index == 0) {
                _showMatriculaSelectionDialog(goToConsumo: true);
              } else {
                _showMatriculaSelectionDialog(goToManutencao: true);
              }
            },
            backgroundColor: Colors.red, // Cor vermelha para o botão de adicionar
            child: Icon(Icons.add, color: Colors.white, size: 30),
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
