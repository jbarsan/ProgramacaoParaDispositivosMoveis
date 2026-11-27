# Documento de Especificação de Requisitos — SGP Mobile (CPPT/MPPI)

| Metadado | Descrição |
| :--- | :--- |
| **Projeto** | **SGP Mobile — Sistema de Gestão de Perícias** |
| **Contexto** | Projeto Final — Disciplina de Programação para Dispositivos Móveis |
| **Instituição Referência** | Ministério Público do Estado do Piauí (MPPI) — CPPT |
| **Plataforma Alvo** | Android (Mobile) e Web (Ambiente de testes em notebook) |
| **Data de Atualização** | 27/11/2026 |

---

> 🤖 **INSTRUÇÃO PARA O AGENTE DE IA:** Antes de gerar código, configurar o ambiente ou iniciar qualquer tarefa neste projeto, leia obrigatoriamente o arquivo **`AGENTS.md`** (e os guias técnicos complementares referenciados nele) para seguir a arquitetura, as regras de segurança do Firebase e os padrões de código definidos.

---

## 1. Visão Geral e Recorte Estratégico

O **SGP Mobile** é uma versão enxuta, focada e operacional do Sistema de Gestão de Perícias (SGP) da Coordenadoria de Perícias e Pareceres Técnicos (CPPT/MPPI). O objetivo deste recorte é atender integralmente aos critérios acadêmicos da disciplina de **Programação para Dispositivos Móveis**, focando nas operações de campo dos servidores/peritos: acompanhamento de demandas, interação por comentários, controle de pausas e **mapeamento inteligente de viagens com rotas via Google Maps**.

### 1.1. Escopo Incluído

* **Incluído (Foco Android e Web para testes):** Autenticação completa (E-mail/Senha e Google), fluxo de provisionamento do Administrador Master (`administrador@sgp.com.br`), aprovação de novos usuários pelo Administrador/Coordenador com validação e edição opcional dos dados cadastrais, perfil do servidor com seleção de avatar local (`assets/images/`) e alteração de senha, navegação híbrida (`Drawer` + `BottomNavigationBar`), cadastro/listagem/detalhes de demandas com endereço completo e máscara SEI, pausa/retomada com justificativa, comentários e histórico de movimentações, gestão de viagens com múltiplos destinos preenchidos a partir das demandas e integração total com Google Maps (marcadores, busca de endereços, seleção interativa de ponto no mapa com geocodificação reversa e rotas).

---

## 2. Identidade Visual e Design (UI/UX)

O aplicativo deve seguir uma interface **Clean UX** (minimalista, intuitiva e de alto contraste), respeitando a identidade visual institucional do MPPI:

* **Cor Primária (Vermelho Institucional MPPI):** `#8E1919` (utilizada em AppBars, cabeçalho do Drawer, botões principais, destaques ativos e marcadores prioritários).
* **Cor Primária Variante (Escura/Hover):** `#6B1212`
* **Cores Neutras e Auxiliares:**
  * **Fundo Principal (Surface/Background):** `#FFFFFF` (Branco puro) e `#F8F9FA` (Cinza gelo suave para cartões e separadores).
  * **Textos e Ícones Principais:** `#121212` (Preto carvão para leitura confortável) e `#5F6368` (Cinza médio para subtítulos e metadados).
  * **Semântica de Status:** Verde (`#2E7D32`) para *Concluída*, Âmbar (`#ED6C02`) para *Pausada*, Azul (`#0288D1`) para *Em Andamento* e Vermelho (`#D32F2F`) para *Prioridade Alta / Atrasada*.

---

## 3. Perfis de Acesso Simplificados e Controle de Liberação

Para o ambiente mobile/web, os perfis seguem o fluxo de segurança institucional com liberação controlada e inicialização segura:

