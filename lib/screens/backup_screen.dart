import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _carregando = false;
  String _mensagemStatus = '';

  Future<void> _fazerBackup() async {
    setState(() {
      _carregando = true;
      _mensagemStatus = 'Gerando backup...';
    });

    try {
      final jsonString = await DatabaseHelper.instance.exportarParaJson();

      // Obtém a pasta Documentos/Downloads do dispositivo
      Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/revcheck_backup.json');
      await file.writeAsString(jsonString);

      setState(() {
        _mensagemStatus = 'Backup salvo com sucesso em:\n${file.path}';
      });
    } catch (e) {
      setState(() {
        _mensagemStatus = 'Erro ao salvar backup: $e';
      });
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _restaurarBackup() async {
    setState(() {
      _carregando = true;
      _mensagemStatus = 'Procurando arquivo de backup...';
    });

    try {
      Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/revcheck_backup.json');

      if (!await file.exists()) {
        setState(() {
          _mensagemStatus =
              'Arquivo revcheck_backup.json não encontrado na pasta do app.';
        });
        return;
      }

      final jsonString = await file.readAsString();
      await DatabaseHelper.instance.importarDeJson(jsonString);

      setState(() {
        _mensagemStatus = 'Dados restaurados com sucesso!';
      });
    } catch (e) {
      setState(() {
        _mensagemStatus = 'Erro ao restaurar backup: $e';
      });
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e Restauração')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Exportar Backup (Salvar JSON)'),
              onPressed: _carregando ? null : _fazerBackup,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Importar Backup (Restaurar JSON)'),
              onPressed: _carregando ? null : _restaurarBackup,
            ),
            const SizedBox(height: 24),
            if (_carregando) const Center(child: CircularProgressIndicator()),
            Text(
              _mensagemStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
