# lsploghover.nvim

Hover windows on specified Neovim LSP logs

### The Problem 
While debugging an LSP, I find myself frequently switching between the buffer 
I'm testing the LSP on and the LSP log file. This constant switching between the
buffer and log file (oftentimes just in search of a single log statement) is
time consuming and annoying.

### The Solution

This plugin streams the above process. Any logs of interest can be marked with a
special string (the default is `[[LSPLOGHOVER]]`), or the plugin can be
configured to match a substring already in a log statement of interest. Upon 
opening a buffer to test, one can simply:

- Start the plugin with `:lua require("lsploghover").start()`
- Have any specially marked logs appear in a hover window over the current
buffer, checking with `:lua require("lsploghover").show_logs()`

### TODO

- Look into taking advantage of more advanced log marking beyond a simple
substring check
- Figure out how to enable text wrapping in the hover window without using the
deprectated `nvim_win_set_option()`
- Add install instructions and an example gif to the README