1. **Administrador Master (`administrador` / `ativo: true`):** Conta inicial (`administrador@sgp.com.br`, configurada via `.env`) que já nasce ativa no primeiro login para realizar o *bootstrap* do sistema, aprovando os primeiros Coordenadores e Servidores e atribuindo suas lotações. Possui acesso irrestrito.
2. **Coordenação (`coordenacao` / `ativo: true`):** Visualiza todas as demandas e viagens, pode aprovar novos usuários cadastrados definindo seu papel (`servidor` ou `coordenacao`) e vinculando-os ao setor/assessoria correspondente, além de criar demandas/viagens, atribuir servidores e editar/excluir qualquer comentário.
3. **Servidor / Perito (`servidor` / `ativo: true`):** Visualiza as demandas e viagens vinculadas a si e à sua lotação, atualiza status, pausa/despausa demandas, insere comentários (podendo editar/excluir apenas os próprios) e consulta rotas no mapa.
4. **Pendente (`pendente` / `ativo: false`):** Estado padrão de qualquer outro usuário recém-cadastrado (via e-mail/senha ou Google). Não possui acesso aos dados do banco (demandas, viagens ou mapas) e visualiza exclusivamente a tela de **Aguardando Aprovação**.

---

## 4. Requisitos Funcionais (RF)

### 4.1. Módulo de Autenticação, Aprovação, Perfil e Navegação
* **RF-001 — Login, Cadastro e Bootstrap Administrativo:** Permitir autenticação via E-mail e Senha, além de tela para criação de nova conta (informando Nome completo, E-mail institucional, Matrícula, Cargo e Senha). Todo novo cadastro comum é criado com status `ativo = false` e papel `pendente`. Caso o login ocorra com o e-mail definido em `ADMIN_MASTER_EMAIL` (`administrador@sgp.com.br`), o sistema provisiona automaticamente seu perfil como `role = "administrador"` e `ativo = true` no primeiro acesso.
* **RF-002 — Recuperação de Senha:** Permitir envio de e-mail para redefinição de senha via Firebase Authentication.
* **RF-003 — Login Social:** Permitir autenticação rápida utilizando conta **Google** (criando o perfil como `pendente` no primeiro acesso).
* **RF-004 — Fluxo de Aprovação e Tela de Espera:**
  * Caso um usuário autenticado possua `ativo == false` ou `role == "pendente"`, o aplicativo deve bloquear o acesso às abas operacionais e exibir a tela **"Aguardando Autorização da Coordenação"** (com opção de atualizar status ou fazer logout).
  * Disponibilizar aos perfis **Administrador** e **Coordenação** uma tela de **Gestão de Usuários** exibindo todos os dados preenchidos no cadastro (`Nome`, `E-mail`, `Matrícula`, `Cargo` e `Data de cadastro`) já pré-preenchidos para validação (com edição opcional se necessário), permitindo aprovar o acesso (`ativo = true`), definir o papel (`servidor`, `coordenacao` ou `administrador`), excluir contas de usuários (exceto a própria conta e o Administrador Master; somente o Administrador pode excluir contas de Coordenação) e vincular a lotação exibida com sigla e nome completo (truncável em espaços compactos):
    * `CPPT` — Coordenadoria de Perícias e Pareceres Técnicos;
    * `ARQ` — Assessoria de Arquitetura;
    * `CONT` — Assessoria de Contabilidade;
    * `CONV` — Assessoria de Convênios;
    * `ENG` — Assessoria de Engenharia Civil;
    * `PSI` — Assessoria de Psicologia.
