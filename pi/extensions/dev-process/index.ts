import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "typebox";
import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const EXT_ID = "dev-process";

type PhaseStatus = "pending" | "running" | "done" | "error" | "blocked" | "approval";

type DevTask = {
	id: string;
	title: string;
	agent?: string;
	branch?: string;
	worktree?: string;
	status: PhaseStatus;
	dependsOn: string[];
	parallelGroup?: number;
	affectedFiles?: string[];
	validation?: string[];
	risks?: string[];
	summary?: string;
	changedFiles?: string[];
	error?: string;
	reviewStatus?: "pending" | "approved" | "changes-requested" | "error";
	reviewSummary?: string;
};

type DevLedger = {
	version: 1;
	createdAt: string;
	updatedAt: string;
	sprint: {
		name: string;
		slug: string;
		description: string;
		baseBranch: string;
		branch: string;
		worktree: string;
		status: PhaseStatus;
		push: boolean;
	};
	phases: Record<string, PhaseStatus>;
	tasks: DevTask[];
	parallelGroups: Array<{ id: number; tasks: string[] }>;
	approvals: Array<{ id: string; status: string; at: string; summary?: string }>;
	validations?: Array<{ command: string; status: "passed" | "failed"; exitCode: number; output: string; elapsed: number; at: string }>;
	events: Array<{ at: string; type: string; message: string; details?: unknown }>;
};

type DevState = {
	ledger?: DevLedger;
	ledgerPath?: string;
	repoRoot?: string;
};

function slugify(input: string): string {
	return input
		.normalize("NFD")
		.replace(/[\u0300-\u036f]/g, "")
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, 80) || "sprint";
}

function now(): string {
	return new Date().toISOString();
}

