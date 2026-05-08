---
description: Gera documentação usando o agente global docs
argument-hint: "<tipo de documentação e contexto>"
---

Use o agente global `docs` por meio da ferramenta `subagent`.

Tarefa para o agente `docs`:

$ARGUMENTS

Instruções para você, agente principal:

1. Delegue ao subagente `docs` com `agentScope: "user"`.
2. Não altere arquivos durante esta etapa.
3. Apresente a documentação gerada ao usuário.
4. Pergunte se o usuário quer salvar a documentação em arquivo.
