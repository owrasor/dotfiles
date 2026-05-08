# Pi Agents

Configuração global de agentes, prompts e extensions do [pi coding agent](https://github.com/badlogic/pi-mono).

Este diretório é versionado nos dotfiles e deve ser linkado para `~/.pi/agent`, mantendo fora do repositório arquivos locais/sensíveis como credenciais, sessões e preferências da máquina.

## Estrutura

```txt
pi/
├── agents/                 # Agentes globais em Markdown
├── extensions/             # Extensions globais do pi
│   ├── subagent/           # Tool para delegar tarefas a agentes especializados
│   └── dev-process/        # Workflow dev-* com git worktree e planejamento de sprint
├── prompts/                # Slash commands globais
├── specs/                  # Especificações versionadas dos workflows/extensions
└── README.md
```

## Agentes disponíveis

- `prd`: cria Product Requirements Documents completos.
- `planner`: transforma PRDs/requisitos em planos de execução técnicos.
- `architect`: cria propostas técnicas e arquiteturais.
- `reviewer`: revisa código, PRDs, planos e propostas.
- `qa`: cria planos de QA, casos de teste e matriz de cobertura.
- `docs`: gera documentação técnica, READMEs, guias, ADRs e runbooks.
- `plan-reviewer`: revisa decomposição de tarefas, dependências, paralelismo e riscos de conflito.
- `integration-manager`: integra branches de tarefa na branch da sprint, resolve conflitos e roda validações.

## Prompts disponíveis

- `/prd <ideia, projeto ou feature>`
- `/plan <PRD, requisito ou feature>`
- `/arch <requisito, PRD ou plano>`
- `/review-artifact <escopo da revisão>`
- `/qa-plan <feature, PRD ou plano>`
- `/docs <tipo de documentação e contexto>`
- `/product-workflow <ideia, projeto ou feature>`
- `/dev-start [--base main] [--push|--no-push] <sprint> <descrição>`
- `/dev-approve-plan [sprint] [--push|--no-push]`
- `/dev-run [sprint] [--group N]`
- `/dev-review [sprint] [--agent reviewer] [--task ID]`
- `/dev-integrate [sprint] [--push|--no-push] [--task ID]`
- `/dev-validate [sprint] [--cmd "comando"] [--list]`
- `/dev-finish [sprint]`
- `/dev-cleanup [sprint] [--include-sprint] [--delete-branches]`
- `/dev-resume [sprint]`
- `/dev-status [sprint]

O fluxo `/product-workflow` executa uma cadeia:

```txt
prd → planner → architect → qa
```

## Instalação manual

A partir do repositório de dotfiles:

```bash
DOTFILES="$HOME/Code/owrasor/dotfiles"
STAMP="$(date +%Y%m%d%H%M%S)"

mkdir -p "$HOME/.pi/agent/extensions"

# Se já existirem diretórios reais, faça backup antes de criar os links.
for target in \
  "$HOME/.pi/agent/agents" \
  "$HOME/.pi/agent/prompts" \
  "$HOME/.pi/agent/extensions/subagent" \
  "$HOME/.pi/agent/extensions/dev-process"
do
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.backup-$STAMP"
  fi
done

ln -sfn "$DOTFILES/pi/agents" "$HOME/.pi/agent/agents"
ln -sfn "$DOTFILES/pi/prompts" "$HOME/.pi/agent/prompts"
ln -sfn "$DOTFILES/pi/extensions/subagent" "$HOME/.pi/agent/extensions/subagent"
ln -sfn "$DOTFILES/pi/extensions/dev-process" "$HOME/.pi/agent/extensions/dev-process"
```

Depois reinicie o pi ou rode dentro dele:

```txt
/reload
```

## Instalação via script principal

O script `../install` já cria esses links automaticamente quando o diretório `pi/` existe.

```bash
cd ~/Code/owrasor/dotfiles
./install
```

## O que não deve ser versionado

Não versionar estes itens locais do pi:

```txt
~/.pi/agent/auth.json
~/.pi/agent/settings.json
~/.pi/agent/sessions/
```

Motivos:

- `auth.json` pode conter credenciais ou tokens.
- `settings.json` pode variar por máquina.
- `sessions/` contém histórico local de conversas.

Esses caminhos estão protegidos no `.gitignore` do repositório caso algum dia sejam copiados para dentro de `pi/`.

## Observações de segurança

Extensions do pi executam código com permissões do usuário local. Revise qualquer extension antes de versionar ou instalar.

Os agentes deste diretório são prompts/instruções. Alguns podem permitir ferramentas de leitura ou comandos seguros; revise o frontmatter de cada agente para confirmar as ferramentas habilitadas.