function parseDevStartArgs(raw: string): { base?: string; push?: boolean; sprintName: string; description: string } | null {
	const tokens = raw.match(/(?:[^\s"]+|"[^"]*")+/g)?.map(t => t.replace(/^"|"$/g, "")) || [];
	let base: string | undefined;
	let push: boolean | undefined;
	const rest: string[] = [];

	for (let i = 0; i < tokens.length; i++) {
		const token = tokens[i];
		if (token === "--base" || token === "-b") {
			base = tokens[++i];
		} else if (token.startsWith("--base=")) {
			base = token.slice("--base=".length);
		} else if (token === "--push") {
			push = true;
		} else if (token === "--no-push") {
			push = false;
		} else {
			rest.push(token);
		}
	}

	if (rest.length < 2) return null;
	return {
		base,
		push,
		sprintName: rest[0],
		description: rest.slice(1).join(" "),
	};
}

function statusIcon(status: PhaseStatus): string {
	switch (status) {
		case "done": return "✓";
		case "running": return "●";
		case "error": return "✗";
		case "blocked": return "!";
		case "approval": return "?";
		default: return "○";
	}
}

function statusColor(status: PhaseStatus): string {
	switch (status) {
		case "done": return "success";
		case "running": return "accent";
		case "error": return "error";
		case "blocked": return "warning";
		case "approval": return "warning";
		default: return "dim";
	}
}

function addEvent(ledger: DevLedger, type: string, message: string, details?: unknown) {
	ledger.events.push({ at: now(), type, message, details });
	ledger.updatedAt = now();
}

async function ensureDir(dir: string) {
	await fs.promises.mkdir(dir, { recursive: true });
}

async function fileExists(filePath: string): Promise<boolean> {
	try {
		await fs.promises.access(filePath);
		return true;
	} catch {
		return false;
	}
}

async function writeLedger(filePath: string, ledger: DevLedger) {
	ledger.updatedAt = now();
	await ensureDir(path.dirname(filePath));
	await fs.promises.writeFile(filePath, JSON.stringify(ledger, null, "\t") + "\n", "utf-8");
}

async function readLedger(filePath: string): Promise<DevLedger> {
	return JSON.parse(await fs.promises.readFile(filePath, "utf-8")) as DevLedger;
}

function normalizeTask(ledger: DevLedger, task: Partial<DevTask> & { id: string; title: string }): DevTask {
	const taskSlug = slugify(task.id);
	return {
		id: task.id,
		title: task.title,
		agent: task.agent,
		branch: task.branch || `task/${ledger.sprint.slug}/${taskSlug}`,
		worktree: task.worktree || path.join(".worktrees", `task-${ledger.sprint.slug}-${taskSlug}`),
		status: task.status || "pending",
		dependsOn: task.dependsOn || [],
		parallelGroup: task.parallelGroup,
		affectedFiles: task.affectedFiles || [],
		validation: task.validation || [],
		risks: task.risks || [],
		summary: task.summary,
		changedFiles: task.changedFiles || [],
		error: task.error,
		reviewStatus: task.reviewStatus,
		reviewSummary: task.reviewSummary,
	};
}

function recomputeParallelGroups(tasks: DevTask[], explicit?: Array<{ id: number; tasks: string[] }>): Array<{ id: number; tasks: string[] }> {
	if (explicit?.length) return explicit;
	const groups = new Map<number, string[]>();
	for (const task of tasks) {
		const group = task.parallelGroup || 1;
		groups.set(group, [...(groups.get(group) || []), task.id]);
	}
	return Array.from(groups.entries()).sort(([a], [b]) => a - b).map(([id, taskIds]) => ({ id, tasks: taskIds }));
}

function parseAgentFile(filePath: string): { name: string; description: string; tools: string; systemPrompt: string } | undefined {
	try {
		const raw = fs.readFileSync(filePath, "utf-8");
		const match = raw.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
		if (!match) return undefined;
		const frontmatter: Record<string, string> = {};
		for (const line of match[1].split("\n")) {
			const idx = line.indexOf(":");
			if (idx > 0) frontmatter[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
		}
		if (!frontmatter.name) return undefined;
		return {
			name: frontmatter.name,
			description: frontmatter.description || "",
			tools: normalizeTools(frontmatter.tools || "read,grep,find,ls,bash,edit,write"),
			systemPrompt: match[2].trim(),
		};
	} catch {
		return undefined;
	}
}

function normalizeTools(raw: string): string {
	const map: Record<string, string> = {
		read: "read", grep: "grep", glob: "find", find: "find", ls: "ls",
		bash: "bash", edit: "edit", write: "write", agent: "",
		viewcodeitem: "read", findbyname: "find",
	};
	const tools = raw.split(",").map(t => t.trim().toLowerCase()).map(t => map[t] ?? t).filter(Boolean);
	return Array.from(new Set(tools)).join(",") || "read,grep,find,ls";
}

function discoverAgent(repoRoot: string, worktreeAbs: string, agentName?: string) {
	if (!agentName) return undefined;
	const dirs = [
		path.join(worktreeAbs, ".pi", "agents"),
		path.join(worktreeAbs, ".agent", "agents"),
		path.join(repoRoot, ".pi", "agents"),
		path.join(repoRoot, ".agent", "agents"),
		path.join(os.homedir(), ".pi", "agent", "agents"),
	];
	for (const dir of dirs) {
		if (!fs.existsSync(dir)) continue;
		for (const file of fs.readdirSync(dir)) {
			if (!file.endsWith(".md")) continue;
			const parsed = parseAgentFile(path.join(dir, file));
			if (parsed && parsed.name.toLowerCase() === agentName.toLowerCase()) return parsed;
		}
	}
	return undefined;
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
	if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}
	const execName = path.basename(process.execPath).toLowerCase();
	const isGenericRuntime = /^(node|bun)(\.exe)?$/.test(execName);
	return isGenericRuntime ? { command: "pi", args } : { command: process.execPath, args };
}

async function findLatestLedger(repoRoot: string): Promise<string | undefined> {
	const dir = path.join(repoRoot, ".pi", "workflows", "sessions");
	if (!(await fileExists(dir))) return undefined;
	const files = (await fs.promises.readdir(dir))
		.filter(f => f.endsWith(".json"))
		.map(f => path.join(dir, f));
	if (files.length === 0) return undefined;
	const stats = await Promise.all(files.map(async file => ({ file, stat: await fs.promises.stat(file) })));
	stats.sort((a, b) => b.stat.mtimeMs - a.stat.mtimeMs);
	return stats[0]?.file;
}

async function runGit(pi: ExtensionAPI, cwd: string, args: string[]) {
	return pi.exec("git", args, { cwd, timeout: 120000 } as any);
}

async function gitOutput(pi: ExtensionAPI, cwd: string, args: string[]): Promise<string> {
	const result = await runGit(pi, cwd, args);
	if (result.code !== 0) {
		throw new Error((result.stderr || result.stdout || `git ${args.join(" ")} failed`).trim());
	}
	return result.stdout.trim();
}

async function detectRepoRoot(pi: ExtensionAPI, cwd: string): Promise<string> {
	return gitOutput(pi, cwd, ["rev-parse", "--show-toplevel"]);
}

async function branchExists(pi: ExtensionAPI, cwd: string, branch: string): Promise<boolean> {
	const result = await runGit(pi, cwd, ["show-ref", "--verify", "--quiet", `refs/heads/${branch}`]);
	return result.code === 0;
}

async function worktreePathExists(worktree: string): Promise<boolean> {
	return fileExists(worktree);
}

async function detectBaseBranch(pi: ExtensionAPI, cwd: string, requested?: string): Promise<string> {
	if (requested) return requested;
	for (const candidate of ["main", "master"]) {
		if (await branchExists(pi, cwd, candidate)) return candidate;
	}
	return gitOutput(pi, cwd, ["branch", "--show-current"]);
}

async function getChangedFiles(pi: ExtensionAPI, worktreeAbs: string, baseBranch: string): Promise<string[]> {
	const result = await runGit(pi, worktreeAbs, ["diff", "--name-only", `${baseBranch}...HEAD`]);
	if (result.code !== 0) return [];
	return result.stdout.split("\n").map(s => s.trim()).filter(Boolean);
}

async function runShell(pi: ExtensionAPI, cwd: string, command: string, timeout = 300000) {
	const started = Date.now();
	const result = await pi.exec("bash", ["-lc", command], { cwd, timeout } as any);
	return {
		command,
		status: result.code === 0 ? "passed" as const : "failed" as const,
		exitCode: result.code,
		output: `${result.stdout || ""}${result.stderr || ""}`.slice(0, 12000),
		elapsed: Date.now() - started,
		at: now(),
	};
}

function compactOutput(output: string, maxLength = 2400): string {
	const normalized = (output || "").replace(/\r\n/g, "\n").trim();
	if (!normalized) return "(sem saída capturada)";
	if (normalized.length <= maxLength) return normalized;
	return `... saída truncada; mostrando os últimos ${maxLength} caracteres ...\n${normalized.slice(-maxLength)}`;
}

function formatPhaseSummary(ledger: DevLedger): string {
	const order = ["init", "discovery", "planning", "approval", "taskWorktrees", "run", "review", "integrate", "validate", "finish"];
	return order.map(key => `${key}:${ledger.phases[key] || "pending"}`).join(" | ");
}

function findFailedValidation(ledger: DevLedger) {
	return (ledger.validations || []).find(v => v.status === "failed");
}

function buildNextStep(ledger: DevLedger): string {
	const failedValidation = findFailedValidation(ledger);
	if (failedValidation) {
		return [
			`Corrija a falha do comando \`${failedValidation.command}\` na worktree da sprint \`${ledger.sprint.worktree}\`.`,
			`Depois rode novamente: /dev-validate ${ledger.sprint.slug} --cmd "${failedValidation.command.replace(/"/g, '\\"')}"`,
			"Se o comando detectado estiver errado, use /dev-validate --list ou informe o comando correto com --cmd.",
		].join("\n");
	}

	const erroredTask = ledger.tasks.find(t => t.status === "error");
	if (erroredTask) return `Corrija/reexecute a tarefa ${erroredTask.id} na worktree ${erroredTask.worktree}. Depois rode /dev-run ${ledger.sprint.slug}${erroredTask.parallelGroup ? ` --group ${erroredTask.parallelGroup}` : ""}.`;

	const blockedReview = ledger.tasks.find(t => t.reviewStatus === "changes-requested" || t.reviewStatus === "error" || t.status === "blocked");
	if (blockedReview) return `Ajuste a tarefa ${blockedReview.id} conforme o review. Depois rode /dev-run ${ledger.sprint.slug}${blockedReview.parallelGroup ? ` --group ${blockedReview.parallelGroup}` : ""} e /dev-review ${ledger.sprint.slug} --task ${blockedReview.id}.`;

	if (ledger.phases.approval === "approval") return `/dev-approve-plan ${ledger.sprint.slug}`;
	if (ledger.phases.run === "approval" || getRunnableGroup(ledger)) return `/dev-run ${ledger.sprint.slug}`;
	if (ledger.phases.review === "approval") return `/dev-review ${ledger.sprint.slug}`;
	if (ledger.phases.integrate === "approval") return `/dev-integrate ${ledger.sprint.slug}`;
	if (ledger.phases.validate === "approval") return `/dev-validate ${ledger.sprint.slug}`;
	if (ledger.phases.finish === "approval") return `/dev-finish ${ledger.sprint.slug}`;
	if (ledger.sprint.status === "done") return `/dev-cleanup ${ledger.sprint.slug}`;
	return "/dev-status";
}

function formatDetailedStatus(ledger: DevLedger, ledgerPath?: string): string {
	const tasks = ledger.tasks.length
		? ledger.tasks.map(t => {
			const parts = [`- ${t.id}: ${t.status}`, `agent:${t.agent || "n/a"}`, `review:${t.reviewStatus || "n/a"}`];
			if (t.worktree) parts.push(`worktree:${t.worktree}`);
			if (t.error) parts.push(`\n  Erro: ${compactOutput(t.error, 900)}`);
			if (t.reviewStatus === "changes-requested" || t.reviewStatus === "error") parts.push(`\n  Review: ${compactOutput(t.reviewSummary || "", 900)}`);
			return parts.join(" | ");
		}).join("\n")
		: "- Nenhuma tarefa planejada ainda.";
	const validations = ledger.validations?.length
		? ledger.validations.map(v => {
			const line = `- ${v.status === "passed" ? "✓" : "✗"} ${v.command} — status:${v.status} exit:${v.exitCode} tempo:${Math.round(v.elapsed / 1000)}s`;
			return v.status === "failed" ? `${line}\n  Saída:\n${compactOutput(v.output, 2400).split("\n").map(l => `  ${l}`).join("\n")}` : line;
		}).join("\n")
		: "- Nenhuma validação executada.";
	const recentEvents = ledger.events.slice(-5).map(e => `- ${e.at} [${e.type}] ${e.message}`).join("\n") || "- Nenhum evento.";
	return `Sprint: ${ledger.sprint.name}\nStatus: ${ledger.sprint.status}\nBranch: ${ledger.sprint.branch}\nWorktree: ${ledger.sprint.worktree}\nLedger: ${ledgerPath || "n/a"}\n\nFases:\n${formatPhaseSummary(ledger)}\n\nTarefas:\n${tasks}\n\nValidações:\n${validations}\n\nEventos recentes:\n${recentEvents}\n\nPróximo passo sugerido:\n${buildNextStep(ledger)}`;
}

async function detectValidationCommands(worktreeAbs: string, tasks: DevTask[]): Promise<string[]> {
	const commands = new Set<string>();
	for (const task of tasks) for (const cmd of task.validation || []) if (cmd.trim()) commands.add(cmd.trim());

	const has = (rel: string) => fs.existsSync(path.join(worktreeAbs, rel));
	if (has("composer.json")) {
		try {
			const composer = JSON.parse(await fs.promises.readFile(path.join(worktreeAbs, "composer.json"), "utf-8"));
			const scripts = composer.scripts || {};
			if (scripts.test) commands.add("composer test");
			if (has("artisan")) commands.add("php artisan test");
			if (has("vendor/bin/pint")) commands.add("vendor/bin/pint --test");
			if (has("vendor/bin/phpstan")) commands.add("vendor/bin/phpstan analyse");
		} catch {}
	}
	if (has("package.json")) {
		try {
			const pkg = JSON.parse(await fs.promises.readFile(path.join(worktreeAbs, "package.json"), "utf-8"));
			const scripts = pkg.scripts || {};
			if (scripts.lint) commands.add("npm run lint");
			if (scripts.typecheck) commands.add("npm run typecheck");
			if (scripts.build) commands.add("npm run build");
			if (scripts.test) commands.add("npm test");
		} catch {}
	}
	if (has("docker-compose.yml") || has("docker-compose.yaml") || has("compose.yml") || has("compose.yaml")) {
		commands.add("docker compose config");
	}
	return Array.from(commands);
}

function getRunnableGroup(ledger: DevLedger, requestedGroup?: number): { id: number; tasks: DevTask[] } | undefined {
	const done = new Set(ledger.tasks.filter(t => t.status === "done").map(t => t.id));
	const groups = recomputeParallelGroups(ledger.tasks, ledger.parallelGroups);
	for (const group of groups) {
		if (requestedGroup !== undefined && group.id !== requestedGroup) continue;
		const tasks = group.tasks.map(id => ledger.tasks.find(t => t.id === id)).filter(Boolean) as DevTask[];
		const pending = tasks.filter(t => t.status === "pending" || t.status === "blocked");
		if (pending.length === 0) continue;
		const depsMet = pending.every(t => (t.dependsOn || []).every(dep => done.has(dep)));
		if (depsMet) return { id: group.id, tasks: pending };
		if (requestedGroup !== undefined) return undefined;
	}
	return undefined;
}

function createInitialLedger(input: {
	sprintName: string;
	description: string;
	baseBranch: string;
	slug: string;
	sprintBranch: string;
	sprintWorktreeRel: string;
	push: boolean;
}): DevLedger {
	return {
		version: 1,
		createdAt: now(),
		updatedAt: now(),
		sprint: {
			name: input.sprintName,
			slug: input.slug,
			description: input.description,
			baseBranch: input.baseBranch,
			branch: input.sprintBranch,
			worktree: input.sprintWorktreeRel,
			status: "running",
			push: input.push,
		},
		phases: {
			init: "running",
			discovery: "pending",
			planning: "pending",
			approval: "pending",
			taskWorktrees: "pending",
			run: "pending",
			review: "pending",
			integrate: "pending",
			validate: "pending",
			finish: "pending",
		},
		tasks: [],
		parallelGroups: [],
		approvals: [],
		validations: [],
		events: [],
	};
}

function renderWidget(state: DevState, theme: any): Text {
	const ledger = state.ledger;
	if (!ledger) return new Text("", 0, 0);

	const phaseOrder: Array<[string, string]> = [
		["init", "Init"],
		["discovery", "Discovery"],
		["planning", "Planning"],
		["approval", "Approval"],
		["taskWorktrees", "Task WT"],
		["run", "Run"],
		["review", "Review"],
		["integrate", "Integrate"],
		["validate", "Validate"],
		["finish", "Finish"],
	];

	const phases = phaseOrder.map(([key, label]) => {
		const st = ledger.phases[key] || "pending";
		return theme.fg(statusColor(st), `[${statusIcon(st)}] ${label}`);
	}).join(theme.fg("dim", "  "));

	const groups = ledger.parallelGroups.length > 0
		? ledger.parallelGroups.map(g => {
			const taskText = g.tasks.map(id => {
				const task = ledger.tasks.find(t => t.id === id);
				const st = task?.status || "pending";
				return theme.fg(statusColor(st), `${id} ${statusIcon(st)}`);
			}).join(theme.fg("dim", " | "));
			return `G${g.id}: ${taskText}`;
		}).join("\n")
		: theme.fg("dim", "Nenhum grupo paralelo definido ainda.");

	const taskLines = ledger.tasks.slice(0, 6).map(task => {
		const agent = task.agent ? theme.fg("muted", ` @${task.agent}`) : "";
		const group = task.parallelGroup ? theme.fg("dim", ` G${task.parallelGroup}`) : "";
		return theme.fg(statusColor(task.status), `${statusIcon(task.status)} ${task.id}`) + agent + group;
	});
	if (ledger.tasks.length > 6) taskLines.push(theme.fg("dim", `... +${ledger.tasks.length - 6} tarefas`));

	const latest = ledger.events.at(-1)?.message || "Aguardando ações.";
	const lines = [
		theme.fg("accent", theme.bold(`dev: ${ledger.sprint.name}`)) + theme.fg("dim", ` | base ${ledger.sprint.baseBranch} | ${ledger.sprint.branch}`),
		theme.fg("dim", `worktree: ${ledger.sprint.worktree}`),
		phases,
		theme.fg("muted", "Grupos paralelos:"),
		groups,
		theme.fg("muted", "Tarefas:"),
		taskLines.length ? taskLines.join("\n") : theme.fg("dim", "Nenhuma tarefa planejada ainda."),
		theme.fg("dim", `Último evento: ${latest}`),
	];

	return new Text(lines.join("\n"), 0, 0);
}

function runTaskAgent(pi: ExtensionAPI, ctx: any, ledger: DevLedger, repoRoot: string, task: DevTask): Promise<{ output: string; exitCode: number; elapsed: number }> {
	const worktreeAbs = path.join(repoRoot, task.worktree || "");
	const agent = discoverAgent(repoRoot, worktreeAbs, task.agent);
	const model = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
	const tools = agent?.tools || "read,grep,find,ls,bash,edit,write";
	const systemPrompt = [
		agent?.systemPrompt || `Você é o agente responsável pela tarefa ${task.id}.`,
		"",
		"## Regras do workflow dev-process",
		`- Trabalhe somente nesta worktree: ${task.worktree}`,
		`- Branch da tarefa: ${task.branch}`,
		`- Branch base/sprint: ${ledger.sprint.branch}`,
		"- Não faça merge para a sprint nem para main.",
		"- Não remova worktrees ou branches.",
		"- Mantenha o escopo da tarefa; evite alterar arquivos não relacionados.",
		"- Rode as validações listadas quando possível.",
		"- Ao final, responda com resumo, arquivos alterados, validações executadas e riscos.",
	].join("\n");

	const prompt = [
		`Sprint: ${ledger.sprint.name}`,
		`Descrição da sprint: ${ledger.sprint.description}`,
		`Tarefa: ${task.id} — ${task.title}`,
		`Agente responsável: ${task.agent || "não especificado"}`,
		`Dependências já atendidas: ${(task.dependsOn || []).join(", ") || "nenhuma"}`,
		`Arquivos previstos: ${(task.affectedFiles || []).join(", ") || "não especificado"}`,
		`Validações esperadas:\n${(task.validation || []).map(v => `- ${v}`).join("\n") || "- não especificado"}`,
		`Riscos conhecidos:\n${(task.risks || []).map(r => `- ${r}`).join("\n") || "- nenhum registrado"}`,
		"",
		"Implemente esta tarefa agora nesta worktree. Faça commits somente se for explicitamente necessário pelo workflow; caso contrário deixe as alterações na branch da tarefa e reporte o resultado.",
	].join("\n");

	const args = ["--mode", "json", "-p", "--no-extensions", "--tools", tools, "--thinking", "off", "--append-system-prompt", systemPrompt];
	if (model) args.push("--model", model);
	args.push(prompt);
	const invocation = getPiInvocation(args);
	const started = Date.now();
	const chunks: string[] = [];
	let stderr = "";

	return new Promise(resolve => {
		const proc = spawn(invocation.command, invocation.args, { cwd: worktreeAbs, stdio: ["ignore", "pipe", "pipe"], env: { ...process.env } });
		let buffer = "";
		proc.stdout.setEncoding("utf-8");
		proc.stdout.on("data", (chunk: string) => {
			buffer += chunk;
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) {
				if (!line.trim()) continue;
				try {
					const event = JSON.parse(line);
					if (event.type === "message_update") {
						const delta = event.assistantMessageEvent;
						if (delta?.type === "text_delta") chunks.push(delta.delta || "");
					}
				} catch {}
			}
		});
		proc.stderr.setEncoding("utf-8");
		proc.stderr.on("data", (chunk: string) => { stderr += chunk; });
		proc.on("close", code => {
			resolve({ output: chunks.join("") || stderr, exitCode: code ?? 1, elapsed: Date.now() - started });
		});
		proc.on("error", error => {
			resolve({ output: `Erro ao iniciar agente: ${error.message}`, exitCode: 1, elapsed: Date.now() - started });
		});
	});
}

function runReviewAgent(pi: ExtensionAPI, ctx: any, ledger: DevLedger, repoRoot: string, task: DevTask, reviewerName: string): Promise<{ output: string; exitCode: number; elapsed: number }> {
	const worktreeAbs = path.join(repoRoot, task.worktree || "");
	const agent = discoverAgent(repoRoot, worktreeAbs, reviewerName);
	const model = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
	const tools = normalizeTools(agent?.tools || "read,grep,find,ls,bash").split(",").filter(t => !["edit", "write"].includes(t)).join(",") || "read,grep,find,ls,bash";
	const systemPrompt = [
		agent?.systemPrompt || "Você é um revisor técnico rigoroso.",
		"",
		"## Regras do review dev-process",
		"- Faça revisão read-only. Não altere arquivos.",
		"- Avalie corretude, segurança, testes, escopo e risco de regressão.",
		"- Compare a branch da tarefa com a branch da sprint quando útil.",
		"- Se encontrar problemas bloqueantes, use exatamente o marcador CHANGES_REQUESTED.",
		"- Se aprovar, use exatamente o marcador APPROVED.",
	].join("\n");
	const prompt = [
		`Sprint: ${ledger.sprint.name}`,
		`Branch da sprint: ${ledger.sprint.branch}`,
		`Tarefa: ${task.id} — ${task.title}`,
		`Branch da tarefa: ${task.branch}`,
		`Worktree: ${task.worktree}`,
		`Arquivos alterados registrados: ${(task.changedFiles || []).join(", ") || "não registrado"}`,
		`Resumo da implementação:\n${task.summary || "não informado"}`,
		"",
		"Revise a implementação desta tarefa. Não altere arquivos. Ao final, responda com APPROVED ou CHANGES_REQUESTED, seguido de justificativa, riscos e validações recomendadas.",
	].join("\n");
	const args = ["--mode", "json", "-p", "--no-extensions", "--tools", tools, "--thinking", "off", "--append-system-prompt", systemPrompt];
	if (model) args.push("--model", model);
	args.push(prompt);
	const invocation = getPiInvocation(args);
	const started = Date.now();
	const chunks: string[] = [];
	let stderr = "";
	return new Promise(resolve => {
		const proc = spawn(invocation.command, invocation.args, { cwd: worktreeAbs, stdio: ["ignore", "pipe", "pipe"], env: { ...process.env } });
		let buffer = "";
		proc.stdout.setEncoding("utf-8");
		proc.stdout.on("data", (chunk: string) => {
			buffer += chunk;
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) {
				if (!line.trim()) continue;
				try {
					const event = JSON.parse(line);
					if (event.type === "message_update") {
						const delta = event.assistantMessageEvent;
						if (delta?.type === "text_delta") chunks.push(delta.delta || "");
					}
				} catch {}
			}
		});
		proc.stderr.setEncoding("utf-8");
		proc.stderr.on("data", (chunk: string) => { stderr += chunk; });
		proc.on("close", code => resolve({ output: chunks.join("") || stderr, exitCode: code ?? 1, elapsed: Date.now() - started }));
		proc.on("error", error => resolve({ output: `Erro ao iniciar revisor: ${error.message}`, exitCode: 1, elapsed: Date.now() - started }));
	});
}

