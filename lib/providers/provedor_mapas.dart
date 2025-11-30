// lib/providers/provedor_mapas.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Serviço utilitário para abrir localizações externas (Google Maps).
class ServicoMapas {
  
  /// Dicionário de locais mapeados da UFSCar Sorocaba.
  /// As chaves são os nomes usados no app, e os valores são "Plus Codes"
  /// ou endereços pesquisáveis para garantir precisão no GPS.
  final Map<String, String> _dicionarioLocais = {
    'ATLab': 'CF9F+99P Sorocaba, São Paulo',
    'AT2': 'CF9F+5J Sorocaba, São Paulo',
    'CCHB': 'CF9F+8X Sorocaba, São Paulo',
    'CCTS': 'CF8F+PR Sorocaba, São Paulo',
    'CCGT': 'CF8F+XM Sorocaba, São Paulo',
    'FINEP 1': 'CF9F+GX9 Sorocaba, São Paulo',
    'FINEP 2': 'CF8F+GM Sorocaba, São Paulo',
  };

  /// Tenta abrir o aplicativo de mapas nativo do celular com o endereço do prédio.
  ///
  /// [predio]: Nome do prédio (ex: 'ATLab'). Se não for encontrado no dicionário,
  /// tenta buscar pelo nome + "UFSCar Sorocaba".
  Future<void> abrirLocalizacao(String predio) async {
    // Busca o código exato ou cria uma query genérica
    String query = _dicionarioLocais[predio] ?? '$predio UFSCar Sorocaba';
    
    // Codifica a string para ser usada em URL (ex: espaços viram %20)
    final String queryCodificada = Uri.encodeComponent(query);
    
    // Constrói a URL universal do Google Maps
    final Uri urlGoogleMaps = Uri.parse("https://www.google.com/maps/search/?api=1&query=$queryCodificada");
    
    // Verifica se o dispositivo pode abrir a URL e executa
    if (await canLaunchUrl(urlGoogleMaps)) {
      await launchUrl(urlGoogleMaps, mode: LaunchMode.externalApplication);
    } else {
      throw 'Não foi possível abrir o aplicativo de mapas.';
    }
  }
}

/// Provedor global para acessar o serviço de mapas.
final provedorMapas = Provider<ServicoMapas>((ref) {
  return ServicoMapas();
});