* **RF-005 — Menu Lateral de Perfil do Servidor (`Drawer`):** Exibir um menu lateral com cabeçalho institucional (`#8E1919`) apresentando o avatar do servidor (imagem local ou foto da conta Google), Nome completo, Matrícula, Lotação/Assessoria (sigla + nome completo), Cargo e Papel no sistema, além de atalhos para edição de perfil/senha, gestão de usuários (apenas Administrador/Coordenação) e encerramento de sessão (Logout).
* **RF-006 — Perfil, Seleção de Avatar Local e Alteração de Senha:** Permitir que o usuário edite seus dados pessoais (`Nome`, `Matrícula`, `Cargo`), escolha um avatar a partir da galeria de imagens locais em `assets/images/` (sem necessidade de Firebase Storage) e altere sua senha diretamente no perfil mediante confirmação da senha atual.
* **RF-007 — Navegação Rápida (`BottomNavigationBar`):** Disponibilizar barra de navegação inferior persistente nas telas principais (liberada apenas para usuários aprovados) para alternância instantânea entre os módulos:
  1. **Demandas:** Listagem e acompanhamento de tarefas periciais;
  2. **Viagens:** Controle e agendamento de deslocamentos;
  3. **Mapa Geral:** Visualização geográfica das demandas no Google Maps;
  4. **Resumo / Indicadores:** Visão rápida de produtividade e prazos do servidor.

### 4.2. Módulo de Gestão de Demandas e Notificações
* **RF-008 — Cadastro, Listagem, Demandas do Setor e Filtros:**
  * Permitir a gestores e servidores o cadastro de novas demandas (nascendo como `nao_iniciada`), com máscara para **Número SGP** (`numero/ano` — até 7 dígitos + `/` + 4 dígitos do ano, concatenado automaticamente à sigla da lotação de destino, ex.: `0001234/2026-ENG`), máscara automática para **Número SEI** (`00.00.0000.0000000/xxxx-00`, ano não superior ao ano corrente) e **endereço completo** (`CEP`, `Logradouro`, `Número` opcional, `Complemento` opcional, `Bairro`, `Cidade`, `Estado/UF`). Gestores podem vincular a um servidor ou deixar sem vínculo; servidores criam demandas vinculadas exclusivamente ao seu setor.
  * Exibir lista de demandas em cartões limpos com filtro por status (*Todas*, *Demandas do Setor* para assumir demandas sem servidor, *Não Iniciadas*, *Em Andamento*, *Pausadas*, *Concluídas*) e barra de busca textual.
* **RF-009 — Detalhes, Início, Vínculo e Exclusão Controlada da Demanda:**
  * Exibir informações completas da demanda e disponibilizar o botão **"Iniciar"** (`nao_iniciada` → `em_andamento`) exclusivamente para usuários da lotação de destino da demanda.
  * Permitir ao Administrador/Coordenação alterar ou desvincular o servidor responsável e excluir a demanda apenas se estiver `nao_iniciada` e não vinculada a nenhuma viagem.
  * Permitir ao servidor desvincular-se de sua própria demanda, desde que ela não esteja em uma viagem iniciada ou concluída.
* **RF-010 — Pausar e Despausar Demanda:** Permitir pausar uma demanda em andamento exigindo obrigatoriamente uma **justificativa textual**. Ao despausar, o status retorna para *Em Andamento*.
* **RF-011 — Comentários na Demanda:** Permitir que usuários autenticados e aprovados adicionem comentários em uma demanda. Apenas o autor do comentário ou um usuário com perfil `coordenacao`/`administrador` pode editar ou excluir o comentário.
* **RF-012 — Histórico Automático (Linha do Tempo) e Notificações In-App:**
  * Registrar automaticamente e exibir em ordem cronológica reversa os eventos da demanda (criação, início, vínculo/desvínculo, pausa com justificativa, retomada, conclusão, inclusão de comentário e agendamento/desvínculo de viagem).
  * Enviar notificações em tempo real via Cloud Firestore (ícone de sino na barra superior e tela `NotificacoesView`) para Coordenação/Administração (alterações em demandas, desvínculos, exclusões) e para Servidores (atribuição/desvínculo de demandas e vinculação a viagens).

