# SGP Mobile — Sistema de Gestão de Perícias (CPPT/MPPI)

Aplicativo multiplataforma desenvolvido em **Flutter** para apoiar a operação de campo dos servidores/peritos e gestores da **Coordenadoria de Perícias e Pareceres Técnicos (CPPT)** do Ministério Público do Estado do Piauí (MPPI).

> **Contexto Acadêmico:** Projeto final da disciplina de **Programação para Dispositivos Móveis**, ministrada pelo **Professor Otílio Paulo**, do curso de **Análise e Desenvolvimento de Sistemas (ADS)** do **IFPI — Campus Central, Teresina/PI**.
>
> **Data:** 27/11/2026

---

## Plataformas Suportadas

- **Android** (Mobile)
- **Flutter Web** (Ambiente de testes em navegador)

*(iOS e desktop não são alvos deste projeto.)*

---

## Principais Funcionalidades

- **Autenticação e Controle de Acesso (`AuthGate`):**
  - Login com E-mail/Senha, Cadastro de novos usuários, Recuperação de Senha e Login Social com **Google**.
  - Provisionamento automático (*bootstrap*) do **Administrador Master** (`ADMIN_MASTER_EMAIL` configurado no `.env`).
  - Novos cadastros iniciam como `pendente` (`ativo: false`) na tela **Aguardando Autorização da Coordenação**.
- **Gestão de Usuários e Perfis:**
  - Validação e edição opcional dos dados cadastrais (`Nome`, `E-mail`, `Matrícula`, `Cargo`) pelo Administrador/Coordenação.
  - Atribuição de papel (`servidor`, `coordenacao`, `administrador`) e lotação (`CPPT`, `ARQ`, `CONT`, `CONV`, `ENG`, `PSI`) com nome completo.
  - Exclusão de contas controlada (somente Administrador pode excluir Coordenação).
  - Edição de perfil, escolha de avatar local (`assets/images/`) e alteração de senha.
- **Gestão de Demandas Periciais:**
  - Cadastro com máscara de **Número SGP** (`0001234/2026-ENG`), máscara de **Número SEI** (`00.00.0000.0000000/xxxx-00`), endereço completo e status inicial `Não Iniciada`.
  - Filtros (*Todas*, *Demandas do Setor*, *Não Iniciadas*, *Em Andamento*, *Pausadas*, *Concluídas*) e busca textual.
  - Botão **Iniciar** disponível exclusivamente para servidores da lotação de destino.
  - Pausa obrigatória com justificativa, comentários com controle de autoria/gestão, linha do tempo automática (`historico`), desvínculo e exclusão controlada.
- **Viagens, Mapas e Rotas:**
  - Cadastro de viagens vinculadas a múltiplas demandas e múltiplos servidores, preenchendo automaticamente os endereços das demandas selecionadas (suportando múltiplas cidades).
  - Mapa Geral interativo com marcadores das demandas (`google_maps_flutter`).
  - Busca de coordenadas por endereço (`geocoding`) e seletor interativo no mapa (`MapPickerView` com geocodificação reversa).
  - Cálculo e traçado de rotas no app com `google_maps_routes` e fallback geodésico.
- **Notificações In-App:**
  - Sino de notificações em tempo real na barra superior (`Cloud Firestore`) com contador de não lidas e tela dedicada (`NotificacoesView`).

---

## Arquitetura e Stack Tecnológica

- **Padrão:** MVC / MVVM com gerenciamento de estado reativo via `provider` (`models/`, `views/`, `controllers/`, `services/`, `utils/`).
- **Backend (BaaS):** `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`.
- **Mapas e Localização:** `google_maps_flutter`, `google_maps_routes`, `geolocator`, `geocoding`, `http`.
- **Configuração e Formatação:** `flutter_dotenv`, `intl`, `material_ui`.

---

## Como Configurar e Executar

### 1. Pré-requisitos
- Flutter SDK instalado e configurado no `PATH`
- Projeto Firebase configurado (`lib/firebase_options.dart` e `android/app/google-services.json`)
- Chave de API do Google Maps (com Maps SDK for Android, Maps JavaScript API, Geocoding API e Directions API)

### 2. Variáveis de Ambiente (`.env`)
Crie o arquivo `.env` na raiz a partir do modelo `.env.example`:

```bash
cp .env.example .env
```

Preencha `ADMIN_MASTER_EMAIL`, `GOOGLE_MAPS_API_KEY` e as chaves do Firebase no `.env`.
Na versão Web, informe também sua chave no `<script>` do Google Maps em `web/index.html`.

### 3. Regras do Cloud Firestore
Publique o conteúdo do arquivo `firestore.rules` na aba **Firestore Database → Regras** do Firebase Console.

### 4. Instalar Dependências e Rodar

```bash
flutter pub get

# Executar na Web (Chrome)
flutter run -d chrome

# Executar no Android (dispositivo/emulador conectado)
flutter run
```

### 5. Análise Estática e Testes

```bash
flutter analyze
flutter test
```

---

## Documentação Complementar

- `REQUISITOS.md` — Especificação completa de requisitos funcionais e não funcionais.

