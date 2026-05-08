---
description: Cria um plano de QA usando o agente global qa
argument-hint: "<feature, PRD ou plano>"
---

Use o agente global `qa` por meio da ferramenta `subagent`.

Tarefa para o agente `qa`:

$ARGUMENTS

Instruções para você, agente principal:

1. Delegue ao subagente `qa` com `agentScope: "user"`.
2. Não implemente código durante esta etapa.
3. Apresente o plano de QA ao usuário.
4. Pergunte se o usuário quer salvar o plano em arquivo.
