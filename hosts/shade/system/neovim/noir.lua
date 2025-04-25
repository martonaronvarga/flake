vim.cmd([[
  highlight clear
  set background=dark
  if version > 580
    if exists("syntax_on")
      syntax reset
    endif
  endif
  let g:colors_name = "256_noir_custom"

  if has("gui_running") || &t_Co == 256
    hi Normal       cterm=NONE ctermfg=250 ctermbg=16  gui=NONE guifg=#bcbcbc guibg=#000000
    hi Keyword      cterm=NONE ctermfg=255 ctermbg=16  gui=NONE guifg=#eeeeee guibg=#000000
    hi Constant     cterm=NONE ctermfg=252 ctermbg=16  gui=NONE guifg=#d0d0d0 guibg=#000000
    hi String       cterm=NONE ctermfg=245 ctermbg=16  gui=NONE guifg=#8a8a8a guibg=#000000
    hi Comment      cterm=NONE ctermfg=240 ctermbg=16  gui=NONE guifg=#585858 guibg=#000000
    hi Number       cterm=NONE ctermfg=196 ctermbg=16  gui=NONE guifg=#ff0000 guibg=#000000
    hi Error        cterm=NONE ctermfg=255 ctermbg=88  gui=NONE guifg=#eeeeee guibg=#870000
    hi ErrorMsg     cterm=NONE ctermfg=255 ctermbg=124 gui=NONE guifg=#eeeeee guibg=#af0000
    hi Search       cterm=NONE ctermfg=245 ctermbg=236 gui=NONE guifg=#8a8a8a guibg=#303030
    hi IncSearch    cterm=reverse ctermfg=255 ctermbg=245 gui=reverse guifg=#eeeeee guibg=#8a8a8a
    hi DiffChange   cterm=NONE ctermfg=160 ctermbg=255 gui=NONE guifg=#d70000 guibg=#eeeeee
    hi DiffText     cterm=bold ctermfg=250 ctermbg=196 gui=bold guifg=#bcbcbc guibg=#ff0000
    hi SignColumn   cterm=NONE ctermfg=124 ctermbg=240 gui=NONE guifg=#af0000 guibg=#585858
    hi SpellBad     cterm=undercurl ctermfg=255 ctermbg=88  gui=undercurl guifg=#eeeeee guibg=#870000
    hi SpellCap     cterm=NONE ctermfg=255 ctermbg=124 gui=NONE guifg=#eeeeee guibg=#af0000
    hi SpellRare    cterm=NONE ctermfg=124 ctermbg=16  gui=NONE guifg=#af0000 guibg=#000000
    hi WildMenu     cterm=NONE ctermfg=240 ctermbg=255 gui=NONE guifg=#585858 guibg=#eeeeee
    hi Pmenu        cterm=NONE ctermfg=255 ctermbg=240 gui=NONE guifg=#eeeeee guibg=#585858
    hi PmenuThumb   cterm=NONE ctermfg=232 ctermbg=240 gui=NONE guifg=#080808 guibg=#585858
    hi SpecialKey   cterm=NONE ctermfg=16  ctermbg=255 gui=NONE guifg=#000000 guibg=#eeeeee
    hi MatchParen   cterm=NONE ctermfg=16  ctermbg=240 gui=NONE guifg=#000000 guibg=#585858
    hi CursorLine   cterm=NONE ctermfg=NONE ctermbg=233 gui=NONE guifg=NONE guibg=#121212
    hi StatusLine   cterm=bold,reverse ctermfg=245 ctermbg=16  gui=bold,reverse guifg=#8a8a8a guibg=#000000
    hi StatusLineNC cterm=reverse ctermfg=236 ctermbg=16  gui=reverse guifg=#303030 guibg=#000000
    hi Visual       cterm=reverse ctermfg=250 ctermbg=16  gui=reverse guifg=#bcbcbc guibg=#000000
    hi TermCursor   cterm=reverse ctermfg=NONE ctermbg=NONE gui=reverse guifg=NONE guibg=NONE
    hi Directory    cterm=NONE ctermfg=29  ctermbg=16  gui=NONE guifg=#2a5c45 guibg=#000000
    hi Function     cterm=NONE ctermfg=29  ctermbg=16  gui=NONE guifg=#2a5c45 guibg=#000000
    hi Type         cterm=NONE ctermfg=29  ctermbg=16  gui=NONE guifg=#2a5c45 guibg=#000000
    hi Identifier   cterm=NONE ctermfg=29  ctermbg=16  gui=NONE guifg=#2a5c45 guibg=#000000
    hi Statement    cterm=NONE ctermfg=29  ctermbg=16  gui=NONE guifg=#2a5c45 guibg=#000000
  else
    hi Normal       cterm=NONE ctermfg=Gray ctermbg=Black
    hi Keyword      cterm=NONE ctermfg=White ctermbg=Black
    hi Constant     cterm=NONE ctermfg=Gray ctermbg=Black
    hi String       cterm=NONE ctermfg=Gray ctermbg=Black
    hi Comment      cterm=NONE ctermfg=DarkGray ctermbg=Black
    hi Number       cterm=NONE ctermfg=Red ctermbg=Black
    hi Error        cterm=NONE ctermfg=White ctermbg=DarkRed
    hi ErrorMsg     cterm=NONE ctermfg=White ctermbg=Red
    hi Search       cterm=NONE ctermfg=Gray ctermbg=DarkGray
    hi IncSearch    cterm=reverse ctermfg=White ctermbg=Gray
    hi DiffChange   cterm=NONE ctermfg=Red ctermbg=White
    hi DiffText     cterm=bold ctermfg=Gray c
::contentReference[oaicite:0]{index=0}
]])
