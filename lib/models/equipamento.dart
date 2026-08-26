class Equipamento {
  final int? id;
  final String codigo;
  final String nome;
  final double horometroAtual;
  final String? lembreteData;
  final String? lembreteObs;

  Equipamento({
    this.id,
    required this.codigo,
    required this.nome,
    required this.horometroAtual,
    this.lembreteData,
    this.lembreteObs,
  });

  // Converter do Banco (Map) para Objeto Dart
  factory Equipamento.fromMap(Map<String, dynamic> map) {
    return Equipamento(
      id: map['id'] as int?,
      codigo: map['codigo'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      horometroAtual: (map['horometro_atual'] as num?)?.toDouble() ?? 0.0,
      lembreteData: map['lembrete_data'] as String?,
      lembreteObs: map['lembrete_obs'] as String?,
    );
  }

  // Converter de Objeto Dart para Banco (Map)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nome': nome,
      'horometro_atual': horometroAtual,
      'lembrete_data': lembreteData,
      'lembrete_obs': lembreteObs,
    };
  }
}
