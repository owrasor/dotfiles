local M = {}

M._completion_root = nil

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function systemlist(args, cwd)
    local opts = cwd and { cwd = cwd } or nil
    local result = vim.fn.systemlist(args, nil, opts)

    if vim.v.shell_error ~= 0 then
        return nil
    end

    return result
end

local function git_root()
    local current_dir = vim.fn.expand("%:p:h")
    if current_dir == "" then
        current_dir = vim.fn.getcwd()
    end

    local result = systemlist({ "git", "-C", current_dir, "rev-parse", "--show-toplevel" })
    if not result or not result[1] or result[1] == "" then
        vim.notify("Não foi possível encontrar a raiz do repositório Git", vim.log.levels.ERROR)
        return nil
    end

    return result[1]
end

local function current_branch(root)
    local result = systemlist({ "git", "-C", root, "branch", "--show-current" })
    if not result or not result[1] or result[1] == "" then
        return "HEAD"
    end

    return result[1]
end

local function default_path(root)
    local current_file = vim.fn.expand("%:p")
    if current_file ~= "" and vim.startswith(current_file, root) then
        local relative = current_file:sub(#root + 2)
        if relative ~= "" then
            return relative
        end
    end

    return "."
end

local function unique_sorted(values)
    local seen = {}
    local result = {}

    for _, value in ipairs(values or {}) do
        value = trim(value)
        if value ~= "" and not seen[value] then
            seen[value] = true
            table.insert(result, value)
        end
    end

    table.sort(result)
    return result
end

local function starts_with(value, prefix)
    return prefix == "" or value:sub(1, #prefix) == prefix
end

local function branch_candidates(root, arglead)
    root = root or M._completion_root or git_root()
    if not root then
        return {}
    end

    local refs = systemlist({
        "git",
        "-C",
        root,
        "for-each-ref",
        "--format=%(refname:short)",
        "refs/heads",
        "refs/remotes",
    }) or {}

    table.insert(refs, "HEAD")

    local result = {}
    for _, ref in ipairs(unique_sorted(refs)) do
        if ref ~= "origin/HEAD" and not ref:match("/HEAD$") and starts_with(ref, arglead or "") then
            table.insert(result, ref)
        end
    end

    return result
end

local function path_candidates(root, arglead)
    root = root or M._completion_root or git_root()
    if not root then
        return {}
    end

    arglead = arglead or ""

    local files = systemlist({ "git", "-C", root, "ls-files" }) or {}
    local candidates = { "." }
    local dirs = {}

    for _, file in ipairs(files) do
        if file ~= "" then
            table.insert(candidates, file)

            local partial = ""
            for part in file:gmatch("[^/]+") do
                partial = partial == "" and part or (partial .. "/" .. part)
                if partial ~= file then
                    dirs[partial .. "/"] = true
                end
            end
        end
    end

    for dir, _ in pairs(dirs) do
        table.insert(candidates, dir)
    end

    local result = {}
    for _, candidate in ipairs(unique_sorted(candidates)) do
        if starts_with(candidate, arglead) then
            table.insert(result, candidate)
        end
    end

    return result
end

_G.DiffviewComparePathCompleteBranches = function(arglead)
    return branch_candidates(M._completion_root, arglead)
end

_G.DiffviewComparePathCompletePaths = function(arglead)
    return path_candidates(M._completion_root, arglead)
end

local function input(prompt, default, completion, callback)
    vim.ui.input({ prompt = prompt, default = default, completion = completion }, function(value)
        value = trim(value)
        if value == "" then
            return
        end

        callback(value)
    end)
end

local function open_diffview(destination, source, path)
    local root = git_root()
    if not root then
        return
    end

    destination = trim(destination)
    source = trim(source)
    path = trim(path)

    if destination == "" or source == "" or path == "" then
        vim.notify("Informe destino, origem e caminho", vim.log.levels.ERROR)
        return
    end

    vim.cmd("lcd " .. vim.fn.fnameescape(root))

    -- Destino fica à esquerda/base; origem fica à direita, como se origem fosse integrada no destino.
    local rev_range = destination .. ".." .. source
    local command = "DiffviewOpen " .. vim.fn.fnameescape(rev_range) .. " -- " .. vim.fn.fnameescape(path)

    vim.cmd(command)
end

function M.prompt()
    local root = git_root()
    if not root then
        return
    end

    M._completion_root = root

    local default_destination = "master"
    local default_source = current_branch(root)
    local path = default_path(root)

    input(
        "Branch de destino/base (lado esquerdo): ",
        default_destination,
        "customlist,v:lua.DiffviewComparePathCompleteBranches",
        function(destination)
            input(
                "Branch de origem/comparada (lado direito): ",
                default_source,
                "customlist,v:lua.DiffviewComparePathCompleteBranches",
                function(source)
                    input(
                        "Arquivo ou pasta para comparar: ",
                        path,
                        "customlist,v:lua.DiffviewComparePathCompletePaths",
                        function(target_path)
                            open_diffview(destination, source, target_path)
                        end
                    )
                end
            )
        end
    )
end

function M.open_from_args(args)
    local root = git_root()
    if not root then
        return
    end

    M._completion_root = root

    if not args or #args == 0 then
        M.prompt()
        return
    end

    local destination = args[1]
    local source = args[2]
    local path = table.concat(vim.list_slice(args, 3), " ")

    if not destination or not source or path == "" then
        vim.notify(
            "Uso: :DiffviewComparePath <destino/base> <origem/comparada> <arquivo-ou-pasta>",
            vim.log.levels.ERROR
        )
        return
    end

    open_diffview(destination, source, path)
end

local function command_complete(arglead, cmdline)
    local root = git_root()
    if not root then
        return {}
    end

    M._completion_root = root

    local args = vim.split(cmdline, "%s+", { trimempty = true })
    -- args[1] is the command name. Complete args[2] and args[3] as branches, then path.
    local arg_count = math.max(#args - 1, 0)
    local ends_with_space = cmdline:match("%s$") ~= nil

    if ends_with_space then
        arg_count = arg_count + 1
    end

    if arg_count <= 2 then
        return branch_candidates(root, arglead)
    end

    return path_candidates(root, arglead)
end

function M.setup()
    vim.api.nvim_create_user_command("DiffviewComparePath", function(opts)
        M.open_from_args(opts.fargs)
    end, {
        nargs = "*",
        complete = command_complete,
        desc = "Abre Diffview para branch origem → destino em um arquivo ou pasta",
    })
end

return M
