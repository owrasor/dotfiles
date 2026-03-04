#!/bin/bash
tmux new-session -d -s test_rpc_srv 'nvim --clean --listen 127.0.0.1:8894 --headless'
sleep 1
# Start the remote-ui client in background
tmux new-session -d -s test_rpc_cli 'nvim --clean --server 127.0.0.1:8894 --remote-ui'
sleep 1
# Now tell the server to execute an RPC call on the client
# Find the client channel. The client channel type is 'ui' but wait, nvim_list_chans()
# Let's write a lua script for the server to run:
nvim --clean --server 127.0.0.1:8894 --remote-expr "luaeval('vim.rpcnotify(vim.tbl_filter(function(c) return c.client and c.client.type == \"ui\" end, vim.api.nvim_list_chans())[1].id, \"nvim_command\", \"!touch /tmp/rpc_success\")')"
sleep 1
tmux kill-session -t test_rpc_srv
tmux kill-session -t test_rpc_cli
ls /tmp/rpc_success
