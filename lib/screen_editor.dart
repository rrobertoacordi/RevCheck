import 'package:flutter/material.dart';

import '../theme_notifier.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  final List<Color> coresDisponiveis = const [
    Colors.blue,
    Colors.green,
    Colors.amber,
    Colors.red,
    Colors.orange,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personalização')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Opção Modo Escuro
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeMode,
            builder: (context, mode, _) {
              return SwitchListTile(
                title: const Text('Modo Escuro'),
                subtitle: const Text('Ideal para uso noturno'),
                value: mode == ThemeMode.dark,
                onChanged: (isDark) => AppTheme.alternarTema(isDark),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'Cor do Aplicativo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Paleta de Cores
          ValueListenableBuilder<Color>(
            valueListenable: AppTheme.primaryColor,
            builder: (context, corAtual, _) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: coresDisponiveis.map((cor) {
                  final isSelected = corAtual.value == cor.value;
                  return GestureDetector(
                    onTap: () => AppTheme.mudarCor(cor),
                    child: CircleAvatar(
                      backgroundColor: cor,
                      radius: 24,
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
