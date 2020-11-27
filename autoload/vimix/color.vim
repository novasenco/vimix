
function! s:addmatch()
  let pat = substitute(getline('.'), '^\s*\(\s\+\).*', '\1', '')
  let lnr = line('.')
  let cnr = strlen(substitute(getline('.'), '^\(\s*\).*', '\1', '')) + 1
  let len = strlen(pat)
  echom pat lnr cnr len
  sil! call matchaddpos(pat, [[lnr, cnr, len]])
endfunction

function! vimix#color#update()
  keepj keepp g/^\s*\u\w\+\s\+-\@!/call <sid>addmatch()
  " for lnr in range(line(a:line1), line(a:line2))
  "   echom getline(lnr)
  " endfor
endfunction

