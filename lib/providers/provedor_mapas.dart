// lib/providers/provedor_mapas.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicoMapas {
  
  final Map<String, String> _dicionarioLocais = {
    'ATLab': 'CF9F+99P Sorocaba, São Paulo',
    'AT1': 'CF9F+5J Sorocaba, São Paulo',
    'AT2': 'CF9F+5J Sorocaba, São Paulo',
    'CCHB': 'CF9F+8X Sorocaba, São Paulo',
    'CCTS': 'CF8F+PR Sorocaba, São Paulo',
    'CCGT': 'CF8F+XM Sorocaba, São Paulo',
    'FINEP 1': 'CF9F+GX9 Sorocaba, São Paulo',
    'FINEP 2': 'CF8F+GM Sorocaba, São Paulo',
  };

  Future<void> abrirLocalizacao(String predio) async {
    // 1. Define a busca
    String query = _dicionarioLocais[predio] ?? '$predio UFSCar Sorocaba';
    
    // 2. Codifica para URL
    final String queryCodificada = Uri.encodeComponent(query);
    
    // 3. URL Universal do Google Maps (Funciona em Android e iOS)
    final Uri urlMaps = Uri.parse("https://www.google.com/maps/search/?api=1&query=$queryCodificada");

    // 4. Tenta abrir
    if (await canLaunchUrl(urlMaps)) {
      await launchUrl(
        urlMaps, 
        mode: LaunchMode.externalApplication // Força abrir fora do app (no Maps ou Browser)
      );
    } else {
      throw 'Não foi possível abrir o mapa para: $predio';
    }
  }
}

final provedorMapas = Provider<ServicoMapas>((ref) {
  return ServicoMapas();
});