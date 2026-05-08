---
description: Cria um plano de execução usando o agente global planner
argument-hint: "<PRD, requisito ou feature>"
---

Use o agente global `planner` por meio da ferramenta `subagent`.

Tarefa para o agente `planner`:

$ARGUMENTS

Instruções para você, agente principal:

1. Delegue ao subagente `planner` com `agentScope: "user"`.
2. Não implemente código durante esta etapa.
3. Apresente o plano ao usuário.
4. Pergunte se o usuário quer salvar o plano em arquivo.