function runIntegrationAgent(pi: ExtensionAPI, ctx: any, ledger: DevLedger, repoRoot: string, branches: string[], mergeOutput: string): Promise<{ output: string; exitCode: number; elapsed: number }> {
	const sprintWorktreeAbs = path.join(repoRoot, ledger.sprint.worktree);
	const agent = discoverAgent(repoRoot, sprintWorktreeAbs, "integration-manager");
	const model = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
	const tools = agent?.tools || "read,grep,find,ls,bash,edit,write";
	const systemPrompt = [
		agent?.systemPrompt || "Você é um integration-manager responsável por resolver conflitos de merge com segurança.",
		"",
		"## Regras do dev-integrate",
		`- Trabalhe somente na worktree da sprint: ${ledger.sprint.worktree}`,
		`- Branch da sprint: ${ledger.sprint.branch}`,
		"- Resolva conflitos preservando a intenção das branches de tarefa.",
		"- Não faça merge para main/master.",
		"- Não remova branches nem worktrees.",
		"- Se a resolução for ambígua, pare e explique o bloqueio.",
		"- Após resolver, deixe os arquivos prontos para commit de merge.",
	].join("\n");
	const prompt = [
		`Sprint: ${ledger.sprint.name}`,
		`Descrição: ${ledger.sprint.description}`,
		`Branch da sprint: ${ledger.sprint.branch}`,
		`Branches em integração: ${branches.join(", ")}`,
		"",
		"O merge encontrou conflitos ou precisa de intervenção. Resolva os conflitos nesta worktree da sprint.",
		"",
		"Saída do git merge:",
		mergeOutput,
		"",
		"Tarefas aprovadas:",
		ledger.tasks.filter(t => branches.includes(t.branch || "")).map(t => `- ${t.id}: ${t.title}\n  arquivos: ${(t.changedFiles || []).join(", ") || "n/a"}\n  resumo: ${(t.summary || "").slice(0, 1000)}`).join("\n"),
		"",
		"Resolva os conflitos. Ao final, responda com um relatório das decisões tomadas. Não faça push.",
	].join("\n");
	const args = ["--mode", "json", "-p", "--no-extensions", "--tools", tools, "--thinking", "off", "--append-system-prompt", systemPrompt];
	if (model) args.push("--model", model);
	args.push(prompt);
	const invocation = getPiInvocation(args);
	const started = Date.now();
	const chunks: string[] = [];
	let stderr = "";
	return new Promise(resolve => {
		const proc = spawn(invocation.command, invocation.args, { cwd: sprintWorktreeAbs, stdio: ["ignore", "pipe", "pipe"], env: { ...process.env } });
		let buffer = "";
		proc.stdout.setEncoding("utf-8");
		proc.stdout.on("data", (chunk: string) => {
			buffer += chunk;
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) {
				if (!line.trim()) continue;
				try {
					const event = JSON.parse(line);
					if (event.type === "message_update") {
						const delta = event.assistantMessageEvent;
						if (delta?.type === "text_delta") chunks.push(delta.delta || "");
					}
				} catch {}
			}
		});
		proc.stderr.setEncoding("utf-8");
		proc.stderr.on("data", (chunk: string) => { stderr += chunk; });
		proc.on("close", code => resolve({ output: chunks.join("") || stderr, exitCode: code ?? 1, elapsed: Date.now() - started }));
		proc.on("error", error => resolve({ output: `Erro ao iniciar integration-manager: ${error.message}`, exitCode: 1, elapsed: Date.now() - started }));
	});
}

