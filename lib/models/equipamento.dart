class Equipamento {
  final int? id;
  final String nome;
  final String codigo;
  final String? modelo;
  final double horometroAtual;

  Equipamento({
    this.id,
    required this.nome,
    required this.codigo,
    this.modelo,
    this.horometroAtual = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'codigo': codigo,
      'modelo': modelo,
      'horometro_atual': horometroAtual,
    };
  }

  factory Equipamento.fromMap(Map<String, dynamic> map) {
    return Equipamento(
      id: map['id'],
      nome: map['nome'],
      codigo: map['codigo'],
      modelo: map['modelo'],
      horometroAtual: (map['horometro_atual'] as num).toDouble(),
    );
  }
}
