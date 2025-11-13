# Documento Mestre: Guar[APP]ari - O Ecossistema Simbiótico Completo (v1.0)

**Versão:** 1.0
**Data:** 11/10/2025
**Descrição:** Este documento consolida todos os módulos e protótipos do aplicativo Guar[APP]ari, servindo como a fonte única de verdade para a visão do produto, arquitetura de informação, fluxos de usuário (B2C) e plataformas de parceiros (B2B).

---
---

# Parte 1: Visão Estratégica e Manifesto (Origem: prototipo_geral.md)

## 1.1. Conceito do Aplicativo

Guar[APP]ari é uma plataforma de experiências que cria um **ecossistema simbiótico** entre moradores, turistas, especialistas locais e inteligência artificial. O aplicativo conecta a necessidade do usuário ao serviço perfeito, seja ele um roteiro gerado por IA, uma experiência autêntica com um guia humano, ou um produto da nossa loja local.

## 1.2. Nosso Manifesto

*A Guarapari das praias.*
*A Guarapari das montanhas.*
*A Guarapari das baleias.*
*A Guarapari da música.*
*A Guarapari da feirinha.*
*A Guarapari do calçadão.*

*Para todas as Guaraparis um único APP.*

*Guar[APP]ari*
*A sua Guarapari está aqui.*

## 1.3. Proposta de Valor

* **Para Usuários:** Oferecer um guia completo e personalizado para encontrar a "sua" Guarapari, com **conveniência e segurança em pagamentos e a possibilidade de recompensas (cashback).**
* **Para Clientes (Estabelecimentos, Artistas, Guias):** Oferecer uma vitrine digital, uma plataforma de marketing **através da ferramenta "Guar[APP]ari Promoter" com dashboards de BI, um modelo de marketing de afiliados para impulsionar vendas**, uma solução de pagamento integrada de baixo custo e uma plataforma inovadora para escalar seu conhecimento e criar novas fontes de receita passiva através da criação de 'Guias IA' personalizados.

## 1.4. Funcionalidades Chave

* **Agenda Cultural e de Eventos:** O coração inicial do app.
* **Loja (Marketplace de Produtos Locais):** Vitrine para artesãos e comerciantes.
* **Ecossistema de Guias (Humanos & IA):** Um diretório unificado que apresenta tanto especialistas locais quanto personalidades de IA.
* **Plataforma "Guar[APP]ari Promoter":** Painel de controle B2B para estabelecimentos, artistas e influenciadores criarem e promoverem eventos, com ferramentas de BI para análise de ROI.
* **Motor de "Matchmaking" por IA:** Sistema de busca por linguagem natural (texto e voz) que conecta o usuário com os guias mais adequados.
* **Sistema de Convites ("Bora?"):** Motor de crescimento viral e engajamento social. Apresenta uma interface gamificada ("swipe") para aceitar/recusar/marcar como 'talvez' os convites recebidos e um fluxo de propagação dedicado para que os usuários convidem sua própria rede de contatos.
* **Geolocalização:** Exibição de estabelecimentos, eventos, lojinhas de produtores e pontos de utilidade pública no mapa.

## 1.5. Modelo de Monetização

* **Planos de Assinatura para Parceiros:** Planos com diferentes níveis de destaque e ferramentas de marketing.
* **Plano Premium para Usuários:** Experiência sem anúncios, com **acesso ilimitado ao gerador de roteiros por IA**, e acesso a roteiros e experiências premium.
* **Taxa sobre Transações (Loja/Experiências):** Percentual sobre vendas de produtos e contratação de serviços.
* **Modelo de Afiliados (Comissão):** Estrutura de comissão para parceiros do tipo "Promoter" sobre as vendas de ingressos/vouchers geradas através de seus canais de divulgação exclusivos.

## 1.6. Arquitetura de Navegação (Menu Principal / Tab Bar)

* **Home:** Dashboard personalizado.
* **Agenda:** Eventos e programações.
* **Loja:** Produtos locais.
* **Guias & Experiências:** O ecossistema de roteiros e serviços.
* **Perfil:** Área do usuário, configurações e ingressos.
* **Ação Principal (FAB):** Um Botão de Ação Flutuante (FAB) com o ícone de localização (`[Ícone de Pin]`) é o componente de navegação universal que fornece acesso rápido ao mapa a partir da maioria das telas.

---
---

# Parte 2: Fluxos do Usuário (B2C)

## 2.1. Módulo: Onboarding de Novos Usuários

### Tela 1: Boas-vindas e Cadastro
- **Elemento Visual:** `[Animação sutil com a logo e o manifesto do Guar[APP]ari]`
- **Título:** A sua Guarapari está aqui.
- **Opções de Cadastro (Foco em Baixa Fricção):**
    - `[Botão: Continuar com Google]`
    - `[Botão: Continuar com Facebook]`
    - `[Botão: Continuar com Apple]`
