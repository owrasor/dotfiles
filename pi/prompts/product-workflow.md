---
description: Executa fluxo PRD → plano → arquitetura → QA usando agentes globais
argument-hint: "<ideia, projeto ou feature>"
---

Use a ferramenta `subagent` em modo `chain` com `agentScope: "user"` para executar este fluxo de agentes globais:

1. `prd`
2. `planner`
3. `architect`
4. `qa`

Tarefa inicial:

$ARGUMENTS

Configuração da cadeia sugerida:

- Passo 1, agente `prd`: criar um PRD completo para: `$ARGUMENTS`.
- Passo 2, agente `planner`: com base no PRD anterior, criar um plano de execução técnico incremental. Contexto: `{previous}`.
- Passo 3, agente `architect`: com base no PRD e no plano anterior, criar uma proposta técnica/arquitetural. Contexto: `{previous}`.
- Passo 4, agente `qa`: com base nos artefatos anteriores, criar um plano de QA e matriz de cobertura. Contexto: `{previous}`.

Instruções para você, agente principal:

1. Não implemente código durante este fluxo.
2. Depois da cadeia, apresente um resumo executivo dos artefatos gerados.
3. Pergunte quais documentos o usuário deseja salvar e em quais caminhos.
