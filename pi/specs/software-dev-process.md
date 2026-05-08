# Especificação: Software Development Process no Pi

Status: planejamento aprovado para iniciar implementação incremental de `dev-start`.
Data: 2026-04-24.

## 1. Objetivo

Criar uma solução global para o Pi, versionada nos dotfiles, que execute um processo completo de desenvolvimento de software com agentes especializados, `git worktree`, planejamento de paralelismo, branches por sprint/tarefa, revisão, integração automática e UI de acompanhamento.

A implementação deve nascer em:

```txt
~/Code/owrasor/dotfiles/pi/
```

Depois deve ser replicada/linkada para as pastas globais do Pi, conforme a estratégia já existente dos dotfiles.

## 2. Decisões confirmadas

1. Prefixo dos comandos: `dev-`.
2. Local das worktrees: `.worktrees/`.
3. Escopo inicial: um repositório por vez.
4. Branch de origem: deve ser possível especificar; se omitida, detectar `main`/`master` ou usar a branch configurada.
5. Push remoto: permitido, com opção/configuração e confirmação quando apropriado.
6. Merge: deve ser automático, com resolução coerente de conflitos por agente responsável.
7. Cleanup: remover worktrees automaticamente somente após confirmação do merge.
8. Novos agentes: permitido criar `integration-manager` e `plan-reviewer`.
9. UI: deve existir widget/TUI para acompanhar sprint, fases, tarefas, worktrees, paralelismo, validações e integração.

## 3. Fluxo de branches e worktrees

Modelo base:

```txt
main ou <branch-origem>
  │
  └── sprint/<nome-da-sprint>
        │
        ├── task/<nome-da-sprint>/<tarefa-1>
        ├── task/<nome-da-sprint>/<tarefa-2>
        └── task/<nome-da-sprint>/<tarefa-3>
```

Regras:

- `sprint/*` é branch de planejamento e integração.
- `task/*` é branch de desenvolvimento isolado.
- Nunca desenvolver diretamente na branch da sprint, exceto ajustes de integração/conflito feitos pelo `integration-manager`.
- Cada branch relevante deve ter sua própria worktree.
- Tarefas paralelizáveis rodam em worktrees independentes.

Exemplo:

```txt
repo/
  .worktrees/
    sprint-cadastro-aluno/
    task-cadastro-aluno-backend-api/
    task-cadastro-aluno-frontend-form/
```

## 4. Comandos planejados

### 4.1 Primeira implementação

```txt
/dev-start <nome-da-sprint> <descrição>
/dev-start --base <branch-origem> <nome-da-sprint> <descrição>
```

Responsabilidades do `dev-start`:

1. validar que está dentro de um repositório Git;
2. validar/registrar branch de origem;
3. validar status do repositório;
4. criar ledger da sprint;
5. criar branch `sprint/<nome>` a partir da branch de origem;
6. criar worktree `.worktrees/sprint-<nome>`;
7. opcionalmente fazer push da branch de sprint;
8. iniciar fase de descoberta/planejamento;
9. produzir plano com tarefas, dependências e paralelismo;
10. exibir UI/status da sprint;
11. pedir aprovação antes de criar worktrees de tarefa ou alterar código.

### 4.2 Comandos implementados nesta etapa

```txt
/dev-approve-plan [sprint] [--push|--no-push]
```

Responsabilidades do `dev-approve-plan`:

1. carregar o ledger ativo ou o ledger informado;
2. validar que existe plano estruturado salvo;
3. apresentar resumo das tarefas, branches, worktrees, agentes, grupos e dependências;
4. pedir aprovação humana;
5. marcar o plano como aprovado;
6. criar branches/worktrees de tarefa a partir da branch da sprint;
7. opcionalmente fazer push das branches de tarefa;
8. atualizar ledger e UI;
9. deixar a sprint aguardando `/dev-run`.

A ferramenta interna `dev_save_plan` fica disponível para o agente salvar no ledger o plano estruturado produzido na fase de planejamento.

## 4.3 Execução implementada nesta etapa

