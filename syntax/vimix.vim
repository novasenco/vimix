
syntax match vimixComment #[!"<].*#
syntax match vimixMetaTitle "\%(^\s*\"\s*\)\@<=\%(\u\w\+\s*\)\+:" contained containedin=vimixComment

syntax match vimixAnsi "\<\d\+\>" contained containedin=vimixDefLine,vimixHiLine
syntax match vimixHex   "#\x\{6\}" contained containedin=vimixDefLine,vimixHiLine
syntax match vimixName "[[:lower:]_][[:alnum:]_-]*\|-" contained containedin=vimixHiLine
syntax match vimixAuto "\~" contained containedin=vimixDefLine,vimixHiLine
syntax match vimixNone "-\|none" contained containedin=vimixDefLine,vimixHiLine

syntax match vimixDefLine "^\s*\%(\d\+\|\l\w*\)\s*:.*" contains=vimixComment
syntax match vimixDefId "\%(^\s*\)\@<=\%(\d\+\|\l\w*\)\%(\s*:\)\@=" contained containedin=vimixDefLine
syntax region vimixDefAlias matchgroup=vimixDefAliasBracket start="\[" end="\]" contained containedin=vimixDefLine

syntax match vimixMetaLine "^\s*-[^:]*:.*"
syntax match vimixMetaId "^\s*-\s*\zs[^:]*" contained containedin=vimixMetaLine

syntax match vimixHiLine "^\s*\w\+\s\+[[:alnum:]_~].*" keepend contains=vimixComment
syntax match vimixHiGroup "^\s*\zs\w\+" contained containedin=vimixHiLine
syntax match vimixHiAtts "\<[BURIN]\+\>" contained containedin=vimixHiLine

syntax match vimixLinkLine "^\s*\w\+\s*->.*" contains=vimixComment
syntax match vimixLinkArrow "->" contained containedin=vimixLinkLine
syntax match vimixSemiError "\%(->\s*\w\+\s*\)\@<!;" contained containedin=vimixLinkLine
syntax match vimixLinkName "\w\+" contained containedin=vimixLinkLine

silent! syntax include @vimixVim syntax/vim.vim
silent! syntax include @vimixVim after/syntax/vim.vim
syntax region vimixExCmd matchgroup=vimixVimPrefix start="^:" end="$" contains=@vimixVim keepend
syntax region vimixExLink matchgroup=vimixVimPrefix start="^>" end="$" contains=@vimixVim keepend

highlight default link vimixComment Comment
highlight default link vimixHiGroup Statement
highlight default link vimixHiAtts String
highlight default link vimixMetaTitle Title
highlight default link vimixDefId Statement
highlight default link vimixDefAlias Identifier
highlight default link vimixDefBase16 Identifier
" highlight default link vimixDefAliasBracket Identifier
highlight default link vimixAnsi Constant
highlight default link vimixHex String
highlight default link vimixName Identifier
highlight default link vimixAuto Constant
highlight default link vimixNone Constant
highlight default link vimixLinkArrow Operator
highlight default link vimixLinkName Identifier
highlight default link vimixMetaLine Comment
highlight default link vimixConditional Operator
highlight default link vimixSemiError Error

