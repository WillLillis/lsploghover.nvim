# lsploghover.nvim

Hover windows on specified Neovim LSP logs

### The Problem 
While debugging an LSP, I find myself frequently switching between the buffer 
I'm testing the LSP on and the LSP log file. This constant switching between the
buffer and log file (oftentimes just in search of a single log statement) is
time consuming and annoying.

### The Solution

This plugin streamlines the above process. Any logs of interest can be marked by
prepending the relevant text with the log key (the default is `LSPLOGHOVER`) and
then wrapping the text with angle brackets. For example, 

`log("Some important info");`

could be marked by changing the line to

`log("LSPLOGHOVER<Some important info>");`

Upon opening a buffer to test, one can then simply:

- Start the plugin with `:lua require("lsploghover").start()`.
    - Calling `start()` will ensure that only logs with timestamps after that point
    in time will be displayed. Not calling start will allow all marked logs to
    be shown.
- Have any specially marked logs appear in a hover window over the current
buffer with `:lua require("lsploghover").show_logs()`.

### Demo

The gif below shows a basic use of the plugin while debugging
[asm-lsp](https://github.com/bergercookie/asm-lsp/tree/master).

![](https://github.com/WillLillis/lsploghover.nvim/blob/main/demo.gif)

### Installation

- Install lsploghover like any other Neovim plugin
    - For example, with [packer.nvim](https://github.com/wbthomason/packer.nvim)
    : `'use WillLillis/lsploghover.nvim'`. In `after/plugin/lsploghover.lua`, I 
    have
    ```lua
    local log = require("lsploghover")

    vim.keymap.set('n', '<leader>st', function() log.start() end)
    vim.keymap.set('n', '<leader>sh', function() log.show_logs() end)

    log.setup()
    ```

### TODO

- Further testing to work out bugs.