### 4.3. Módulo de Mapeamento de Viagens e Google Maps
* **RF-013 — Cadastro, Vínculos e Exclusão Controlada de Viagens:** Permitir cadastrar e editar viagens vinculadas a uma ou mais demandas (inclusive em cidades diferentes) e a um ou mais servidores, contendo:
  * Demanda(s) associada(s) (puxando automaticamente a unidade solicitante e preenchendo a lista de endereços/destinos da viagem com os endereços já cadastrados nas demandas);
  * Servidores vinculados (quando criada por servidor, inicia vinculada a ele com opção de alterar; quando criada por gestor, exige ao menos um servidor);
  * Número SEI da Portaria (com máscara `00.00.0000.0000000/xxxx-00`) e Número da Portaria;
  * Múltiplos Destinos/Endereços completos (`CEP`, `Logradouro`, `Número` opcional, `Complemento` opcional, `Bairro`, `Cidade`, `Estado/UF` e coordenadas), com opção de adicionar endereços extras manualmente ou pelo mapa;
  * Data de Ida e Data de Retorno;
  * Situação (`Agendada`, `Em andamento`, `Concluída`, `Cancelada`);
  * Número SEI da Prestação de Contas e Observações complementares;
  * Desvínculo de demanda da viagem (e vice-versa) permitido ao gestor desde que a viagem não esteja `Em andamento` nem `Concluída`, e exclusão de viagem permitida ao gestor apenas quando não houver demandas vinculadas.
* **RF-014 — Mapa Geral de Demandas e Viagens:** Exibir uma tela com mapa interativo (Google Maps) contendo marcadores personalizados para todos os endereços das demandas vinculadas ao usuário logado, permitindo tocar no marcador para visualizar um resumo e abrir a demanda.
* **RF-015 — Busca de Endereços e Seleção Interativa no Mapa (Geocoding Direto e Reverso):**
  * Permitir buscar coordenadas geográficas (`latitude` e `longitude`) a partir do endereço completo ao cadastrar uma demanda ou adicionar destino de viagem.
  * Caso o endereço não seja encontrado na busca textual, perguntar ao usuário se deseja buscar no mapa, abrindo um seletor interativo (`MapPickerView`) onde o clique em qualquer ponto exibe suas coordenadas e endereço correspondente (geocodificação reversa) e os aplica ao formulário.
* **RF-016 — Cálculo e Traçado de Rota:** A partir da localização atual do dispositivo (GPS/Navegador) até o destino da demanda ou a qualquer um dos destinos cadastrados na viagem selecionada, calcular distância/tempo estimado e desenhar a polilinha da rota diretamente no mapa.

---

## 5. Requisitos Não Funcionais (RNF)

* **RNF-001 — Arquitetura Limpa:** Separação clara de responsabilidades utilizando o padrão **MVC / MVVM** organizado nas pastas `models`, `views`, `controllers`, `services` e `utils`.
* **RNF-002 — Banco de Dados, Mídia Local e Regras de Segurança:** Utilização do **Cloud Firestore** protegido por `firestore.rules` (exigindo autenticação e aprovação `ativo == true` no perfil do usuário para leitura/escrita operacional) e avatares locais em `assets/images/` para o perfil do servidor (dispensando Firebase Storage).
* **RNF-003 — Segurança e Proteção de Credenciais:** Nenhuma chave de API (Google Maps API Key, configurações do Firebase ou e-mail do administrador master) deve ser versionada diretamente no código-fonte. Todas as credenciais devem ser isoladas em arquivo `.env` ignorado pelo Git (`.gitignore`).
* **RNF-004 — Compatibilidade e Responsividade:** Suporte nativo para **Android** e execução fluida em **Flutter Web** (para testes no notebook), com permissões devidamente configuradas para rede e localização (GPS).
* **RNF-005 — Acessibilidade:** Uso de contrastes adequados (preto/branco sobre `#8E1919`), tamanhos de fonte legíveis e rótulos semânticos nos botões e campos de formulário.
* **RNF-006 — Qualidade e Testes:** Código limpo, comentado em regras complexas e acompanhado de testes unitários (regras de negócio/models) e testes de widget/integração básicos.