```txt
/dev-run [sprint] [--group N]
```

Responsabilidades do `dev-run`:

1. carregar o ledger ativo ou informado;
2. encontrar o próximo grupo paralelo pendente com dependências atendidas;
3. pedir confirmação humana antes de executar agentes que podem alterar código;
4. executar tarefas do grupo em paralelo, cada uma na sua worktree;
5. usar o agente responsável quando o arquivo de agente for encontrado;
6. registrar resumo, arquivos alterados, erros e eventos no ledger;
7. avançar para o próximo grupo ou bloquear em caso de erro;
8. atualizar a UI em tempo real.

## 4.4 Review implementado nesta etapa

```txt
/dev-review [sprint] [--agent reviewer] [--task ID]
```

Responsabilidades do `dev-review`:

1. carregar o ledger ativo ou informado;
2. selecionar tarefas concluídas e ainda não aprovadas;
3. pedir confirmação humana;
4. executar reviews em paralelo em modo read-only;
5. usar o agente `reviewer` por padrão ou outro agente via `--agent`;
6. marcar tarefas como `approved`, `changes-requested` ou `error`;
7. bloquear a sprint se houver alterações solicitadas;
8. liberar integração quando todas as tarefas concluídas forem aprovadas.

## 4.5 Integração implementada nesta etapa

```txt
/dev-integrate [sprint] [--push|--no-push] [--task ID]
```

Responsabilidades do `dev-integrate`:

1. carregar o ledger ativo ou informado;
2. selecionar tarefas concluídas e aprovadas em review;
3. confirmar que a worktree da sprint está limpa;
4. pedir confirmação humana antes dos merges;
5. fazer merge `--no-ff` das branches de tarefa na branch da sprint;
6. acionar `integration-manager` quando houver conflito;
7. verificar se ainda existem arquivos em conflito;
8. concluir commit de merge após resolução;
9. opcionalmente fazer push da branch da sprint;
10. liberar a fase de validação.

## 4.6 Validação implementada nesta etapa

```txt
/dev-validate [sprint] [--cmd "comando"] [--list]
```

Responsabilidades do `dev-validate`:

1. carregar o ledger ativo ou informado;
2. detectar comandos de validação a partir das tarefas e da stack do projeto;
3. permitir listar comandos com `--list`;
4. permitir comandos explícitos com `--cmd`;
5. pedir confirmação humana antes de executar;
6. executar validações na worktree da sprint;
7. registrar saída, exit code, tempo e status no ledger;
8. bloquear a sprint em caso de falha;
9. liberar finalização quando todas as validações passarem.

Detecção inicial:

- `composer.json`: `composer test`, `php artisan test`, `vendor/bin/pint --test`, `vendor/bin/phpstan analyse` quando disponíveis;
- `package.json`: `npm run lint`, `npm run typecheck`, `npm run build`, `npm test` quando scripts existirem;
- Docker compose: `docker compose config`.

## 4.7 Finalização e cleanup implementados nesta etapa

```txt
/dev-finish [sprint]
/dev-cleanup [sprint] [--include-sprint] [--delete-branches]
```

Responsabilidades do `dev-finish`:

1. carregar o ledger ativo ou informado;
2. verificar validações registradas;
3. gerar relatório final Markdown em `.pi/workflows/reports/<sprint>.md`;
4. resumir tarefas, branches, worktrees, validações e arquivos alterados;
5. marcar a sprint como finalizada;
6. orientar abertura de PR/MR e cleanup após merge.

Responsabilidades do `dev-cleanup`:

1. carregar o ledger ativo ou informado;
2. pedir confirmação humana;
3. remover worktrees de tarefa;
4. opcionalmente remover a worktree da sprint com `--include-sprint`;
5. preservar branches por padrão;
6. opcionalmente deletar branches de tarefa locais com `--delete-branches`;
7. registrar ações no ledger.

## 4.8 Resume implementado nesta etapa

```txt
/dev-resume [sprint]
```

Responsabilidades do `dev-resume`:

1. detectar a raiz do repositório Git atual;
2. carregar o ledger informado ou o ledger mais recente;
3. restaurar estado em memória e UI;
4. nomear a sessão como `dev:<sprint>`;
5. registrar evento de retomada;
6. sugerir o próximo comando com base nas fases do ledger.

## 4.9 Comandos futuros

```txt
/dev-plan
/dev-status
```

## 5. Fases do processo

## Fase 0 — Inicialização segura

Entrada típica:

```txt
/dev-start --base main cadastro-aluno Implementar cadastro de aluno
```

A extensão deve:

- detectar raiz do Git;
- detectar remote padrão;
- confirmar branch base;
- impedir sobrescrever sprint/worktree existente sem confirmação;
- criar `.worktrees/`, se necessário;
- criar `sprint/<nome>` a partir da origem;
- criar worktree da sprint;
- criar ledger em `.pi/workflows/sessions/<nome>.json` ou equivalente global/local definido pela implementação.

Comando conceitual:

```bash
git fetch origin
git worktree add .worktrees/sprint-cadastro-aluno -b sprint/cadastro-aluno origin/main
```

Se não houver remote ou se a branch local for a origem escolhida:

```bash
git worktree add .worktrees/sprint-cadastro-aluno -b sprint/cadastro-aluno main
```

## Fase 1 — Descoberta e análise

Agentes candidatos:

- `explorer-agent`;
- `code-archaeologist`;
- `product-owner` ou `prd`;
- `security-auditor`, se aplicável;
- `database-architect`, se houver banco/migration;
- `frontend-specialist`, se houver UI;
- `backend-specialist`, se houver API/backend.

Pode rodar em paralelo quando for somente leitura.

Saída esperada:

- arquivos relevantes;
- riscos;
- dependências;
- pontos de impacto;
- contratos necessários;
- perguntas abertas.

## Fase 2 — Planejamento e decomposição

Agentes principais:

- `project-planner` ou `planner`;
- `plan-reviewer` para revisar dependências e paralelismo.

O plano deve conter:

- tarefas;
- responsável/agente;
- branch da tarefa;
- worktree da tarefa;
- dependências;
- grupo paralelo;
- projetos/arquivos afetados;
- validações esperadas;
- riscos;
- critérios de aceite.

Exemplo de estrutura:

```yaml
sprint:
  name: cadastro-aluno
  baseBranch: main
  sprintBranch: sprint/cadastro-aluno
  sprintWorktree: .worktrees/sprint-cadastro-aluno

tasks:
  - id: backend-api
    title: Criar endpoints de cadastro de aluno
    agent: backend-specialist
    branch: task/cadastro-aluno/backend-api
    worktree: .worktrees/task-cadastro-aluno-backend-api
    dependsOn: []
    parallelGroup: 1
    canRunInParallel: true
    affectedFiles:
      - routes/api.php
      - app/Http/Controllers/AlunoController.php
    validation:
      - php artisan test --filter=Aluno
```

## 6. Identificação de paralelismo

O planejamento deve montar um grafo de dependências.

Pode paralelizar quando:

- tarefas alteram subprojetos ou arquivos diferentes;
- uma tarefa depende apenas de contrato já definido;
- backend e frontend podem avançar com contrato de API aprovado;
- revisão/análise é read-only;
- documentação não bloqueia implementação;
- testes são de áreas independentes.

Não deve paralelizar quando:

- tarefas alteram o mesmo arquivo;
- uma depende de migration ainda não definida;
- contrato/API/interface ainda está instável;
- ambas alteram configuração global;
- ambas alteram dependências;
- risco de conflito é alto;
- a ordem lógica exige serialização.

Representação desejada:

```yaml
parallelGroups:
  - id: 1
    tasks:
      - backend-api
      - frontend-form
  - id: 2
    tasks:
      - integration-tests
  - id: 3
    tasks:
      - security-review
      - performance-review
```

## 7. Aprovação humana do plano

Antes de criar worktrees de tarefa ou iniciar desenvolvimento, a extensão deve apresentar:

