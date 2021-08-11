
let s:save_cpo = &cpo
set cpo&vim

let s:hiFmt = 'highlight %s cterm=%s ctermfg=%s ctermbg=%s gui=%s guifg=%s guibg=%s'
let s:atMap = {'B':'bold', 'U':'underline', 'R':'reverse', 'I':'italic', 'N':'NONE'}

function! vimix#hi()
  let lnr = 0
  for line in getline(1, '$')
    let lnr += 1
    if line =~ '^\%(\s*\w\+\%(\s*->\s*\w\+\)*\s*->\s*\w\+\s*\%(;\|$\)\)\+$'
      " Links: <from> [ -> <from> ... ] -> <to> [ ; <from> [ -> <from> ... ] -> <to> ... ]
      " let defs = map(split(line, '\s*;\s*'), { _,c -> split(c, '\s*->\s*') })
    elseif line =~ '^\s*\w\+\s\+[[:alnum:]_~].*'
      " Highlight Group: <group> [atts] [foreground] [background]
      let [name, rhs] = split(substitute(line, '["!].*', '', ''), ':')
      let name = substitute(name, '^\s\+\|\s\+$', '', 'g')
      let rhs = split(rhs)
      let lenrhs = len(rhs)
      let cterm = ''
      let gui = ''
      let alias = ''
      if lenrhs < 2
        " return vimix#utils#error(2, linenr, 'Definition Needs Cterm and Gui Colors', line)
        continue
      elseif lenrhs is 2
        let [cterm, gui] = rhs
      elseif lenrhs is 3
        let [cterm, gui, alias] = rhs
      else
        " return vimix#utils#error(5, linenr, 'Definition Has Too Many Values', line)
        continue
      endif
      if cterm is '~' && gui is '~'
        " return vimix#utils#error(6, linenr, 'Definition Cannot Have Two Auto Values', line)
        continue
      endif
      if gui is '~'
        let gui = vimix#convert#ansiToHex(cterm)
      elseif cterm is '~'
        let cterm = vimix#convert#hexToApproxAnsi(gui)
      endif
      let defs[name] = {'cterm':cterm, 'gui':gui}
      if alias isnot ''
        if name =~ '^\d\+$'
          if alias !~ '^\[\l\w\+\]$'
            return vimix#utils#error(4, linenr, 'Definition Has Invalid Alias ('.string(alias).')', line)
          endif
          let alias = strpart(alias, 1, strlen(alias) - 2)
          let defs[alias] = defs[name]
          let base16map[alias] = [str2nr(name), str2nr(name)]
        else
          if alias !~ '^\[\s*\%(\d\+\|none\|\~\)\s*,\s*\%(\d\+\|none\|\~\)\s*\]$'
            return vimix#utils#error(3, linenr, 'Definition Has Invalid Base16 Map ('.string(alias).')', line)
          endif
          let base16map[name] = split(substitute(alias, '^\[\s*\|\s*\]$', '', 'g'), '\s*,\s*')
        endif
      endif

    elseif line =~ '^\s*\%(\l\w*\|\d\+\)\s*:'
      " Definition: <name> : <cterm> <gui> [<alias>] <<base16>>
    endif
  endfor
endfunction

function! s:preamble(meta, defs, lines16, links)
  let palette = map(range(16), 'get(a:defs, v:val).gui')
  if index(palette, '0') >= 0
    call vimix#utils#warn(3, 1, 'Unfinished Palette (changing all 0''s to #000000', string(palette))
  endif
  let palette = map(palette, 'v:val is 0 ? "#000000" : v:val')
  let fg = get(a:defs, 'fg', 'NONE')
  let bg = get(a:defs, 'bg', 'NONE')
  let cfg = fg.cterm == get(a:defs, 7).cterm ? 7 : 'NONE'
  let cbg = bg.cterm == get(a:defs, 8).cterm ? 8 : 'NONE'
  let hlnorm16 = printf(s:hiFmt, 'Normal', 'NONE', cfg, cbg, 'NONE', fg.gui, bg.gui)
  let hlnorm = printf(s:hiFmt, 'Normal', 'NONE', fg.cterm, bg.cterm, 'NONE', fg.gui, bg.gui)
  let pre = [
   \ '',
   \ 'highlight clear',
   \ "if exists('syntax_on')",
   \ 'syntax reset',
   \ 'endif',
   \ "let colors_name = '".(a:meta.name)."'",
   \]
  let bgtype = a:meta.type is '' ? get(g:, 'vimix_assume_bg', 'dark') : a:meta.type
  if bgtype =~? '^\%(dark\|light\)$'
    let pre += ["if &background isnot '".bgtype."'", 'set background=dark', 'endif']
  endif
  let pre += [
   \ '',
   \ "if has('gui_running') || has('termguicolors') && &termguicolors",
   \ 'let g:terminal_ansi_colors = '.string(palette),
   \ 'endif',
   \ '',
   \] + a:links + [
   \ '',
   \ '" automatically downgrade if &t_Co is smaller than 256',
   \ "if (exists('&t_Co') && !empty(&t_Co) && &t_Co > 1 ? &t_Co : 2) < 256",
   \ hlnorm16,
   \] + a:lines16 + [
   \ 'finish',
   \ 'endif',
   \ '',
   \ hlnorm,
   \]
  return pre