- **Link de Acesso Direto:** `[Link: Já tenho uma conta. Entrar]`

### Tela 2: Personalização de Interesses
- **Título:** Olá, [Nome do Usuário]! Para começar, conte-nos do que você mais gosta.
- **Subtítulo:** Suas escolhas nos ajudam a montar uma Guarapari com a sua cara.
- **Componente: Seleção de Tags (Múltipla Escolha)**
    - **Seção: Música**
        - `[Tag: Rock]` `[Tag: Samba]` `[Tag: Forró]` `[Tag: MPB]` `[Tag: Eletrônica]`
    - **Seção: Rolês**
        - `[Tag: Praia de Dia]` `[Tag: Barzinho à Noite]` `[Tag: Restaurantes]` `[Tag: Trilhas e Natureza]` `[Tag: Passeio Cultural]`
- **CTA:** `[Botão: Concluir]` (O botão fica ativo após a seleção de pelo menos 3 tags)

### Tela 3: Micro-tutorial (Carrossel Automático)
- **Slide 1: A Agenda Inteligente**
    - **Texto:** "Nunca mais se pergunte 'o que tem pra fazer hoje?'. A melhor agenda da cidade, na sua mão."
- **Slide 2: O Matchmaker de IA**
    - **Texto:** "Fale ou escreva o que você quer. Nossa IA encontra o rolê, o prato ou a experiência perfeita para você."
- **Slide 3: O Ecossistema Local**
    - **Texto:** "Ao usar o app, você fortalece artistas, guias e produtores da nossa terra. Bem-vindo ao Guar[APP]ari."
- **CTA Final:** `[Botão: Começar a Explorar!]` -> *Leva para a Tela Inicial (Home)*

---

## 2.2. Módulo: Tela Inicial (Home) (Origem: home.md)

### Cabeçalho Principal (Topo Fixo)
| Elemento | Conteúdo |
| :--- | :--- |
| **Identidade** | `[Logo Guar[APP]ari]` \| **Olá, [Nome do Usuário]!** |
| **Ações Imediatas** | `[Ícone de Notificações 🔔]` \| `[Ícone de Perfil / Wallet 💳]` |

### Módulo Principal: Busca Conversacional
- **Título:** **Encontre a sua Guarapari de hoje.**
- **Campo de Busca:** `[Escreva ou fale: "Quero um guia para mergulho amanhã"]`
- **Botão de Áudio:** `[Ícone de Microfone 🎙️]`
- **CTA:** `[Botão de Ação: Buscar]`

### Navegação Rápida (Tags de Intenção)
*Carrossel horizontal de atalhos.*
| Tag de Filtro | Módulo de Destino |
| :--- | :--- |
| `[O que fazer Hoje?]` | Agenda |
| `[Onde Comprar?]` | Loja |
| `[Quero um Roteiro]` | Guias & Experiências |
| `[Utilidades Próximas]` | Mapa |

### Conteúdo Dinâmico (Blocos Modulares)
- **Bloco: Agenda em Destaque**
    - **Título:** **Seu Próximo Evento**
    - **Componente:** `[Carrossel Horizontal de Cards de Evento]`
- **Bloco: Curadoria de Kits**
    - **Título:** **Oferta Exclusiva para Você**
    - **Componente:** `[Carrossel Horizontal de Cards de Kits]`
- **Bloco: Guia e Experiências**
    - **Título:** **Sua Próxima Aventura**
    - **Componente:** `[Grid de Cards de Experiência (2 Colunas)]`

---

## 2.3. Módulo: Agenda & Crescimento Viral (Origem: modulo_agenda.md)

### Tela Principal da Agenda
- **Alerta Condicional:** `[Banner sutil: ✉️ Você tem 3 novos convites! [Ver Agora]]`
- **Controles:** `[Sua Agenda]` `[Hoje]` `[Esta Semana]`
- **Busca e Filtros:** `[🔎 Buscar...]` `[Ícone de Filtro 📊]`
- **Destaques:** `[Carrossel de Banners Patrocinados]`
- **Feed Principal:** Lista de `[Card de Evento]` com Data, Título, Local, Tags e Indicador Social.

### Tela de Detalhes do Evento
- **Hero:** `[Banner do evento]`, Título, Data, `[Link: Local]`
- **Artista:** `[Foto]`, `[Link: Nome do Artista]`
- **Descrição:** Sobre o evento, como chegar (`[Mapa Interativo]`).
- **Prova Social:** "Maria Clara, João Pedro e outros 12 amigos seus confirmaram presença."
- **CTAs:**
    - `[Botão Grande: Comprar Ingresso - R$ 50,00]`
    - `[Botão com Ícone de Foguete 🚀: BORA? Chamar sua galera!]`

