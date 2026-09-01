import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/equipamento.dart';
import '../services/notification_service.dart';

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
      // Busca também se já existe lembrete para este compartimento específico
      final lembretes = await DatabaseHelper.instance
          .getLembretesPorCompartimento(c['id']);

      Map<String, dynamic> item = Map.from(c);
      if (trocas.isNotEmpty) {
        item['ultima_troca'] = trocas.first;
      }
      item['lembretes'] = lembretes;
      listaCompleta.add(item);
    }

    if (!mounted) return;
    setState(() {
      _compartimentos = listaCompleta;
    });
  }

  // AGORA O LEMBRETE É AGENDADO PARA UM COMPARTIMENTO ESPECÍFICO
  Future<void> _agendarLembreteCompartimento(
    Map<String, dynamic> compartimento,
  ) async {
    final DateTime agora = DateTime.now();

    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: agora.add(const Duration(days: 1)),
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 365 * 5)),
      helpText:
          'DATA DA REVISÃO - ${compartimento['nome'].toString().toUpperCase()}',
      locale: const Locale('pt', 'BR'),
    );

    if (dataSelecionada == null) return;

    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'HORA DO LEMBRETE',
    );

    if (horaSelecionada == null) return;

    final obsController = TextEditingController();
    final bool? confirmouObs = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Observação - ${compartimento['nome']}'),
        content: TextField(
          controller: obsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ex: Troca de óleo e elemento filtrante',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Agendar'),
          ),
        ],
      ),
    );

    if (confirmouObs != true) return;

    final DateTime dataHoraFinal = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      dataSelecionada.day,
      horaSelecionada.hour,
      horaSelecionada.minute,
    );

    // Salva no banco relacionando com o compartimento
    final lembreteId = await DatabaseHelper.instance
        .insertLembreteCompartimento(
          equipamentoId: widget.equipamento.id!,
          compartimentoId: compartimento['id'],
          dataHora: dataHoraFinal.toIso8601String(),
          observacao: obsController.text,
        );

    // Notificação exibe o Equipamento + Compartimento
    final textoNotificacao =
        '${widget.equipamento.nome} (${compartimento['nome']}): ${obsController.text}';

    await NotificationService().agendarNotificacaoEquipamento(
      id: lembreteId,
      nomeEquipamento: textoNotificacao,
      dataHora: dataHoraFinal,
    );

    await _carregarCompartimentos();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lembrete agendado para ${compartimento['nome']}!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removerLembrete(int lembreteId) async {
    await DatabaseHelper.instance.deleteLembrete(lembreteId);
    await NotificationService().cancelarNotificacao(lembreteId);
    await _carregarCompartimentos();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lembrete removido!')));
    }
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

                        await _carregarCompartimentos();

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
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
                      final List lembretes = item['lembretes'] ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['nome'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // Botão de agendar lembrete específico deste filtro
                                      IconButton(
                                        icon: Icon(
                                          lembretes.isNotEmpty
                                              ? Icons.alarm_on
                                              : Icons.add_alarm,
                                          color: lembretes.isNotEmpty
                                              ? Colors.amber.shade700
                                              : Colors.grey,
                                        ),
                                        tooltip:
                                            'Agendar Lembrete para este filtro',
                                        onPressed: () =>
                                            _agendarLembreteCompartimento(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await DatabaseHelper.instance
                                              .deleteCompartimento(item['id']);
                                          _carregarCompartimentos();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(),
                              if (ultimaTroca != null) ...[
                                Text('Filtro: ${ultimaTroca['codigo_filtro']}'),
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
                              ] else
                                const Text('Sem registros de troca'),

                              // Se houver lembrete para este compartimento, mostra um mini card
                              if (lembretes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...lembretes.map((l) {
                                  final dt = DateTime.parse(l['data_hora']);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.alarm,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Lembrete: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              _removerLembrete(l['id']),
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
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