endfunction

function! vimix#parse() abort
  let meta = {'name':'vimix', 'description':'', 'author':''}
  let defs = {'none':{'cterm':'NONE', 'gui':'NONE'}}
  let defs['~'] = defs['none']
  let groups = {}
  let lines = []
  let lines16 = []
  let base16map = {'none':['NONE', 'NONE']}
  let base16map['~'] = base16map['none']
  let links = []
  let linenr = 0
  for line in getline(1, '$')
    let linenr += 1

    if line =~ '^:'
      " Ex Command: : <ex-command>
      call add(lines, strpart(line, 1))

    elseif line =~ '^>'
      " Ex Command For Links: > <ex-command>
      call add(links, strpart(line, 1))

    elseif line =~ '^\s*$'
      " Empty Line:
      if lines[-1] !~ '^\s*$'
        call add(lines, line)
      endif

    elseif line =~ '^\s*"'
      " Comment: <quot> <text>
      call add(lines, line)
      if line =~ '^\s*"\s*\%(\u\w\+\s*\):'
        let ind = stridx(line, ':')
        let name = substitute(strpart(line, 0, ind), '^\s*"\s*\|\s\+$', '', 'g')
        let rhs = substitute(strpart(line, ind + 1), '^\s', '', '')
        let meta[tolower(name)] = rhs
      endif

    elseif line =~ '^\s*<'
      " Comment For Links: <lcmt> ::= [spc] <gt> <text>
      call add(links, substitute(line, '^\s*<', '"', ''))

    elseif line =~ '^\s*\%(\l\w*\|\d\+\)\s*:'
      " Definition: <name> : <cterm> <gui> [<alias>] <<base16>>
      let [name, rhs] = split(substitute(line, '["!].*', '', ''), ':')
      let name = substitute(name, '^\s\+\|\s\+$', '', 'g')
      let rhs = split(rhs)
      let lenrhs = len(rhs)
      let cterm = ''
      let gui = ''
      let alias = ''
      if lenrhs < 2 
        return vimix#utils#error(2, linenr, 'Definition Needs Cterm and Gui Colors', line)
      elseif lenrhs is 2
        let [cterm, gui] = rhs
      elseif lenrhs is 3
        let [cterm, gui, alias] = rhs
      else
        return vimix#utils#error(5, linenr, 'Definition Has Too Many Values', line)
      endif
      if cterm is '~' && gui is '~'
        return vimix#utils#error(6, linenr, 'Definition Cannot Have Two Auto Values', line)
      endif
      if gui is '~'
        let gui = vimix#convert#ansiToHex(cterm)
      elseif cterm is '~'
        let cterm = vimix#convert#hexToApproxAnsi(gui)
      endif
      let defs[name] = {'cterm':cterm, 'gui':gui}
      if alias isnot ''
        if name =~ '^\d\+$'
          if alias !~ '^\[\l\w\+\]$'
            return vimix#utils#error(4, linenr, 'Definition Has Invalid Alias ('.string(alias).')', line)
          endif
          let alias = strpart(alias, 1, strlen(alias) - 2)
          let defs[alias] = defs[name]
          let base16map[alias] = [str2nr(name), str2nr(name)]
        else
          if alias !~ '^\[\s*\%(\d\+\|none\|\~\)\s*,\s*\%(\d\+\|none\|\~\)\s*\]$'
            return vimix#utils#error(3, linenr, 'Definition Has Invalid Base16 Map ('.string(alias).')', line)
          endif
          let base16map[name] = split(substitute(alias, '^\[\s*\|\s*\]$', '', 'g'), '\s*,\s*')
        endif
      endif

    elseif line =~ '^\%(\s*\w\+\%(\s*->\s*\w\+\)*\s*->\s*\w\+\s*\%(;\|$\)\)\+$'
      " Links: <from> [ -> <from> ... ] -> <to> [ ; <from> [ -> <from> ... ] -> <to> ... ]
      for chunk in split(substitute(line, '^\s\+\|\s\+$', '', 'g'), '\s*;\s*')
        let lchunks = split(chunk, '\s*->\s*')
        let target = substitute(remove(lchunks, -1), '^\s\+\|\s\+$', '', 'g')
        for link in lchunks
          call add(links, printf('highlight! link %s %s', substitute(link, '^\s\+\|\s\+$', '', 'g'), target))
        endfor
      endfor

    elseif line =~ '^\s*\w\+\s\+[[:alnum:]_~].*'
      " Highlight Group: <group> [atts] [foreground] [background]
      let rhs = split(line)
      let group = remove(rhs, 0)
      if rhs is ''
        call vimix#utils#warn(1, linenr, 'Empty Highlight Group', line)
      endif
      let at = 'N'
      let fg = 'none'
      let bg = 'none'
      let ind = 0
      for attr in rhs
        if attr =~ '^\u\+$'
          let at = attr
        elseif has_key(defs, attr)
          if ind is 0
            let fg = attr
            let ind += 1
          elseif ind is 1
            let bg = attr
            let ind += 1
          else
            return vimix#utils#error(7, linenr, 'Too Many Defs (1/2 only) for Hl Group', line)
          endif
        elseif attr isnot '~'
          return vimix#utils#error(8, linenr, 'Unkown Def ('.string(attr).') for Hl Group', line)
        endif
      endfor
      let at = join(map(split(at, '\zs'), 'get(s:atMap, v:val, "NONE")'), ',')
      let f = defs[fg]
      let b = defs[bg]
      call add(lines, printf(s:hiFmt, group, at, f.cterm, b.cterm, at, f.gui, b.gui))
      call add(lines16, printf(s:hiFmt, group, at, base16map[fg][0], base16map[bg][1], at, f.gui, b.gui))

    elseif line !~ '^\s*!'
      " Invalid Line:
      return vimix#utils#error(1, linenr, 'Invalid Line', line)

    endif
  endfor
  return [ meta, defs, groups, lines, lines16, base16map, links ]