function startPlanningPrompt(pi: ExtensionAPI, ledger: DevLedger, ledgerPath: string) {
	const prompt = `Inicie a fase de descoberta e planejamento da sprint abaixo, sem alterar código ainda.\n\n` +
		`Sprint: ${ledger.sprint.name}\n` +
		`Descrição: ${ledger.sprint.description}\n` +
		`Branch da sprint: ${ledger.sprint.branch}\n` +
		`Worktree da sprint: ${ledger.sprint.worktree}\n` +
		`Ledger: ${ledgerPath}\n\n` +
		`Objetivo agora:\n` +
		`1. analisar o repositório usando a worktree da sprint;\n` +
		`2. propor tarefas com IDs estáveis;\n` +
		`3. identificar dependências entre tarefas;\n` +
		`4. identificar quais tarefas podem rodar em paralelo;\n` +
		`5. sugerir agentes responsáveis;\n` +
		`6. sugerir branches/worktrees de tarefa;\n` +
		`7. listar validações e riscos;\n` +
		`8. salvar o plano estruturado usando a ferramenta dev_save_plan;\n` +
		`9. não executar desenvolvimento nem criar worktrees de tarefa ainda;\n` +
		`10. ao final, peça aprovação humana para avançar com /dev-approve-plan.\n\n` +
		`Use a especificação global em pi/specs/software-dev-process.md se estiver disponível nos dotfiles.`;

	pi.sendUserMessage(prompt);
}

