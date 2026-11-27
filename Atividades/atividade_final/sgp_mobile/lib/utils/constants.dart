import 'package:flutter_dotenv/flutter_dotenv.dart';

// Constantes globais, nomes de coleções, papéis e configurações do SGP Mobile.
class AppConstants {
  // Impede instanciação direta desta classe utilitária.
  AppConstants._();

  // Nome da aplicação exibido em títulos e cabeçalhos.
  static const String appName = 'SGP Mobile';

  // Subtítulo institucional exibido na tela de login e menu lateral.
  static const String appSubtitle = 'CPPT • Ministério Público do Piauí';

  // Largura máxima recomendada para centralização do layout na Web.
  static const double maxWebContentWidth = 900.0;

  // --- Nomes das coleções no Cloud Firestore ---
  static const String colProfiles = 'profiles';
  static const String colDemandas = 'demandas';
  static const String colComentarios = 'comentarios';
  static const String colHistorico = 'historico';
  static const String colViagens = 'viagens';
  static const String colNotificacoes = 'notificacoes';

  // --- Papéis de usuário (roles) ---
  static const String rolePendente = 'pendente';
  static const String roleServidor = 'servidor';
  static const String roleCoordenacao = 'coordenacao';
  static const String roleAdministrador = 'administrador';

  // Lista de papéis selecionáveis na aprovação de usuários.
  static const List<String> rolesAprovaveis = [
    roleServidor,
    roleCoordenacao,
    roleAdministrador,
  ];

  // Lotações/Assessorias técnicas disponíveis na CPPT/MPPI.
  static const List<String> lotacoesDisponiveis = [
    'CPPT',
    'ARQ',
    'CONT',
    'CONV',
    'ENG',
    'PSI',
  ];

  // Mapa de siglas para nomes completos das lotações/setores.
  static const Map<String, String> lotacoesNomes = {
    'CPPT': 'Coordenadoria de Perícias e Pareceres Técnicos',
    'ARQ': 'Assessoria de Arquitetura',
    'CONT': 'Assessoria de Contabilidade',
    'CONV': 'Assessoria de Convênios',
    'ENG': 'Assessoria de Engenharia Civil',
    'PSI': 'Assessoria de Psicologia',
  };

  // Lista de avatares locais disponíveis em `assets/images/` para o perfil.
  static const List<String> avatarAssets = [
    'assets/images/avatar_1.png',
    'assets/images/avatar_2.png',
    'assets/images/avatar_3.png',
    'assets/images/avatar_4.png',
    'assets/images/avatar_5.png',
    'assets/images/avatar_6.png',
    'assets/images/avatar_7.png',
    'assets/images/avatar_8.png',
    'assets/images/avatar_9.png',
    'assets/images/avatar_10.png',
  ];

  // Siglas das Unidades Federativas brasileiras para formulários de endereço.
  static const List<String> estadosBrasileiros = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  // --- Status de Demanda ---
  static const String statusNaoIniciada = 'nao_iniciada';
  static const String statusEmAndamento = 'em_andamento';
  static const String statusPausada = 'pausada';
  static const String statusConcluida = 'concluida';

  // --- Prioridades de Demanda ---
  static const String prioridadeAlta = 'alta';
  static const String prioridadeNormal = 'normal';
  static const String prioridadeBaixa = 'baixa';

  // --- Situações de Viagem ---
  static const String viagemAgendada = 'agendada';
  static const String viagemEmAndamento = 'em_andamento';
  static const String viagemConcluida = 'concluida';
  static const String viagemCancelada = 'cancelada';

  static const List<String> situacoesViagem = [
    viagemAgendada,
    viagemEmAndamento,
    viagemConcluida,
    viagemCancelada,
  ];

  // Coordenadas padrão (Teresina - PI) usadas quando o GPS ainda não respondeu.
  static const double defaultLat = -5.0892;
  static const double defaultLng = -42.8019;

  // Lê o e-mail do Administrador Master a partir do `.env` (sem hardcode).
  static String get adminMasterEmail =>
      (dotenv.env['ADMIN_MASTER_EMAIL'] ?? '').trim().toLowerCase();

  // Lê a chave da API do Google Maps a partir do `.env`.
  static String get googleMapsApiKey =>
      (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '').trim();
}
