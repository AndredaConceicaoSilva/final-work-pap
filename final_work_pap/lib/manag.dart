import 'package:flutter/material.dart';

class Manag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manutenção'),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Página de Mação',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
