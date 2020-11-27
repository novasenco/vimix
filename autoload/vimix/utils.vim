
function! vimix#utils#error(erno, lnr, msg, token) abort
  echohl ErrorMsg
  unsilent echom 'VimixE'.a:erno '[line' a:lnr.']:' a:msg.':' string(a:token)
  echohl NONE
  return a:erno
endfunction

function! vimix#utils#warn(erno, lnr, msg, token) abort
  echohl WarningMsg
  unsilent echom 'VimixW'.a:erno '[line' a:lnr.']:' a:msg.':' string(a:token)
  echohl NONE
  return a:erno
endfunction