### Sub-telas: Perfil do Estabelecimento e Perfil do Artista
- Páginas dedicadas com informações, bio e lista de próximos eventos/shows.

### Fluxo "Bora?": Gerenciador de Convites Recebidos
- **Interface Gamificada:** Pilha de "Cards de Convite" estilo Tinder/Stories.
- **Card:** Imagem do evento, "Quem Convidou", "Quem já vai".
- **Ações:**
    - **Swipe Direita / ✅:** Aceitar
    - **Swipe Esquerda / ❌:** Recusar
    - **Swipe Cima / 🤔:** Talvez

### Fluxo "Bora?": Propagar Convite
- **Contexto:** `[🎉 Presença Confirmada!]` no evento.
- **Sugestões Inteligentes:** Carrossel de contatos sugeridos ("Vocês foram a 3 eventos de Rock juntos").
- **Seleção:** Busca e lista de contatos.
- **CTA Final:** `[Botão com Ícone do WhatsApp: Enviar Convite para (3)]`

---

## 2.4. Módulo: Loja Local (Origem: modulo_loja.md)

### Tela Principal da Loja
- **Busca Conversacional:** `[🔎 O que você gostaria de comprar?]`
- **Filtros Rápidos:** `[Todos]`, `[Produtos Rurais]`, `[Artesanato]`, `[Kits Temáticos]`
- **Seção: Kits Especiais (Curadoria IA)**
    - **Título:** Kits Recomendados para a Sua Experiência
    - **Componente:** Carrossel de `[Card de Kit]` com Nome, Descrição e Preço.
- **Seção: Vitrine do Produtor**
    - **Título:** Nossos Parceiros em Destaque
    - **Componente:** Grid de `[Card de Lojinha]` com Foto, Nome, Foco e Avaliação.
- **Feed Unificado de Produtos:** Lista de `[Card de Produto]` com Imagem, Nome, Produtor e Preço.

### Tela da Página do Produtor ("Lojinha")
- **Cabeçalho:** `[Banner/Foto do Local]`, Nome do produtor.
- **Seção de Contexto:** História, Localização, Avaliação.
- **Seção de Produtos:** Catálogo completo de produtos daquele produtor.

---

## 2.5. Módulo: Guias & Experiências (Origem: modulo_guias_e_experiencias.md)

### Tela Principal de Guias & Experiências
- **Módulo de Busca Inteligente ("Matchmaker"):** `[Escreva ou fale o que você procura...]`
- **Seção: "Nossos Guias" (Carrossel)**
    - **Componente:** `[Card de Guia Humano]` e `[Card de Guia IA]`.
- **Seção: "Experiências em Destaque" (Grid)**
    - **Componente:** Grid de `[Card de Experiência]` com Imagem, Título, Categoria e Custo.

### Telas de Lista (Guias ou Experiências)
- **Ferramentas:** Barra de Busca e `[Ícone de Filtro]` que abre um Drawer lateral.
- **Drawer de Filtros:** Opções para Ordenar por, Categorias, Custo, Duração, etc.
- **Conteúdo:** Grid completo de todos os guias ou experiências.

### Fluxo de Contratação de Experiência
- **Tela 1: Resumo e Agendamento**
    - Seleção de Data, Horário e Participantes.
    - **Cálculo de Preço:** Subtotal + **Taxa de Serviço Guar[APP]ari** = Total.
    - **CTA:** `[Botão: Ir para o Pagamento]`
- **Tela 2: Pagamento (Guar[APP]ari Pay)**
    - **Opções:** Usar Saldo, Cartões Cadastrados, PIX.
    - **Cashback:** "Você receberá R$ X de cashback nesta compra!"
    - **CTA:** `[Botão: Confirmar Pagamento]`
- **Tela 3: Confirmação**
    - **Mensagem:** "Reserva Confirmada!"
    - **Informações:** Ponto de Encontro, `[Botão: Enviar Mensagem para Guia]`.

---

## 2.6. Módulo: Mapa & Mobilidade (Origem: modulo_mapa_e_mobilidade.md)

### Tela Principal do Mapa
- **Visualização:** Mapa interativo com Pins para Eventos, Lojas, Guias e Pontos de Interesse.
- **Busca:** `[🔎 Buscar evento, lojinha, guia ou endereço...]`
- **Filtros:** `[Ícone de Filtro]` que expande um carrossel de tags para filtrar os pins (`[Agenda]`, `[Lojas/Produtores]`, `[Utilidade Pública]`).