export default function (pi: ExtensionAPI) {
	const state: DevState = {};
	let widgetCtx: any;

	function updateUi(ctx?: any) {
		const target = ctx || widgetCtx;
		if (!target) return;
		widgetCtx = target;
		if (!state.ledger) {
			target.ui.setWidget(EXT_ID, undefined);
			target.ui.setStatus(EXT_ID, undefined);
			return;
		}
		target.ui.setWidget(EXT_ID, (_tui: any, theme: any) => renderWidget(state, theme));
		target.ui.setStatus(EXT_ID, `dev: ${state.ledger.sprint.slug} | ${state.ledger.sprint.status}`);
	}

	pi.on("session_start", async (_event, ctx) => {
		widgetCtx = ctx;
		updateUi(ctx);
	});

	async function ensureActiveLedger(ctx: any, sprintSlug?: string): Promise<boolean> {
		if (state.ledger && state.ledgerPath && state.repoRoot) return true;
		try {
			const repoRoot = await detectRepoRoot(pi, ctx.cwd);
			const ledgerPath = sprintSlug
				? path.join(repoRoot, ".pi", "workflows", "sessions", `${slugify(sprintSlug)}.json`)
				: await findLatestLedger(repoRoot);
			if (!ledgerPath || !(await fileExists(ledgerPath))) {
				ctx.ui.notify("Nenhum ledger dev encontrado. Inicie com /dev-start.", "warning");
				return false;
			}
			state.repoRoot = repoRoot;
			state.ledgerPath = ledgerPath;
			state.ledger = await readLedger(ledgerPath);
			updateUi(ctx);
			return true;
		} catch (error) {
			ctx.ui.notify(`Falha ao carregar ledger dev: ${error instanceof Error ? error.message : String(error)}`, "error");
			return false;
		}
	}

	pi.registerTool({
		name: "dev_save_plan",
		label: "Save Dev Plan",
		description: "Salva no ledger da sprint o plano estruturado com tarefas, dependências e grupos paralelos. Use após planejar e antes de pedir aprovação humana.",
		parameters: Type.Object({
			sprintSlug: Type.Optional(Type.String({ description: "Slug/nome da sprint. Opcional se já houver sprint ativa." })),
			tasks: Type.Array(Type.Object({
				id: Type.String({ description: "ID estável da tarefa, ex: backend-api ou T-001" }),
				title: Type.String({ description: "Título/objetivo da tarefa" }),
				agent: Type.Optional(Type.String({ description: "Agente responsável sugerido" })),
				branch: Type.Optional(Type.String({ description: "Branch da tarefa. Se omitida será gerada." })),
				worktree: Type.Optional(Type.String({ description: "Worktree da tarefa. Se omitida será gerada." })),
				dependsOn: Type.Optional(Type.Array(Type.String())),
				parallelGroup: Type.Optional(Type.Number({ description: "Grupo paralelo de execução" })),
				affectedFiles: Type.Optional(Type.Array(Type.String())),
				validation: Type.Optional(Type.Array(Type.String())),
				risks: Type.Optional(Type.Array(Type.String())),
			})),
			parallelGroups: Type.Optional(Type.Array(Type.Object({
				id: Type.Number(),
				tasks: Type.Array(Type.String()),
			}))),
			summary: Type.Optional(Type.String({ description: "Resumo curto do plano" })),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const input = params as {
				sprintSlug?: string;
				tasks: Array<Partial<DevTask> & { id: string; title: string }>;
				parallelGroups?: Array<{ id: number; tasks: string[] }>;
				summary?: string;
			};
			if (!(await ensureActiveLedger(ctx, input.sprintSlug))) {
				return { content: [{ type: "text", text: "Nenhum ledger dev ativo para salvar o plano." }] };
			}
			const ledger = state.ledger!;
			ledger.tasks = input.tasks.map(task => normalizeTask(ledger, task));
			ledger.parallelGroups = recomputeParallelGroups(ledger.tasks, input.parallelGroups);
			ledger.phases.discovery = "done";
			ledger.phases.planning = "done";
			ledger.phases.approval = "approval";
			ledger.sprint.status = "approval";
			addEvent(ledger, "plan", `Plano salvo com ${ledger.tasks.length} tarefa(s)`, { summary: input.summary });
			await writeLedger(state.ledgerPath!, ledger);
			updateUi(ctx);
			return {
				content: [{ type: "text", text: `Plano salvo no ledger. Tarefas: ${ledger.tasks.length}. Próximo passo: peça aprovação humana e execute /dev-approve-plan.` }],
				details: { tasks: ledger.tasks, parallelGroups: ledger.parallelGroups, ledgerPath: state.ledgerPath },
			};
		},
		renderCall(args, theme) {
			const count = Array.isArray((args as any).tasks) ? (args as any).tasks.length : 0;
			return new Text(theme.fg("toolTitle", theme.bold("dev_save_plan ")) + theme.fg("accent", `${count} tarefa(s)`), 0, 0);
		},
	});

	pi.registerCommand("dev-start", {
		description: "Inicia uma sprint de desenvolvimento com branch/worktree e planejamento assistido. Uso: /dev-start [--base main] [--push|--no-push] <sprint> <descrição>",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;

			const parsed = parseDevStartArgs(args || "");
			if (!parsed) {
				ctx.ui.notify("Uso: /dev-start [--base main] [--push|--no-push] <sprint> <descrição>", "warning");
				return;
			}

			let repoRoot: string;
			try {
				repoRoot = await detectRepoRoot(pi, ctx.cwd);
			} catch (error) {
				ctx.ui.notify(`dev-start: diretório atual não é um repositório Git (${error instanceof Error ? error.message : String(error)})`, "error");
				return;
			}

			const porcelain = await gitOutput(pi, repoRoot, ["status", "--porcelain"]);
			if (porcelain.trim()) {
				const ok = await ctx.ui.confirm(
					"Repositório com alterações locais",
					"O repositório atual possui alterações não commitadas. A sprint será criada a partir da branch base em uma worktree separada, mas é recomendado revisar o estado atual antes. Continuar?",
				);
				if (!ok) return;
			}

			const slug = slugify(parsed.sprintName);
			const baseBranch = await detectBaseBranch(pi, repoRoot, parsed.base);
			const sprintBranch = `sprint/${slug}`;
			const sprintWorktreeRel = path.join(".worktrees", `sprint-${slug}`);
			const sprintWorktreeAbs = path.join(repoRoot, sprintWorktreeRel);
			const ledgerPath = path.join(repoRoot, ".pi", "workflows", "sessions", `${slug}.json`);
			const push = parsed.push ?? true;

			if (await branchExists(pi, repoRoot, sprintBranch)) {
				const ok = await ctx.ui.confirm("Branch de sprint já existe", `A branch ${sprintBranch} já existe. Usar a branch existente e garantir a worktree?`);
				if (!ok) return;
			}

			if (await worktreePathExists(sprintWorktreeAbs)) {
				const ok = await ctx.ui.confirm("Worktree de sprint já existe", `A worktree ${sprintWorktreeRel} já existe. Reutilizar?`);
				if (!ok) return;
			}

			state.repoRoot = repoRoot;
			state.ledgerPath = ledgerPath;
			state.ledger = createInitialLedger({
				sprintName: parsed.sprintName,
				description: parsed.description,
				baseBranch,
				slug,
				sprintBranch,
				sprintWorktreeRel,
				push,
			});
			addEvent(state.ledger, "init", "Ledger inicial criado", { ledgerPath });
			await writeLedger(ledgerPath, state.ledger);
			updateUi(ctx);

			await ensureDir(path.join(repoRoot, ".worktrees"));

			try {
				await runGit(pi, repoRoot, ["fetch", "origin"]);
			} catch {
				// Repositórios sem remote continuam suportados.
			}

			const branchAlreadyExists = await branchExists(pi, repoRoot, sprintBranch);
			if (!(await worktreePathExists(sprintWorktreeAbs))) {
				const baseRef = baseBranch;
				const argsForWorktree = branchAlreadyExists
					? ["worktree", "add", sprintWorktreeRel, sprintBranch]
					: ["worktree", "add", "-b", sprintBranch, sprintWorktreeRel, baseRef];
				const wtResult = await runGit(pi, repoRoot, argsForWorktree);
				if (wtResult.code !== 0) throw new Error((wtResult.stderr || wtResult.stdout).trim());
				addEvent(state.ledger, "worktree", `Worktree da sprint criada: ${sprintWorktreeRel}`);
			} else {
				addEvent(state.ledger, "worktree", `Worktree da sprint reutilizada: ${sprintWorktreeRel}`);
			}

			if (push) {
				const pushResult = await runGit(pi, repoRoot, ["push", "-u", "origin", sprintBranch]);
				if (pushResult.code === 0) {
					addEvent(state.ledger, "push", `Branch enviada para origin: ${sprintBranch}`);
				} else {
					addEvent(state.ledger, "push-warning", `Push não concluído: ${(pushResult.stderr || pushResult.stdout).trim()}`);
					ctx.ui.notify(`dev-start: branch criada localmente, mas push falhou: ${(pushResult.stderr || pushResult.stdout).trim()}`, "warning");
				}
			}

			state.ledger.phases.init = "done";
			state.ledger.phases.discovery = "running";
			state.ledger.phases.planning = "running";
			state.ledger.sprint.status = "running";
			addEvent(state.ledger, "planning", "Sprint inicializada; planejamento assistido será iniciado");
			await writeLedger(ledgerPath, state.ledger);
			updateUi(ctx);

			ctx.ui.notify(
				`Sprint iniciada: ${parsed.sprintName}\nBranch: ${sprintBranch}\nWorktree: ${sprintWorktreeRel}\nLedger: ${path.relative(repoRoot, ledgerPath)}`,
				"success",
			);

			startPlanningPrompt(pi, state.ledger, path.relative(repoRoot, ledgerPath));
		},
	});

	pi.registerCommand("dev-approve-plan", {
		description: "Aprova o plano salvo e cria branches/worktrees das tarefas. Uso: /dev-approve-plan [sprint] [--push|--no-push]",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;
			const tokens = (args || "").match(/(?:[^\s"]+|"[^"]*")+/g)?.map(t => t.replace(/^"|"$/g, "")) || [];
			let pushOverride: boolean | undefined;
			const positional: string[] = [];
			for (const token of tokens) {
				if (token === "--push") pushOverride = true;
				else if (token === "--no-push") pushOverride = false;
				else positional.push(token);
			}

			if (!(await ensureActiveLedger(ctx, positional[0]))) return;
			const ledger = state.ledger!;
			const repoRoot = state.repoRoot!;
			const ledgerPath = state.ledgerPath!;

			if (ledger.tasks.length === 0) {
				ctx.ui.notify("O ledger ainda não possui tarefas. Peça ao agente para salvar o plano com dev_save_plan antes de aprovar.", "warning");
				return;
			}

			const pushTasks = pushOverride ?? ledger.sprint.push;
			const summary = ledger.tasks.map(task => {
				const deps = task.dependsOn.length ? ` deps: ${task.dependsOn.join(",")}` : "";
				return `- ${task.id}: ${task.title}\n  agent: ${task.agent || "n/a"}\n  branch: ${task.branch}\n  worktree: ${task.worktree}\n  group: ${task.parallelGroup || 1}${deps}`;
			}).join("\n");

			const ok = await ctx.ui.confirm(
				"Aprovar plano dev?",
				`Sprint: ${ledger.sprint.name}\nBranch: ${ledger.sprint.branch}\nWorktree: ${ledger.sprint.worktree}\nPush task branches: ${pushTasks ? "sim" : "não"}\n\n${summary}\n\nCriar branches/worktrees das tarefas agora?`,
			);
			if (!ok) return;

			ledger.phases.approval = "running";
			ledger.phases.taskWorktrees = "running";
			ledger.sprint.status = "running";
			addEvent(ledger, "approval", "Plano aprovado pelo usuário");
			ledger.approvals.push({ id: `plan-${Date.now()}`, status: "approved", at: now(), summary: `${ledger.tasks.length} tarefa(s) aprovadas` });
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);

			await ensureDir(path.join(repoRoot, ".worktrees"));
			for (const task of ledger.tasks) {
				task.status = "running";
				updateUi(ctx);
				const branch = task.branch || `task/${ledger.sprint.slug}/${slugify(task.id)}`;
				const worktreeRel = task.worktree || path.join(".worktrees", `task-${ledger.sprint.slug}-${slugify(task.id)}`);
				task.branch = branch;
				task.worktree = worktreeRel;
				const worktreeAbs = path.join(repoRoot, worktreeRel);
				const existsBranch = await branchExists(pi, repoRoot, branch);

				if (!(await worktreePathExists(worktreeAbs))) {
					const wtArgs = existsBranch
						? ["worktree", "add", worktreeRel, branch]
						: ["worktree", "add", "-b", branch, worktreeRel, ledger.sprint.branch];
					const wtResult = await runGit(pi, repoRoot, wtArgs);
					if (wtResult.code !== 0) {
						task.status = "error";
						addEvent(ledger, "task-worktree-error", `Falha ao criar worktree da tarefa ${task.id}`, { stderr: wtResult.stderr, stdout: wtResult.stdout });
						await writeLedger(ledgerPath, ledger);
						updateUi(ctx);
						ctx.ui.notify(`Falha ao criar worktree da tarefa ${task.id}: ${(wtResult.stderr || wtResult.stdout).trim()}`, "error");
						return;
					}
					addEvent(ledger, "task-worktree", `Worktree criada para ${task.id}: ${worktreeRel}`);
				} else {
					addEvent(ledger, "task-worktree", `Worktree reutilizada para ${task.id}: ${worktreeRel}`);
				}

				if (pushTasks) {
					const pushResult = await runGit(pi, repoRoot, ["push", "-u", "origin", branch]);
					if (pushResult.code === 0) {
						addEvent(ledger, "task-push", `Branch da tarefa enviada para origin: ${branch}`);
					} else {
						addEvent(ledger, "task-push-warning", `Push da tarefa ${task.id} não concluído`, { stderr: pushResult.stderr, stdout: pushResult.stdout });
						ctx.ui.notify(`Push da tarefa ${task.id} falhou; branch/worktree local mantida.`, "warning");
					}
				}

				task.status = "pending";
				await writeLedger(ledgerPath, ledger);
				updateUi(ctx);
			}

			ledger.phases.approval = "done";
			ledger.phases.taskWorktrees = "done";
			ledger.phases.run = "approval";
			ledger.sprint.status = "approval";
			addEvent(ledger, "task-worktrees", "Branches/worktrees de tarefa criadas; aguardando /dev-run");
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);
			ctx.ui.notify(`Plano aprovado. ${ledger.tasks.length} worktree(s) de tarefa prontas. Próximo passo: /dev-run`, "success");
		},
	});

	pi.registerCommand("dev-run", {
		description: "Executa o próximo grupo paralelo pendente. Uso: /dev-run [sprint] [--group N]",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;
			const tokens = (args || "").match(/(?:[^\s"]+|"[^"]*")+/g)?.map(t => t.replace(/^"|"$/g, "")) || [];
			let requestedGroup: number | undefined;
			const positional: string[] = [];
			for (let i = 0; i < tokens.length; i++) {
				const token = tokens[i];
				if (token === "--group" || token === "-g") requestedGroup = Number(tokens[++i]);
				else if (token.startsWith("--group=")) requestedGroup = Number(token.slice("--group=".length));
				else positional.push(token);
			}

			if (!(await ensureActiveLedger(ctx, positional[0]))) return;
			const ledger = state.ledger!;
			const repoRoot = state.repoRoot!;
			const ledgerPath = state.ledgerPath!;
			const group = getRunnableGroup(ledger, requestedGroup);
			if (!group) {
				ctx.ui.notify("Nenhum grupo pendente com dependências atendidas encontrado.", "warning");
				return;
			}

			const summary = group.tasks.map(t => `- ${t.id}: ${t.title}\n  agent: ${t.agent || "n/a"}\n  worktree: ${t.worktree}`).join("\n");
			const ok = await ctx.ui.confirm(
				`Executar grupo G${group.id}?`,
				`As tarefas abaixo serão executadas em paralelo, cada uma em sua própria worktree.\n\n${summary}\n\nContinuar?`,
			);
			if (!ok) return;

			ledger.phases.run = "running";
			ledger.sprint.status = "running";
			addEvent(ledger, "run", `Executando grupo paralelo G${group.id}`, { tasks: group.tasks.map(t => t.id) });
			for (const task of group.tasks) task.status = "running";
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);

			await Promise.all(group.tasks.map(async task => {
				const result = await runTaskAgent(pi, ctx, ledger, repoRoot, task);
				task.summary = result.output.slice(0, 12000);
				task.changedFiles = await getChangedFiles(pi, path.join(repoRoot, task.worktree || ""), ledger.sprint.branch);
				if (result.exitCode === 0) {
					task.status = "done";
					addEvent(ledger, "task-done", `Tarefa concluída: ${task.id}`, { elapsed: result.elapsed, changedFiles: task.changedFiles });
				} else {
					task.status = "error";
					task.error = result.output.slice(0, 4000);
					addEvent(ledger, "task-error", `Tarefa falhou: ${task.id}`, { elapsed: result.elapsed, error: task.error });
				}
				await writeLedger(ledgerPath, ledger);
				updateUi(ctx);
			}));

			const hasErrors = group.tasks.some(t => t.status === "error");
			if (hasErrors) {
				ledger.phases.run = "blocked";
				ledger.sprint.status = "blocked";
				addEvent(ledger, "run-blocked", `Grupo G${group.id} terminou com erro(s)`);
			} else {
				const next = getRunnableGroup(ledger);
				if (next) {
					ledger.phases.run = "approval";
					ledger.sprint.status = "approval";
					addEvent(ledger, "run", `Grupo G${group.id} concluído; próximo grupo disponível: G${next.id}`);
				} else {
					ledger.phases.run = "done";
					ledger.phases.review = "approval";
					ledger.sprint.status = "approval";
					addEvent(ledger, "run-done", "Todas as tarefas planejadas foram executadas; aguardando revisão");
				}
			}
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);
			ctx.ui.notify(hasErrors ? `Grupo G${group.id} finalizado com erro(s). Veja /dev-status.` : `Grupo G${group.id} concluído.`, hasErrors ? "error" : "success");
		},
	});

	pi.registerCommand("dev-review", {
		description: "Revisa tarefas concluídas antes da integração. Uso: /dev-review [sprint] [--agent reviewer] [--task ID]",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;
			const tokens = (args || "").match(/(?:[^\s"]+|"[^"]*")+/g)?.map(t => t.replace(/^"|"$/g, "")) || [];
			let reviewerName = "reviewer";
			let taskId: string | undefined;
			const positional: string[] = [];
			for (let i = 0; i < tokens.length; i++) {
				const token = tokens[i];
				if (token === "--agent" || token === "-a") reviewerName = tokens[++i] || reviewerName;
				else if (token.startsWith("--agent=")) reviewerName = token.slice("--agent=".length);
				else if (token === "--task" || token === "-t") taskId = tokens[++i];
				else if (token.startsWith("--task=")) taskId = token.slice("--task=".length);
				else positional.push(token);
			}

			if (!(await ensureActiveLedger(ctx, positional[0]))) return;
			const ledger = state.ledger!;
			const repoRoot = state.repoRoot!;
			const ledgerPath = state.ledgerPath!;
			const candidates = ledger.tasks.filter(t => t.status === "done" && (!taskId || t.id === taskId) && t.reviewStatus !== "approved");
			if (candidates.length === 0) {
				ctx.ui.notify("Nenhuma tarefa concluída pendente de review encontrada.", "warning");
				return;
			}

			const summary = candidates.map(t => `- ${t.id}: ${t.title}\n  branch: ${t.branch}\n  worktree: ${t.worktree}`).join("\n");
			const ok = await ctx.ui.confirm(
				"Executar review?",
				`Revisor: ${reviewerName}\nTarefas: ${candidates.length}\n\n${summary}\n\nExecutar reviews em paralelo no modo read-only?`,
			);
			if (!ok) return;

			ledger.phases.review = "running";
			ledger.sprint.status = "running";
			for (const task of candidates) task.reviewStatus = "pending";
			addEvent(ledger, "review", `Executando review de ${candidates.length} tarefa(s)`, { reviewer: reviewerName, tasks: candidates.map(t => t.id) });
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);

			await Promise.all(candidates.map(async task => {
				const result = await runReviewAgent(pi, ctx, ledger, repoRoot, task, reviewerName);
				task.reviewSummary = result.output.slice(0, 12000);
				if (result.exitCode !== 0) {
					task.reviewStatus = "error";
					addEvent(ledger, "review-error", `Review falhou: ${task.id}`, { elapsed: result.elapsed, error: task.reviewSummary.slice(0, 2000) });
				} else if (/CHANGES_REQUESTED|REPROVADO|REPROVADA|ALTERAÇÕES SOLICITADAS/i.test(result.output)) {
					task.reviewStatus = "changes-requested";
					task.status = "blocked";
					addEvent(ledger, "review-changes", `Review solicitou alterações: ${task.id}`, { elapsed: result.elapsed });
				} else {
					task.reviewStatus = "approved";
					addEvent(ledger, "review-approved", `Review aprovado: ${task.id}`, { elapsed: result.elapsed });
				}
				await writeLedger(ledgerPath, ledger);
				updateUi(ctx);
			}));

			const hasIssues = candidates.some(t => t.reviewStatus === "changes-requested" || t.reviewStatus === "error");
			const allDoneTasks = ledger.tasks.filter(t => t.status === "done");
			const allReviewed = allDoneTasks.length > 0 && allDoneTasks.every(t => t.reviewStatus === "approved");
			if (hasIssues) {
				ledger.phases.review = "blocked";
				ledger.sprint.status = "blocked";
				addEvent(ledger, "review-blocked", "Review encontrou problemas; corrija tarefas bloqueadas antes de integrar");
			} else if (allReviewed) {
				ledger.phases.review = "done";
				ledger.phases.integrate = "approval";
				ledger.sprint.status = "approval";
				addEvent(ledger, "review-done", "Todas as tarefas concluídas foram aprovadas; aguardando /dev-integrate");
			} else {
				ledger.phases.review = "approval";
				ledger.sprint.status = "approval";
				addEvent(ledger, "review-partial", "Review parcial concluído; ainda há tarefas sem aprovação");
			}
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);
			ctx.ui.notify(hasIssues ? "Review finalizado com problemas. Veja /dev-status." : "Review concluído.", hasIssues ? "warning" : "success");
		},
	});

	pi.registerCommand("dev-integrate", {
		description: "Integra branches de tarefas aprovadas na branch da sprint. Uso: /dev-integrate [sprint] [--push|--no-push] [--task ID]",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;
			const tokens = (args || "").match(/(?:[^\s"]+|"[^"]*")+/g)?.map(t => t.replace(/^"|"$/g, "")) || [];
			let pushOverride: boolean | undefined;
			let taskId: string | undefined;
			const positional: string[] = [];
			for (let i = 0; i < tokens.length; i++) {
				const token = tokens[i];
				if (token === "--push") pushOverride = true;
				else if (token === "--no-push") pushOverride = false;
				else if (token === "--task" || token === "-t") taskId = tokens[++i];
				else if (token.startsWith("--task=")) taskId = token.slice("--task=".length);
				else positional.push(token);
			}

			if (!(await ensureActiveLedger(ctx, positional[0]))) return;
			const ledger = state.ledger!;
			const repoRoot = state.repoRoot!;
			const ledgerPath = state.ledgerPath!;
			const sprintWorktreeAbs = path.join(repoRoot, ledger.sprint.worktree);
			const pushSprint = pushOverride ?? ledger.sprint.push;
			const candidates = ledger.tasks
				.filter(t => t.status === "done" && t.reviewStatus === "approved" && (!taskId || t.id === taskId))
				.sort((a, b) => (a.parallelGroup || 1) - (b.parallelGroup || 1));

			if (candidates.length === 0) {
				ctx.ui.notify("Nenhuma tarefa aprovada para integrar. Execute /dev-review antes ou informe uma tarefa válida.", "warning");
				return;
			}
			if (!(await worktreePathExists(sprintWorktreeAbs))) {
				ctx.ui.notify(`Worktree da sprint não encontrada: ${ledger.sprint.worktree}`, "error");
				return;
			}
			const sprintStatus = await gitOutput(pi, sprintWorktreeAbs, ["status", "--porcelain"]);
			if (sprintStatus.trim()) {
				ctx.ui.notify("A worktree da sprint possui alterações pendentes. Resolva antes de integrar.", "error");
				return;
			}

			const summary = candidates.map(t => `- ${t.id}: ${t.title}\n  branch: ${t.branch}\n  review: ${t.reviewStatus}`).join("\n");
			const ok = await ctx.ui.confirm(
				"Integrar tarefas aprovadas?",
				`Sprint: ${ledger.sprint.name}\nWorktree: ${ledger.sprint.worktree}\nPush sprint: ${pushSprint ? "sim" : "não"}\n\n${summary}\n\nFazer merge destas branches na branch da sprint?`,
			);
			if (!ok) return;

			ledger.phases.integrate = "running";
			ledger.sprint.status = "running";
			addEvent(ledger, "integrate", `Iniciando integração de ${candidates.length} tarefa(s)`, { tasks: candidates.map(t => t.id) });
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);

			const checkout = await runGit(pi, sprintWorktreeAbs, ["checkout", ledger.sprint.branch]);
			if (checkout.code !== 0) {
				ledger.phases.integrate = "blocked";
				ledger.sprint.status = "blocked";
				addEvent(ledger, "integrate-error", "Falha ao garantir branch da sprint", { stderr: checkout.stderr, stdout: checkout.stdout });
				await writeLedger(ledgerPath, ledger);
				updateUi(ctx);
				ctx.ui.notify(`Falha ao fazer checkout da sprint: ${(checkout.stderr || checkout.stdout).trim()}`, "error");
				return;
			}

			const integratedBranches: string[] = [];
			for (const task of candidates) {
				const branch = task.branch!;
				const merge = await runGit(pi, sprintWorktreeAbs, ["merge", "--no-ff", branch, "-m", `Merge ${branch} into ${ledger.sprint.branch}`]);
				if (merge.code === 0) {
					integratedBranches.push(branch);
					addEvent(ledger, "merge", `Branch integrada: ${branch}`, { task: task.id, output: (merge.stdout || merge.stderr).slice(0, 2000) });
					await writeLedger(ledgerPath, ledger);
					updateUi(ctx);
					continue;
				}

				addEvent(ledger, "merge-conflict", `Conflito ao integrar ${branch}; acionando integration-manager`, { task: task.id, output: (merge.stdout || merge.stderr).slice(0, 4000) });
				await writeLedger(ledgerPath, ledger);
				updateUi(ctx);
				const resolver = await runIntegrationAgent(pi, ctx, ledger, repoRoot, [branch], `${merge.stdout}\n${merge.stderr}`);
				const unmerged = await runGit(pi, sprintWorktreeAbs, ["diff", "--name-only", "--diff-filter=U"]);
				if (resolver.exitCode !== 0 || unmerged.stdout.trim()) {
					ledger.phases.integrate = "blocked";
					ledger.sprint.status = "blocked";
					addEvent(ledger, "merge-blocked", `Conflito não resolvido para ${branch}`, { resolver: resolver.output.slice(0, 4000), unmerged: unmerged.stdout });
					await writeLedger(ledgerPath, ledger);
					updateUi(ctx);
					ctx.ui.notify(`Integração bloqueada: conflito não resolvido em ${branch}.`, "error");
					return;
				}

				await runGit(pi, sprintWorktreeAbs, ["add", "-A"]);
				const commit = await runGit(pi, sprintWorktreeAbs, ["commit", "--no-edit"]);
				if (commit.code !== 0 && !/nothing to commit/i.test(commit.stdout + commit.stderr)) {
					ledger.phases.integrate = "blocked";
					ledger.sprint.status = "blocked";
					addEvent(ledger, "merge-commit-error", `Falha ao concluir merge de ${branch}`, { stderr: commit.stderr, stdout: commit.stdout, resolver: resolver.output.slice(0, 4000) });
					await writeLedger(ledgerPath, ledger);
					updateUi(ctx);
					ctx.ui.notify(`Conflito resolvido, mas commit de merge falhou para ${branch}.`, "error");
					return;
				}
				integratedBranches.push(branch);
				addEvent(ledger, "merge-resolved", `Branch integrada com conflito resolvido: ${branch}`, { resolver: resolver.output.slice(0, 4000) });
				await writeLedger(ledgerPath, ledger);
				updateUi(ctx);
			}

			if (pushSprint) {
				const push = await runGit(pi, sprintWorktreeAbs, ["push", "origin", ledger.sprint.branch]);
				if (push.code === 0) {
					addEvent(ledger, "integrate-push", `Branch da sprint enviada para origin: ${ledger.sprint.branch}`);
				} else {
					addEvent(ledger, "integrate-push-warning", "Push da sprint falhou", { stderr: push.stderr, stdout: push.stdout });
					ctx.ui.notify(`Integração concluída localmente, mas push falhou: ${(push.stderr || push.stdout).trim()}`, "warning");
				}
			}

			ledger.phases.integrate = "done";
			ledger.phases.validate = "approval";
			ledger.sprint.status = "approval";
			addEvent(ledger, "integrate-done", `Integração concluída: ${integratedBranches.length} branch(es)`, { branches: integratedBranches });
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);
			ctx.ui.notify(`Integração concluída. Próximo passo: /dev-validate`, "success");
		},
	});

	pi.registerCommand("dev-validate", {
		description: "Roda validações integradas na worktree da sprint. Uso: /dev-validate [sprint] [--cmd \"comando\"] [--list]",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;
			const tokens = (args || "").match(/(?:[^\s"]+|"[^"]*")+/g)?.map(t => t.replace(/^"|"$/g, "")) || [];
			const positional: string[] = [];
			const explicitCommands: string[] = [];
			let listOnly = false;
			for (let i = 0; i < tokens.length; i++) {
				const token = tokens[i];
				if (token === "--cmd" || token === "-c") explicitCommands.push(tokens[++i] || "");
				else if (token.startsWith("--cmd=")) explicitCommands.push(token.slice("--cmd=".length));
				else if (token === "--list") listOnly = true;
				else positional.push(token);
			}

			if (!(await ensureActiveLedger(ctx, positional[0]))) return;
			const ledger = state.ledger!;
			const repoRoot = state.repoRoot!;
			const ledgerPath = state.ledgerPath!;
			const sprintWorktreeAbs = path.join(repoRoot, ledger.sprint.worktree);
			if (!(await worktreePathExists(sprintWorktreeAbs))) {
				ctx.ui.notify(`Worktree da sprint não encontrada: ${ledger.sprint.worktree}`, "error");
				return;
			}

			const commands = explicitCommands.filter(Boolean).length > 0
				? explicitCommands.filter(Boolean)
				: await detectValidationCommands(sprintWorktreeAbs, ledger.tasks);
			if (commands.length === 0) {
				ctx.ui.notify("Nenhum comando de validação detectado. Use /dev-validate --cmd \"seu comando\".", "warning");
				return;
			}
			if (listOnly) {
				ctx.ui.notify(`Comandos de validação detectados:\n${commands.map(c => `- ${c}`).join("\n")}`, "info");
				return;
			}

			const ok = await ctx.ui.confirm(
				"Rodar validação integrada?",
				`Sprint: ${ledger.sprint.name}\nWorktree: ${ledger.sprint.worktree}\n\nComandos:\n${commands.map(c => `- ${c}`).join("\n")}\n\nExecutar agora?`,
			);
			if (!ok) return;

			ledger.phases.validate = "running";
			ledger.sprint.status = "running";
			ledger.validations = [];
			addEvent(ledger, "validate", `Executando ${commands.length} validação(ões) integrada(s)`);
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);

			for (const command of commands) {
				ctx.ui.notify(`Validando: ${command}`, "info");
				const validation = await runShell(pi, sprintWorktreeAbs, command);
				ledger.validations.push(validation);
				addEvent(ledger, validation.status === "passed" ? "validation-passed" : "validation-failed", `${command}: ${validation.status}`, { exitCode: validation.exitCode, output: validation.output.slice(0, 2000) });
				await writeLedger(ledgerPath, ledger);
				updateUi(ctx);
				if (validation.status === "failed") break;
			}

			const failed = ledger.validations.some(v => v.status === "failed");
			if (failed) {
				ledger.phases.validate = "blocked";
				ledger.sprint.status = "blocked";
				addEvent(ledger, "validate-blocked", "Validação integrada falhou; corrija antes de finalizar");
			} else {
				ledger.phases.validate = "done";
				ledger.phases.finish = "approval";
				ledger.sprint.status = "approval";
				addEvent(ledger, "validate-done", "Validações integradas concluídas com sucesso; aguardando /dev-finish");
			}
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);
			if (failed) {
				const failedValidation = findFailedValidation(ledger)!;
				ctx.ui.notify(
					`Validação falhou: ${failedValidation.command}\nExit code: ${failedValidation.exitCode}\nWorktree: ${ledger.sprint.worktree}\n\nSaída:\n${compactOutput(failedValidation.output, 2600)}\n\nPróximo passo:\n${buildNextStep(ledger)}\n\nUse /dev-status ${ledger.sprint.slug} para ver o diagnóstico completo.`,
					"error",
				);
			} else {
				ctx.ui.notify("Validação concluída com sucesso.", "success");
			}
		},
	});

	pi.registerCommand("dev-finish", {
		description: "Gera relatório final da sprint após validação. Uso: /dev-finish [sprint]",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;
			const sprint = (args || "").trim() || undefined;
			if (!(await ensureActiveLedger(ctx, sprint))) return;
			const ledger = state.ledger!;
			const repoRoot = state.repoRoot!;
			const ledgerPath = state.ledgerPath!;
			const sprintWorktreeAbs = path.join(repoRoot, ledger.sprint.worktree);
			const reportPath = path.join(repoRoot, ".pi", "workflows", "reports", `${ledger.sprint.slug}.md`);

			const validationsPassed = (ledger.validations?.length || 0) > 0 && ledger.validations!.every(v => v.status === "passed");
			if (!validationsPassed) {
				const ok = await ctx.ui.confirm("Finalizar sem validação aprovada?", "Não há validações aprovadas registradas ou alguma validação falhou. Gerar relatório mesmo assim?");
				if (!ok) return;
			}

			let changedFiles: string[] = [];
			if (await worktreePathExists(sprintWorktreeAbs)) {
				changedFiles = await getChangedFiles(pi, sprintWorktreeAbs, ledger.sprint.baseBranch);
			}

			const taskSection = ledger.tasks.map(task => [
				`### ${task.id} — ${task.title}`,
				`- Agente: ${task.agent || "n/a"}`,
				`- Branch: ${task.branch || "n/a"}`,
				`- Worktree: ${task.worktree || "n/a"}`,
				`- Status: ${task.status}`,
				`- Review: ${task.reviewStatus || "n/a"}`,
				`- Arquivos alterados: ${(task.changedFiles || []).join(", ") || "n/a"}`,
				`- Riscos: ${(task.risks || []).join(", ") || "n/a"}`,
				"",
				(task.summary ? `Resumo:\n\n${task.summary.slice(0, 2000)}` : ""),
			].filter(Boolean).join("\n")).join("\n\n");

			const validationSection = (ledger.validations || []).map(v =>
				`- ${v.status === "passed" ? "✓" : "✗"} \`${v.command}\` — exit ${v.exitCode} — ${Math.round(v.elapsed / 1000)}s`
			).join("\n") || "- Nenhuma validação registrada.";

			const report = `# Relatório Final da Sprint: ${ledger.sprint.name}\n\n` +
				`- Status: ${ledger.sprint.status}\n` +
				`- Branch base: ${ledger.sprint.baseBranch}\n` +
				`- Branch da sprint: ${ledger.sprint.branch}\n` +
				`- Worktree da sprint: ${ledger.sprint.worktree}\n` +
				`- Ledger: ${path.relative(repoRoot, ledgerPath)}\n` +
				`- Gerado em: ${now()}\n\n` +
				`## Resumo\n\n${ledger.sprint.description}\n\n` +
				`## Tarefas\n\n${taskSection || "Nenhuma tarefa registrada."}\n\n` +
				`## Validações\n\n${validationSection}\n\n` +
				`## Arquivos alterados na sprint\n\n${changedFiles.map(f => `- ${f}`).join("\n") || "- Nenhum arquivo detectado."}\n\n` +
				`## Branches de tarefa\n\n${ledger.tasks.map(t => `- ${t.branch}`).join("\n") || "- Nenhuma."}\n\n` +
				`## Próximos passos\n\n` +
				`1. Revisar manualmente a branch \`${ledger.sprint.branch}\`.\n` +
				`2. Abrir PR/MR da sprint para \`${ledger.sprint.baseBranch}\`.\n` +
				`3. Após merge confirmado, executar \`/dev-cleanup ${ledger.sprint.slug}\`.\n`;

			await ensureDir(path.dirname(reportPath));
			await fs.promises.writeFile(reportPath, report, "utf-8");
			ledger.phases.finish = "done";
			ledger.sprint.status = "done";
			addEvent(ledger, "finish", `Relatório final gerado: ${path.relative(repoRoot, reportPath)}`);
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);
			ctx.ui.notify(`Sprint finalizada. Relatório: ${path.relative(repoRoot, reportPath)}\nPróximo passo após merge: /dev-cleanup ${ledger.sprint.slug}`, "success");
		},
	});

	pi.registerCommand("dev-cleanup", {
		description: "Remove worktrees da sprint após confirmação. Uso: /dev-cleanup [sprint] [--include-sprint] [--delete-branches]",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;
			const tokens = (args || "").match(/(?:[^\s"]+|"[^"]*")+/g)?.map(t => t.replace(/^"|"$/g, "")) || [];
			let includeSprint = false;
			let deleteBranches = false;
			const positional: string[] = [];
			for (const token of tokens) {
				if (token === "--include-sprint") includeSprint = true;
				else if (token === "--delete-branches") deleteBranches = true;
				else positional.push(token);
			}
			if (!(await ensureActiveLedger(ctx, positional[0]))) return;
			const ledger = state.ledger!;
			const repoRoot = state.repoRoot!;
			const ledgerPath = state.ledgerPath!;
			const worktrees = ledger.tasks.map(t => t.worktree).filter(Boolean) as string[];
			if (includeSprint) worktrees.push(ledger.sprint.worktree);

			const ok = await ctx.ui.confirm(
				"Remover worktrees?",
				`Serão removidas as worktrees abaixo:\n${worktrees.map(w => `- ${w}`).join("\n")}\n\nBranches serão ${deleteBranches ? "deletadas localmente" : "preservadas"}. Confirma?`,
			);
			if (!ok) return;

			for (const wt of worktrees) {
				const abs = path.join(repoRoot, wt);
				if (!(await worktreePathExists(abs))) {
					addEvent(ledger, "cleanup-skip", `Worktree não encontrada: ${wt}`);
					continue;
				}
				const result = await runGit(pi, repoRoot, ["worktree", "remove", wt]);
				if (result.code !== 0) {
					const forceOk = await ctx.ui.confirm("Falha ao remover worktree", `git worktree remove ${wt} falhou:\n${(result.stderr || result.stdout).trim()}\n\nTentar com --force?`);
					if (forceOk) {
						const forced = await runGit(pi, repoRoot, ["worktree", "remove", "--force", wt]);
						addEvent(ledger, forced.code === 0 ? "cleanup" : "cleanup-error", `${forced.code === 0 ? "Removida" : "Falha ao remover"}: ${wt}`, { stderr: forced.stderr, stdout: forced.stdout });
					} else {
						addEvent(ledger, "cleanup-error", `Falha ao remover worktree: ${wt}`, { stderr: result.stderr, stdout: result.stdout });
					}
				} else {
					addEvent(ledger, "cleanup", `Worktree removida: ${wt}`);
				}
				await writeLedger(ledgerPath, ledger);
				updateUi(ctx);
			}

			if (deleteBranches) {
				for (const task of ledger.tasks) {
					if (!task.branch) continue;
					const del = await runGit(pi, repoRoot, ["branch", "-d", task.branch]);
					addEvent(ledger, del.code === 0 ? "branch-delete" : "branch-delete-warning", `Branch ${task.branch}: ${del.code === 0 ? "deletada" : "não deletada"}`, { stderr: del.stderr, stdout: del.stdout });
				}
			}

			addEvent(ledger, "cleanup-done", "Cleanup concluído");
			await writeLedger(ledgerPath, ledger);
			updateUi(ctx);
			ctx.ui.notify("Cleanup concluído. Branch da sprint preservada por padrão.", "success");
		},
	});

	pi.registerCommand("dev-resume", {
		description: "Carrega uma sprint dev existente e restaura a UI. Uso: /dev-resume <sprint>",
		getArgumentCompletions: (_prefix: string) => null,
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			widgetCtx = ctx;
			let repoRoot: string;
			try {
				repoRoot = await detectRepoRoot(pi, ctx.cwd);
			} catch (error) {
				ctx.ui.notify(`dev-resume: diretório atual não é um repositório Git (${error instanceof Error ? error.message : String(error)})`, "error");
				return;
			}
			const slug = (args || "").trim() ? slugify((args || "").trim()) : undefined;
			let ledgerPath = slug
				? path.join(repoRoot, ".pi", "workflows", "sessions", `${slug}.json`)
				: await findLatestLedger(repoRoot);
			if (!ledgerPath || !(await fileExists(ledgerPath))) {
				ctx.ui.notify(slug ? `Ledger não encontrado para sprint: ${slug}` : "Nenhum ledger dev encontrado.", "warning");
				return;
			}
			state.repoRoot = repoRoot;
			state.ledgerPath = ledgerPath;
			state.ledger = await readLedger(ledgerPath);
			addEvent(state.ledger, "resume", "Sprint carregada via /dev-resume");
			await writeLedger(ledgerPath, state.ledger);
			pi.setSessionName(`dev:${state.ledger.sprint.slug}`);
			updateUi(ctx);

			const ledger = state.ledger;
			const next = (() => {
				if (ledger.phases.approval === "approval") return "/dev-approve-plan";
				if (ledger.phases.run === "approval" || getRunnableGroup(ledger)) return "/dev-run";
				if (ledger.phases.review === "approval") return "/dev-review";
				if (ledger.phases.integrate === "approval") return "/dev-integrate";
				if (ledger.phases.validate === "approval") return "/dev-validate";
				if (ledger.phases.finish === "approval") return "/dev-finish";
				if (ledger.sprint.status === "done") return `/dev-cleanup ${ledger.sprint.slug}`;
				return "/dev-status";
			})();
			ctx.ui.notify(
				`Sprint carregada: ${ledger.sprint.name}\nBranch: ${ledger.sprint.branch}\nWorktree: ${ledger.sprint.worktree}\nLedger: ${path.relative(repoRoot, ledgerPath)}\nPróximo passo sugerido: ${next}`,
				"success",
			);
		},
	});

	pi.registerCommand("dev-status", {
		description: "Mostra o status da sprint dev atual com diagnóstico e próximo passo. Uso: /dev-status [sprint]",
		handler: async (args, ctx) => {
			widgetCtx = ctx;
			const sprint = (args || "").trim() || undefined;
			if (!(await ensureActiveLedger(ctx, sprint))) return;
			updateUi(ctx);
			const ledger = state.ledger!;
			ctx.ui.notify(formatDetailedStatus(ledger, state.ledgerPath), "info");
		},
	});
}
