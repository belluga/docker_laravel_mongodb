# Documento Estratégico: Ideias de BI para o Dashboard "Guar[APP]ari Promoter"
*Versão 1.0 - Este documento serve como um repositório inicial de ideias para os gráficos e métricas dos dashboards dos nossos parceiros. Será detalhado em uma etapa futura.*

---

## Visão 1: Dashboard do Promoter (Influenciador / Artista)

**Objetivo Central:** Permitir que o promoter meça seu desempenho e demonstre seu impacto para os estabelecimentos parceiros.

**Métricas Chave (KPIs):**
- Receita Gerada (Comissão)
- Ingressos/Vouchers Vendidos (Volume)
- Cliques no Link de Afiliado
- Taxa de Conversão (Vendas / Cliques)
- Alcance (Visualizações do convite)

**Potenciais Gráficos e Componentes:**

1.  **Card de Resumo (Período Selecionado):**
    - `[Valor: R$ 1.250,50]` - Sua Comissão
    - `[Valor: 180]` - Ingressos Vendidos
    - `[Valor: 3.600]` - Cliques no Link
    - `[Valor: 5%]` - Taxa de Conversão

2.  **Gráfico de Linha: "Performance ao Longo do Tempo"**
    - Eixo X: Dias do Mês
    - Eixo Y: Valor da Comissão (R$) ou Volume de Vendas

3.  **Tabela: "Performance por Evento/Estabelecimento"**
    - Colunas: `[Estabelecimento | Evento | Ingressos Vendidos | Minha Comissão | Gerar Relatório PDF]`
    - Funcionalidade: Permitir que o promoter filtre por estabelecimento e exporte um relatório simples para prestar contas.

---

## Visão 2: Dashboard do Dono do Evento (Estabelecimento)

**Objetivo Central:** Permitir que o dono do estabelecimento entenda o ROI de seus canais de divulgação e o impacto de cada promoter.

**Métricas Chave (KPIs):**
- Receita Total do Evento
- Ingressos Vendidos (Total e por canal)
- Origem das Vendas (split por promoter)
- Ticket Médio

**Potenciais Gráficos e Componentes:**

1.  **Card de Resumo (Evento Selecionado):**
    - `[Valor: R$ 25.100,00]` - Receita Bruta
    - `[Valor: 350 / 500]` - Ingressos Vendidos / Capacidade
    - `[Valor: 5]` - Promoters Ativos

2.  **Gráfico de Pizza: "Origem das Vendas"**
    - Fatias: `[Influenciador A (30%)]`, `[Banda B (25%)]`, `[Venda Direta App (20%)]`, `[Outros (25%)]`
    - Interatividade: Clicar em uma fatia filtra a tabela abaixo.

3.  **Tabela: "Ranking de Performance dos Promoters"**
    - Colunas: `[Rank | Nome do Promoter | Ingressos Vendidos | Receita Gerada]`
    - Ordenação: Clicável para ordenar por qualquer coluna.