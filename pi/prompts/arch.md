---
description: Cria uma proposta técnica/arquitetural usando o agente global architect
argument-hint: "<requisito, PRD ou plano>"
---

Use o agente global `architect` por meio da ferramenta `subagent`.

Tarefa para o agente `architect`:

$ARGUMENTS

Instruções para você, agente principal:

1. Delegue ao subagente `architect` com `agentScope: "user"`.
2. Não implemente código durante esta etapa.
3. Apresente a proposta técnica ao usuário.
4. Pergunte se o usuário quer salvar a proposta em arquivo.
