# Módulo Consolidado: Plataforma Guar[APP]ari Promoter (v1.0)

**Propósito:** Fornecer as ferramentas operacionais para que nossos parceiros possam criar eventos, gerenciar sua rede de promoters (afiliados) e dar autonomia para que os próprios promoters acompanhem seu desempenho, alimentando os dashboards de BI.

---

## 1. Protótipo: Tela de Criação e Gestão de Eventos

*A interface onde o dono do estabelecimento ou produtor cultural cadastra um novo evento na agenda do Guar[APP]ari.*

- **Título da Página:** Meus Eventos
- **CTA Principal:** `[Botão: + Criar Novo Evento]`

---

### **Fluxo de Criação de Evento (Modal ou Nova Página)**

- **Título:** Crie seu Evento
- **Campos do Formulário:**
    - **Nome do Evento:** `[Campo de Texto]` (Ex: "Samba de Raiz na Praia")
    - **Categoria:** `[Dropdown: Música, Gastronomia, Esporte, Arte & Cultura, Outros]`
    - **Local:** `[Campo de Texto com Autocomplete do Google Maps]`
    - **Data e Hora de Início:** `[Seletor de Data e Hora]`
    - **Data e Hora de Fim:** `[Seletor de Data e Hora]`
    - **Descrição Completa:** `[Caixa de Texto com formatação simples]`
    - **Upload de Imagem de Capa:** `[Botão de Upload]`
    - **Informações de Ingresso:**
        - `[Radio Button: Evento Gratuito | Evento Pago]`
        - **Se Pago:**
            - **Preço (R$):** `[Campo Numérico]`
            - **Quantidade de Ingressos:** `[Campo Numérico]`
- **CTA:** `[Botão: Publicar Evento]` | `[Link: Salvar como Rascunho]`

---

## 2. Protótipo: Tela de Gestão de Promoters

*O painel onde o dono do evento convida e gerencia sua rede de afiliados.*

- **Título da Página:** Gerenciar Promoters - [Nome do Evento]
- **Visão Geral:**
    - **Métrica 1:** `[Valor: 15]` - Promoters Ativos
    - **Métrica 2:** `[Valor: R$ 4.500,00]` - Receita Gerada por Promoters
- **CTA Principal:** `[Botão: + Convidar Novo Promoter]`

### **Lista de Promoters Ativos (Tabela)**
| Promoter (Usuário) | Link de Afiliado | Vendas | Comissão Gerada | Ações |
| :--- | :--- | :--- | :--- | :--- |
| `[Foto]` Maria Silva | `[Botão: Copiar Link]` | 82 | R$ 410,00 | `[Ícone: Ver Detalhes]` |
| `[Foto]` João Costa | `[Botão: Copiar Link]` | 55 | R$ 275,00 | `[Ícone: Ver Detalhes]` |

---

## 3. Protótipo: Painel de Controle do Promoter

*A visão simplificada para o influenciador ou artista acompanhar seu desempenho em tempo real.*

- **Título da Página:** Meu Painel de Promoter
- **Card de Resumo (Geral):**
    - **Sua Comissão Total (Mês):** `[Valor: R$ 685,00]`
    - **Total de Ingressos Vendidos:** `[Valor: 137]`
- **Seção: "Minhas Campanhas Ativas"**
    - **Componente: Lista de Eventos**
        - **Card de Evento 1:**
            - **Nome:** Samba de Raiz na Praia
            - **Meu Desempenho:** 25 Ingressos | R$ 125,00 de Comissão
            - **Meu Link Exclusivo:** `[campo de texto com link]` `[Botão: Copiar]`
            - **CTA:** `[Botão: Ver Estatísticas Detalhadas]` -> *Leva para o `modulo_promoter_bi.md`*
        - **Card de Evento 2:**
            - (Informações similares)