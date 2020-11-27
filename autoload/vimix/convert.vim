
let s:save_cpo = &cpo
set cpo&vim

let s:default_palette = [
 \ '#000000', '#800000', '#008000', '#808000', '#000080', '#800080', '#008080', '#c0c0c0',
 \ '#808080', '#ff0000', '#00ff00', '#ffff00', '#0000ff', '#ff00ff', '#00ffff', '#ffffff' ]

function! vimix#convert#hexToApproxAnsi(hex)
  let i = index(s:default_alette, a:hex)
  if i isnot -1
    return i
  endif
  for i in range(16, 256)
    if a:hex is vimix#convert#ansiToHex(i)
      return i
    endif
  endfor
  return 0
endfunction

function! vimix#convert#ansiToHex(ansi)
  if a:ansi < 16
    return s:default_palette[a:ansi]
  elseif a:ansi > 231
    let gray = 8 + 10 * (a:ansi - 232)
    return printf('#%02x%02x%02x', gray, gray, gray)
  endif
  let ri = (a:ansi - 16) / 36
  let r = ri > 0 ? 55 + ri * 40 : ri > 0
  let gi = ((a:ansi - 16) % 36) / 6
  let g = gi > 0 ? 55 + gi * 40 : gi > 0
  let bi = (a:ansi - 16) % 6
  let b = bi > 0 ? 55 + bi * 40 : bi > 0
  return printf('#%02x%02x%02x', r, g, b)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
