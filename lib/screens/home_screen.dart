import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/equipamento.dart';
import 'equipamento_detalhe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Equipamento> _equipamentos = [];

  @override
  void initState() {
    super.initState();
    _carregarEquipamentos();
  }

  Future<void> _carregarEquipamentos() async {
    final data = await DatabaseHelper.instance.getEquipamentos();
    setState(() {
      _equipamentos = data.map((e) => Equipamento.fromMap(e)).toList();
    });
  }

  void _abrirFormularioModal() {
    final nomeController = TextEditingController();
    final codigoController = TextEditingController();
    final horometroController = TextEditingController(text: '0.0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Novo Maquinário',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome/Descrição (ex: Trator Valtra)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codigoController,
              decoration: const InputDecoration(
                labelText: 'Código / Frota (ex: TR-01)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: horometroController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Horômetro Atual (Horas)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isEmpty ||
                    codigoController.text.isEmpty) {
                  return;
                }

                final novo = Equipamento(
                  nome: nomeController.text,
                  codigo: codigoController.text,
                  horometroAtual:
                      double.tryParse(horometroController.text) ?? 0.0,
                );

                await DatabaseHelper.instance.insertEquipamento(novo.toMap());
                Navigator.of(context).pop();
                _carregarEquipamentos();
              },
              child: const Text('Salvar Equipamento'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RevCheck - Maquinários')),
      body: _equipamentos.isEmpty
          ? const Center(child: Text('Nenhum equipamento cadastrado.'))
          : ListView.builder(
              itemCount: _equipamentos.length,
              itemBuilder: (context, index) {
                final item = _equipamentos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.precision_manufacturing,
                      size: 36,
                      color: Colors.blue,
                    ),
                    title: Text(
                      '${item.codigo} - ${item.nome}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Horômetro Atual: ${item.horometroAtual} hrs',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EquipamentoDetalheScreen(equipamento: item),
                        ),
                      );
                      _carregarEquipamentos();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormularioModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