- branch de origem;
- branch da sprint;
- worktree da sprint;
- tarefas;
- agentes responsáveis;
- branches de tarefa;
- worktrees de tarefa;
- grupos paralelos;
- dependências;
- arquivos esperados;
- riscos;
- comandos de validação;
- se haverá push remoto.

Somente após aprovação o processo deve avançar para criação das task worktrees.

## 8. Desenvolvimento por tarefa

Após aprovação futura:

1. criar uma branch/worktree por tarefa a partir da branch da sprint;
2. executar agentes responsáveis em suas próprias worktrees;
3. respeitar grupos paralelos;
4. registrar checkpoints;
5. rodar validações locais;
6. não fazer merge diretamente sem etapa de integração.

Exemplo:

```bash
git worktree add .worktrees/task-cadastro-aluno-backend-api \
  -b task/cadastro-aluno/backend-api \
  sprint/cadastro-aluno
```

## 9. Revisão por tarefa

Antes do merge na sprint:

- revisar branch de tarefa;
- rodar revisores read-only em paralelo quando possível;
- retornar para correção se houver reprovação;
- bloquear integração de tarefas reprovadas.

Agentes candidatos:

- `reviewer`;
- `security-auditor`;
- `test-engineer` ou `qa`;
- `database-architect`;
- `performance-optimizer`;
- `frontend-specialist`/`backend-specialist`, conforme escopo.

## 10. Integração automática na sprint

Agente recomendado: `integration-manager`.

Responsabilidades:

- ordenar merges conforme dependências;
- executar merge `--no-ff` das branches de tarefa na worktree da sprint;
- resolver conflitos de forma coerente;
- preservar intenção de ambas as branches;
- rodar validações integradas;
- registrar decisões de conflito no ledger;
- fazer push da sprint se configurado/aprovado.

Exemplo conceitual:

```bash
cd .worktrees/sprint-cadastro-aluno
git merge --no-ff task/cadastro-aluno/backend-api
git merge --no-ff task/cadastro-aluno/frontend-form
```

## 11. Validação integrada

Na worktree da sprint, detectar e rodar comandos conforme stack:

Laravel/PHP:

```bash
composer test
php artisan test
vendor/bin/pint --test
vendor/bin/phpstan analyse
```

Node/React:

```bash
npm run lint
npm run build
npm test
npm run typecheck
```

Docker/infra:

```bash
docker compose config
```

A detecção deve observar arquivos como:

- `composer.json`;
- `package.json`;
- `artisan`;
- `vite.config.*`;
- `next.config.*`;
- `docker-compose.yml`;
- `Makefile`;
- `justfile`.

## 12. Cleanup

Após confirmação do merge e aprovação humana:

- remover worktrees de tarefa;
- opcionalmente remover worktree da sprint;
- preservar branches por padrão, salvo confirmação explícita;
- arquivar ledger.

Nada deve ser apagado sem confirmação clara.

## 13. Ledger da sprint

Estrutura sugerida:

```json
{
  "sprint": {
    "name": "cadastro-aluno",
    "baseBranch": "main",
    "branch": "sprint/cadastro-aluno",
    "worktree": ".worktrees/sprint-cadastro-aluno",
    "status": "planning"
  },
  "tasks": [
    {
      "id": "backend-api",
      "title": "Criar endpoints de cadastro",
      "agent": "backend-specialist",
      "branch": "task/cadastro-aluno/backend-api",
      "worktree": ".worktrees/task-cadastro-aluno-backend-api",
      "status": "planned",
      "dependsOn": [],
      "parallelGroup": 1,
      "affectedFiles": [],
      "changedFiles": [],
      "validation": []
    }
  ],
  "parallelGroups": [],
  "approvals": [],
  "events": []
}
```

## 14. UI/TUI desejada

A extensão deve fornecer uma UI persistente de acompanhamento, inspirada nos widgets de `agent-chain` e `agent-team`.

### 14.1 Widget principal

Deve mostrar:

```txt
Sprint: cadastro-aluno  Base: main  Branch: sprint/cadastro-aluno
Worktree: .worktrees/sprint-cadastro-aluno

Fases:
[✓] Init  [●] Planning  [ ] Approval  [ ] Task WT  [ ] Run  [ ] Review  [ ] Integrate  [ ] Validate  [ ] Finish

Grupos paralelos:
G1: backend-api ○ | frontend-form ○
G2: integration-tests ○
G3: security-review ○ | performance-review ○
```

Estados possíveis:

- `○` pendente;
- `●` rodando;
- `✓` concluído;
- `✗` erro;
- `!` bloqueado;
- `?` aguardando aprovação.

### 14.2 Cards de tarefas

Para cada tarefa:

```txt
┌ backend-api ─────────────────────────────┐
│ Agent: backend-specialist                │
│ Branch: task/cadastro-aluno/backend-api  │
│ WT: .worktrees/task-...                  │
│ Status: running  Group: 1                │
│ Validation: pending                      │
└──────────────────────────────────────────┘
```

### 14.3 Status line

A status line deve exibir resumo curto:

```txt
dev: cadastro-aluno | planning | 3 tasks | G1 parallel | awaiting approval
```

### 14.4 Notificações

A extensão deve notificar:

- criação da sprint branch;
- criação da sprint worktree;
- push realizado;
- plano gerado;
- aprovação pendente;
- criação de task worktrees;
- início/fim de grupos paralelos;
- conflitos detectados;
- conflitos resolvidos;
- validações concluídas;
- cleanup pendente/concluído.

### 14.5 Comandos de inspeção

`/dev-status` deve abrir/mostrar:

- sprint atual;
- ledger path;
- branches/worktrees;
- tarefas por grupo;
- validações;
- aprovações pendentes;
- próximos comandos sugeridos.

## 15. Segurança

A solução deve integrar ou coexistir com `damage-control`.

Regras recomendadas:

- bloquear `.env`, `.ssh`, chaves e certificados;
- pedir confirmação para `rm -rf`;
- pedir confirmação para `git reset --hard`;
- pedir confirmação para comandos Docker com remoção de volumes;
- pedir confirmação para comandos SQL destrutivos;
- pedir confirmação para operações AWS destrutivas;
- proteger lockfiles, salvo necessidade explícita.

## 16. Agentes novos permitidos

### 16.1 `plan-reviewer`

Responsável por:

- revisar decomposição das tarefas;
- validar paralelismo;
- identificar dependências ocultas;
- detectar conflito provável de arquivos;
- melhorar critérios de aceite.

### 16.2 `integration-manager`

Responsável por:

- integrar branches de tarefa;
- resolver conflitos;
- rodar validação integrada;
- registrar decisões;
- preparar relatório de merge.

## 17. Etapas de implementação

### Etapa 1 — Documentação da especificação

Criar este documento nos dotfiles.

### Etapa 2 — Implementar `dev-start`

Criar extensão global nos dotfiles com:

- comando `/dev-start`;
- criação/validação de sprint branch;
- criação/validação de sprint worktree;
- ledger inicial;
- UI inicial;
- suporte a `--base`;
- opção/configuração para push.

### Etapa 3 — Planejamento assistido

Adicionar execução de agentes para descoberta e planejamento, ainda sem desenvolvimento automático.

### Etapa 4 — Aprovação e task worktrees

Implementada inicialmente com `/dev-approve-plan` e a ferramenta `dev_save_plan`.

### Etapa 5 — Execução paralela

Implementada inicialmente com `/dev-run`, respeitando grupos paralelos e dependências concluídas.

### Etapa 6 — Revisão, integração e validação

Review implementado inicialmente com `/dev-review`. Integração implementada inicialmente com `/dev-integrate`. Validação implementada inicialmente com `/dev-validate`. Finalização e cleanup implementados com `/dev-finish` e `/dev-cleanup`. Retomada implementada com `/dev-resume`.

### Etapa 7 — Finalização e cleanup

Adicionar `/dev-finish` e `/dev-cleanup` com confirmação.
