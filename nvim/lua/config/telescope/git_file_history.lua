local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")

local M = {}

local function git_root()
	local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]

	if vim.v.shell_error ~= 0 or not root or root == "" then
		vim.notify("Não está dentro de um repositório git", vim.log.levels.WARN)
		return nil
	end

	return root
end

local function git_show(root, item)
	local spec = item.hash .. ":" .. item.path

	if item.status == "D" then
		spec = item.hash .. "^:" .. item.path
	end

	local lines = vim.fn.systemlist({ "git", "-C", root, "show", spec })

	if vim.v.shell_error ~= 0 and item.status ~= "D" then
		lines = vim.fn.systemlist({ "git", "-C", root, "show", item.hash .. "^:" .. item.path })
	end

	if vim.v.shell_error ~= 0 then
		return {
			"Não foi possível abrir o conteúdo do arquivo neste commit.",
			"",
			"Commit: " .. item.hash,
			"Arquivo: " .. item.path,
		}
	end

	return lines
end

local function open_from_commit(root, item)
	local lines = git_show(root, item)

	vim.cmd("tabnew")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.bo.filetype = vim.filetype.match({ filename = item.path }) or ""
	vim.api.nvim_buf_set_name(0, item.path .. " @ " .. item.short_hash)
end

local function open_diffview(root, item)
	local parents = vim.fn.systemlist({ "git", "-C", root, "rev-list", "--parents", "-n", "1", item.hash })[1] or ""
	local parent = vim.split(parents, " ", { trimempty = true })[2]
	local range = parent and (parent .. ".." .. item.hash) or item.hash

	local path = item.path
	if item.status == "D" and item.old_path and item.old_path ~= "" then
		path = item.old_path
	end

	vim.cmd("DiffviewOpen " .. range .. " -- " .. vim.fn.fnameescape(path))
end

function M.file_history(opts)
	opts = opts or {}

	local root = git_root()
	if not root then
		return
	end

	local default_text = opts.default_text
	if default_text == nil then
		default_text = vim.fn.expand("%:t")
	end

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return nil
			end

			local script = [[
query="$1"
[ -z "$query" ] && exit 0
cd "$2" || exit 0
git log --all --date=iso --name-status --pretty=format:'@@@%H%x09%ad%x09%an%x09%s' -- "*$query*" |
awk -v OFS='\t' '
  /^@@@/ {
    line = substr($0, 4)
    split(line, h, "\t")
    hash = h[1]
    date = h[2]
    author = h[3]
    subject = h[4]
    next
  }
  /^[A-Z][0-9]*[ \t]/ {
    status = $1
    old = ""
    path = $2

    if (status ~ /^[RC]/) {
      old = $2
      path = $3
    }

    if (hash != "" && path != "") {
      print hash, date, author, subject, status, path, old
    }
  }
' |
while IFS=$'\t' read -r hash date author subject status path old; do
  branches=$(git for-each-ref --format='%(refname:short)' --contains "$hash" refs/heads refs/remotes |
    sed 's#^remotes/##' |
    grep -v '/HEAD$' |
    grep -v '^origin$' |
    paste -sd ',' - |
    sed 's/,/, /g')

  if [ -z "$branches" ]; then
    branches="sem branch"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$hash" "$date" "$author" "$subject" "$status" "$path" "$old" "$branches"
done
]]

			return { "bash", "-c", script, "git-file-history", prompt, root }
		end,
		entry_maker = function(line)
			local parts = vim.split(line, "\t", { plain = true })
			local item = {
				hash = parts[1],
				date = parts[2],
				author = parts[3],
				subject = parts[4],
				status = parts[5],
				path = parts[6],
				old_path = parts[7],
				branches = parts[8],
			}

			if not item.hash or not item.path then
				return nil
			end

			item.short_hash = item.hash:sub(1, 8)

			local old_path = ""
			if item.old_path and item.old_path ~= "" then
				old_path = " <- " .. item.old_path
			end

			local display = string.format(
				"%s  %-4s  %-35s  %s  %s%s  %s",
				item.short_hash,
				item.status,
				item.branches or "sem branch",
				(item.date or ""):sub(1, 19),
				item.path,
				old_path,
				item.subject or ""
			)

			return {
				value = item,
				display = display,
				ordinal = table.concat(
					{ item.branches or "", item.path, item.old_path or "", item.subject or "", item.author or "", item.hash },
					" "
				),
			}
		end,
	})

	pickers
		.new(opts, {
			prompt_title = "Git File History",
			finder = finder,
			previewer = previewers.new_buffer_previewer({
				title = "Conteúdo no commit",
				define_preview = function(self, entry)
					local item = entry.value
					local lines = git_show(root, item)

					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.bo[self.state.bufnr].filetype = vim.filetype.match({ filename = item.path }) or ""
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				local function open_selected()
					local selected = action_state.get_selected_entry()
					if not selected then
						return
					end

					actions.close(prompt_bufnr)
					open_diffview(root, selected.value)
				end

				local function open_snapshot()
					local selected = action_state.get_selected_entry()
					if not selected then
						return
					end

					actions.close(prompt_bufnr)
					open_from_commit(root, selected.value)
				end

				map("i", "<CR>", open_selected)
				map("n", "<CR>", open_selected)
				map("i", "<C-o>", open_snapshot)
				map("n", "<C-o>", open_snapshot)

				return true
			end,
		})
		:find()
end

function M.setup()
	vim.api.nvim_create_user_command("GitFileHistory", function(command_opts)
		local default_text = command_opts.args ~= "" and command_opts.args or nil

		M.file_history({ default_text = default_text })
	end, {
		nargs = "?",
		complete = "file",
	})

	vim.keymap.set("n", "<leader>gF", M.file_history, { desc = "Git file history by name" })
end

return M
