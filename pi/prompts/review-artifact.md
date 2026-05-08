---
description: Revisa código, PRD, plano ou proposta usando o agente global reviewer
argument-hint: "<escopo da revisão>"
---

Use o agente global `reviewer` por meio da ferramenta `subagent`.

Tarefa para o agente `reviewer`:

$ARGUMENTS

Instruções para você, agente principal:

1. Delegue ao subagente `reviewer` com `agentScope: "user"`.
2. Não implemente código durante esta etapa.
3. Apresente o resultado da revisão ao usuário.
4. Se houver achados bloqueantes, pergunte como o usuário deseja prosseguir.
