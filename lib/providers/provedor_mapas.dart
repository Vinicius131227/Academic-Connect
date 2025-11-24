// lib/providers/provedor_mapas.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicoMapas {
  
  // Dicionário atualizado com Plus Codes exatos da UFSCar Sorocaba
  final Map<String, String> _dicionarioLocais = {
    'ATLab': 'CF9F+99P Sorocaba, São Paulo',
    'AT2': 'CF9F+5J Sorocaba, São Paulo',
    'CCHB': 'CF9F+8X Sorocaba, São Paulo',
    'CCTS': 'CF8F+PR Sorocaba, São Paulo',
    'CCGT': 'CF8F+XM Sorocaba, São Paulo',
    'FINEP 1': 'CF9F+GX9 Sorocaba, São Paulo',
    'FINEP 2': 'CF8F+GM Sorocaba, São Paulo',
  };

  Future<void> abrirLocalizacao(String predio) async {
    // Tenta encontrar o código exato, senão usa o nome do prédio + UFSCar
    String query = _dicionarioLocais[predio] ?? '$predio UFSCar Sorocaba';
    
    // Remove espaços extras e formata para URL
    final String queryCodificada = Uri.encodeComponent(query);
    
    // URLs universais que funcionam em Android e iOS
    final Uri urlGoogleMaps = Uri.parse("https://www.google.com/maps/search/?api=1&query=$queryCodificada");
    
    // Tenta abrir
    if (await canLaunchUrl(urlGoogleMaps)) {
      await launchUrl(urlGoogleMaps, mode: LaunchMode.externalApplication);
    } else {
      throw 'Não foi possível abrir o app de mapas.';
    }
  }
}

final provedorMapas = Provider<ServicoMapas>((ref) {
  return ServicoMapas();
});