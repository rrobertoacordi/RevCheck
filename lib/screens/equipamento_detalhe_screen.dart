import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/equipamento.dart';

class EquipamentoDetalheScreen extends StatefulWidget {
  final Equipamento equipamento;

  const EquipamentoDetalheScreen({super.key, required this.equipamento});

  @override
  State<EquipamentoDetalheScreen> createState() =>
      _EquipamentoDetalheScreenState();
}

class _EquipamentoDetalheScreenState extends State<EquipamentoDetalheScreen> {
  List<Map<String, dynamic>> _compartimentos = [];

  @override
  void initState() {
    super.initState();
    _carregarCompartimentos();
  }

  Future<void> _carregarCompartimentos() async {
    if (widget.equipamento.id == null) return;

    final compData = await DatabaseHelper.instance
        .getCompartimentosPorEquipamento(widget.equipamento.id!);

    List<Map<String, dynamic>> listaCompleta = [];
    for (var c in compData) {
      final trocas = await DatabaseHelper.instance.getTrocasPorCompartimento(
        c['id'],
      );
      Map<String, dynamic> item = Map.from(c);
      if (trocas.isNotEmpty) {
        item['ultima_troca'] = trocas.first;
      }
      listaCompleta.add(item);
    }

    setState(() {
      _compartimentos = listaCompleta;
    });
  }

  // Método para confirmar e apagar o equipamento
  void _confirmarExclusaoEquipamento() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Equipamento'),
        content: Text(
          'Tem certeza que deseja apagar "${widget.equipamento.nome}"? Todos os filtros e histórico associados serão excluídos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (widget.equipamento.id != null) {
                await DatabaseHelper.instance.deleteEquipamento(
                  widget.equipamento.id!,
                );
              }
              if (mounted) {
                Navigator.of(ctx).pop(); // Fecha o Dialog
                Navigator.of(context).pop(
                  true,
                ); // Volta para a tela anterior notificando a exclusão
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _modalAdicionarFiltro() {
    final nomeFiltroController = TextEditingController();
    final codigoFiltroController = TextEditingController();
    final horometroInstalacaoController = TextEditingController(
      text: widget.equipamento.horometroAtual.toString(),
    );
    final intervaloController = TextEditingController();
    final obsController = TextEditingController();

    double proximaTrocaCalculada = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void calcularProximaTroca() {
              final double horometro =
                  double.tryParse(horometroInstalacaoController.text) ?? 0.0;
              final double intervalo =
                  double.tryParse(intervaloController.text) ?? 0.0;

              setModalState(() {
                proximaTrocaCalculada = horometro + intervalo;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Adicionar Filtro / Compartimento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nomeFiltroController,
                      decoration: const InputDecoration(
                        labelText:
                            'Compartimento / Local (ex: Motor, Transmissão)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: codigoFiltroController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo/Código do Filtro (ex: P550388)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: horometroInstalacaoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Horômetro da Instalação (Horas)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => calcularProximaTroca(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: intervaloController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Intervalo para Troca (Horas ex: 250)',
                        suffixText: 'hrs',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => calcularProximaTroca(),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Próxima Troca (Horômetro Alvo):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            Text(
                              '${proximaTrocaCalculada.toStringAsFixed(1)} hrs',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: obsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (nomeFiltroController.text.isEmpty ||
                            codigoFiltroController.text.isEmpty) {
                          return;
                        }

                        final compId = await DatabaseHelper.instance
                            .insertCompartimento({
                              'equipamento_id': widget.equipamento.id,
                              'nome': nomeFiltroController.text,
                            });

                        await DatabaseHelper.instance.insertTrocaFiltro({
                          'compartimento_id': compId,
                          'codigo_filtro': codigoFiltroController.text,
                          'horas_trocadas':
                              double.tryParse(
                                horometroInstalacaoController.text,
                              ) ??
                              0.0,
                          'proxima_troca': proximaTrocaCalculada,
                          'data_troca': DateTime.now().toIso8601String().split(
                            'T',
                          )[0],
                          'observacao': obsController.text,
                        });

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        _carregarCompartimentos();
                      },
                      child: const Text('Salvar Filtro'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.equipamento.codigo} - ${widget.equipamento.nome}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir Equipamento',
            onPressed: _confirmarExclusaoEquipamento,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Horômetro Atual do Maquinário:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${widget.equipamento.horometroAtual} hrs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _compartimentos.isEmpty
                ? const Center(
                    child: Text('Nenhum filtro/compartimento cadastrado.'),
                  )
                : ListView.builder(
                    itemCount: _compartimentos.length,
                    itemBuilder: (context, index) {
                      final item = _compartimentos[index];
                      final ultimaTroca = item['ultima_troca'];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          title: Text(
                            item['nome'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: ultimaTroca != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Filtro: ${ultimaTroca['codigo_filtro']}',
                                    ),
                                    Text(
                                      'Instalado em: ${ultimaTroca['horas_trocadas']} hrs (${ultimaTroca['data_troca']})',
                                    ),
                                    if (ultimaTroca['proxima_troca'] != null)
                                      Text(
                                        'Próxima Troca: ${ultimaTroca['proxima_troca']} hrs',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    if (ultimaTroca['observacao'] != null &&
                                        ultimaTroca['observacao']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                        'Obs: ${ultimaTroca['observacao']}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                )
                              : const Text('Sem registros de troca'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteCompartimento(
                                item['id'],
                              );
                              _carregarCompartimentos();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _modalAdicionarFiltro,
        icon: const Icon(Icons.filter_alt),
        label: const Text('Adicionar Filtro'),
      ),
    );
  }
}
