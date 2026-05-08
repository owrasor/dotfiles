---
description: Gera um PRD usando o agente global prd
argument-hint: "<descrição do projeto ou feature>"
---

Use o agente global `prd` por meio da ferramenta `subagent` para criar um Product Requirements Document.

Tarefa para o agente `prd`:

$ARGUMENTS

Instruções para você, agente principal:

1. Delegue a análise e geração do PRD ao subagente `prd`.
2. Use `agentScope: "user"`, pois os agentes configurados são globais.
3. Não implemente código durante esta etapa.
4. Depois que o subagente retornar o PRD, apresente o resultado ao usuário.
5. Pergunte se o usuário deseja salvar o documento em arquivo e em qual caminho.
