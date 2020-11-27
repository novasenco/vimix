
if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

let b:undo_ftplugin = "setl cms< kp< | if has('vms') | setl isk< | endif | delc Vimix | delc TestVimix"

setlocal commentstring=!\ %s
setlocal keywordprg=:help
setlocal iskeyword=@,48-57,_,192-255,#,-

command! -complete=dir -nargs=? -bar -bang -buffer Vimix call vimix#export(<q-args>, <q-mods>, <bang>0)
command! -complete=dir -nargs=? -bar -bang -buffer TestVimix call vimix#test(<q-args>, <q-mods>, <bang>0)