endfunction

function! vimix#export(...) abort
  let [ meta, defs, groups, lines, lines16, base16map, links ] = vimix#parse()
  let ind = 0
  while lines[ind] =~ '^\s*"'
    let ind += 1
  endwhile
  call extend(lines, s:preamble(meta, defs, lines16, links), ind)
  let haswin = or(has('win32'), has('win64'))
  let sep = (!haswin || &ssl) ? '/' : '\'
  if a:0 && a:1 isnot ''
    let outdir = a:1
    if outdir[-1:] isnot sep
      let outdir .= sep
    endif
  else
    let cfg = ['.vim', '.config/nvim', 'vimfiles', 'AppData/Local/nvim'][has('nvim') + haswin * 2]
    let outdir = printf('%s%s%s%scolors%s', $HOME, sep, cfg, sep, sep)
  endif
  let out = outdir.(meta.name).'.vim'
  if filereadable(out) && (a:0 > 2 && !a:3 && confirm('File Exists: '.fnameescape(out).' Overwrite?', "&Yes\n&No") isnot 1)
    execute 'noautocmd' (a:0 > 1 ? a:2 : '') 'new'
  else
    let wid = bufwinid(bufnr(fnamemodify(out, ':p')))
    if wid is -1
      let v:swapchoice = 'e'
      execute 'noautocmd noswapfile' (a:0 > 1 ? a:2 : '') 'split' fnameescape(out)
    else
      call win_gotoid(wid)
    endif
    silent setlocal noreadonly modifiable
    silent! %delete
  endif
  silent call setline(1, lines)
  silent setfiletype vim
  silent normal! G=gg
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