### Componente: Card de Detalhe Flutuante (Bottom Sheet)
*Abre ao clicar em um Pin.*
- **Conteúdo:** Título, Endereço, Avaliação.
- **Ações Imediatas:**
    - `[Botão: Ver Detalhes]` (Leva para a página específica do item)
    - **Atalho de Rota Externa:** `[Ícone: Waze] | [Ícone: Uber] | [Ícone: Google Maps]`
- **Conteúdo Integrado (Se aplicável):** Carrossel de "Próximos Eventos no Local".

---

## 2.7. Módulo: Perfil & Utilidades (Origem: modulo_perfil_e_utilidades.md)

### Tela Principal do Perfil
- **Card de Perfil:** `[Foto]`, Nome do Usuário, `[Tag: Membro Premium / Padrão]`.
- **Painel Financeiro (Guar[APP]ari Pay):**
    - **Saldo Disponível (Cashback):** `[Valor em Destaque: R$ 50,00]`
    - **CTAs:** `[Ver Detalhes e Extrato]`
- **Menu de Utilidades:**
    - `[Minhas Compras & Reservas]`
    - `[Itens Salvos (Favoritos)]`
    - `[Plano Premium / Assinaturas]`
    - `[Configurações]`, `[Ajuda e Suporte]`

### Fluxo de Gestão do Plano Premium
- **Tela de Venda (para não-assinantes):**
    - **Benefício Chave:** **Roteiros Ilimitados por IA.**
    - **Outros Benefícios:** Cashback Dobrado, Sem Anúncios.
    - **CTA:** `[Botão: Assinar Plano Premium]`
- **Tela de Gerenciamento (para assinantes):**
    - **Status:** Próximo ciclo de cobrança, opções para Mudar/Cancelar plano.

---
---

# Parte 3: Plataforma do Parceiro (B2B)

## 3.1. Plataforma Guar[APP]ari Promoter (Operacional)

### Tela: Criação e Gestão de Eventos (Dono do Estabelecimento)
- **CTA Principal:** `[+ Criar Novo Evento]`
- **Formulário de Criação:**
    - Campos: Nome do Evento, Categoria, Local, Data/Hora, Descrição, Upload de Imagem, Info de Ingresso (Gratuito/Pago, Preço, Quantidade).
- **CTA:** `[Publicar Evento]` | `[Salvar como Rascunho]`

### Tela: Gestão de Promoters (Dono do Estabelecimento)
- **Título:** Gerenciar Promoters - [Nome do Evento]
- **Métricas:** `[Promoters Ativos]`, `[Receita Gerada por Promoters]`
- **CTA Principal:** `[+ Convidar Novo Promoter]`
- **Tabela de Promoters Ativos:**
    | Promoter | Link de Afiliado | Vendas | Comissão |
    | :--- | :--- | :--- | :--- |
    | `[Foto]` Maria Silva | `[Copiar Link]` | 82 | R$ 410,00 |

### Tela: Painel de Controle do Promoter (Influenciador/Artista)
- **Título:** Meu Painel de Promoter
- **Resumo:** `[Sua Comissão Total (Mês)]`, `[Total de Ingressos Vendidos]`
- **Seção "Minhas Campanhas Ativas":**
    - Lista de `[Card de Evento]` com:
        - Meu Desempenho: (X Ingressos | R$ Y de Comissão)
        - Meu Link Exclusivo: `[Link]` `[Botão: Copiar]`
        - CTA: `[Ver Estatísticas Detalhadas]` -> *Leva para o Dashboard de BI*

---

## 3.2. Dashboards de Business Intelligence (BI) (Origem: modulo_promoter_bi.md)

### Visão 1: Dashboard do Promoter (Influenciador / Artista)
- **Objetivo:** Medir desempenho e impacto.
- **Métricas Chave:** Receita Gerada (Comissão), Ingressos Vendidos, Cliques no Link, Taxa de Conversão.
- **Componentes:**
    - **Card de Resumo:** Totais de comissão, vendas e cliques.
    - **Gráfico de Linha:** Performance ao Longo do Tempo.
    - **Tabela:** Performance por Evento/Estabelecimento.

### Visão 2: Dashboard do Dono do Evento (Estabelecimento)
- **Objetivo:** Entender o ROI dos canais de divulgação.
- **Métricas Chave:** Receita Total, Origem das Vendas (split por promoter), Ticket Médio.
- **Componentes:**
    - **Card de Resumo:** Receita Bruta, Ingressos Vendidos / Capacidade.
    - **Gráfico de Pizza:** Origem das Vendas (`[Influenciador A (30%)]`, `[Venda Direta App (20%)]`, etc.).
    - **Tabela:** Ranking de Performance dos Promoters.