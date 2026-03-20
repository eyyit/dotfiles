" vim-plug
" :PlugInstall to install the plugins
" :PlugUpdate to update them
" :PlugClean will remove unused plugins
" :PlugUpgrade will update vim-plug
call plug#begin('~/.vim_plugins')
"Plug 'dense-analysis/ale'      " Asynchronous Lint Engine.
Plug 'elzr/vim-json'           " Better json highlighting.
"Plug 'scrooloose/syntastic'    " Waiting on Bionic.
Plug 'neomake/neomake'
Plug 'godlygeek/tabular'       " Align text on specific characters.
Plug 'rodjek/vim-puppet'       " Make vim more Puppet friendly.
Plug 'tpope/vim-fugitive'      " Git integration.
Plug 'vim-airline/vim-airline' " Airline statusbar.
call plug#end()

set rtp+=~/.vim_plugins/powerline/powerline/bindings/vim

" Custom Functions
if !exists('MyFuncLoad')
  let MyFuncLoad = 1

  " Paste Mode
  function! TogglePasteMode()
    set number!
    set list!
    set paste!
    silent! IndentLinesToggle
    if &signcolumn == 'auto'
      set signcolumn=no
    else
      set signcolumn=auto
    endif
  endfunction
endif


" Setup
set autoindent                                " Automatically indents lines.
set autoread                                  " Automatically reloads the file if it changes outside of Vim.
set backspace=indent,eol,start                " Defines backspace behavior.
set backup                                    " Creates backup files.
set complete=.,w,b,u,U,t,i,d                  " Configures tab completion options.
set equalalways                               " Keeps windows the same size.
set expandtab                                 " Use spaces instead of tab characters.
set foldenable                                " Enables folding.
set foldlevel=20                              " Sets the initial folding level.
set foldlevelstart=20                         " Sets the initial folding level for when the file is opened.
set foldmethod=syntax                         " Uses syntax highlighting for folding.
set history=3000                              " Increases the command-line history size. (default: 20)
set hlsearch                                  " Highlights matching search terms.
set ignorecase                                " Default to case-insensitive search.
set incsearch                                 " Searches while typing.
set keywordprg=TERM=mostlike\ man\ -s\ -Pless " (default man -s)
set laststatus=2                              " Always shows the status line.
set lazyredraw                                " Avoids unnecessary redrawing.
set list                                      " Eables non-printable characters display according to the listchars setting.
set listchars=tab:»\ ,trail:·,extends:…       " Sets the characters used to represent specific non-printable characters.
set modeline                                  " Allows specifing settings in a file's header or footer.
set noautowrite                               " Disables automatic writing on :next.
set nocursorline                              " Disables the cursor line.
set noerrorbells visualbell t_vb=             " Disable all bells
set nohidden                                  " Closes the buffer when closing a tab.
set nospell                                   " Disables spelling checking by default.
set nowrap                                    " Disables line wrapping.
set number                                    " Displays line numbers.
set ruler                                     " Displays the cursor position.
set scrolloff=5                               " Shows a few lines above/below the cursor while scrolling.
set shiftwidth=2                              " Sets the number of spaces for each level of indentation.
set showcmd                                   " Shows the command being typed.
set showmatch                                 " Shows matching brackets.
set showmode                                  " Always shows the mode.
set showtabline=1                             " Shows the tabline if there are multiple tabs.
set sidescroll=2                              " Faster horizontal scrolling if wrap is off.
set sidescrolloff=5                           " Keeps at least 5 lines left/right while scrolling horizontally.
set smartcase                                 " Case-sensitive search when needed.
set smartindent                               " Enables smart indenting.
set smarttab                                  " Uses shiftwidth instead of tabstop at the beginning of a line.
set softtabstop=2                             " Deletes expanded tabs with a single keystroke.
set splitright splitbelow                     " Splits open windows to the right or below.
set swapfile                                  " Use a swapfile.
set switchbuf=usetab                          " Switches buffers using tabs.
set tabpagemax=30                             " Limits the number of tabs to 30.
set tabstop=2                                 " Sets the width of a tab character.
set ttyfast                                   " Optimizes Vim for fast terminals.
set undolevels=5000                           " Sets a large number of undo levels (default is 1000).
set updatecount=50                            " Switches to the backup file every 50 characters (default is 200).
set whichwrap+=b,s,<,>,h,l,[,]                " Enables wrapping at the beginning or end of lines, brackets, and other characters (default: b,s).
set wildignore=*.o,*.obj*.bak,*.so,*.exe      " Specifies file patterns to be ignored during command-line completion.
set wildmenu                                  " Enables visual command-line completion menu.
set wildmode=longest:full,full                " Defines the behavior of command-line completion modes.
set winheight=2                               " Sets more room for windows if possible.
set winminheight=0                            " Allows smashing windows down to the status line.

" Create .state directory, readable by the group.
silent execute '!(umask 027; mkdir -p ~/.vim/state)'

" Buffers
if has('persistent_undo')
  set undodir=~/.vim/state
  set undofile
endif

" Backups
set backupdir=~/.vim/state
set directory=~/.vim/state

" Syntastic
let g:syntastic_python_pylint_args = '--rcfile=~/.pylintrc'
let g:syntastic_python_checkers = ['python']
let g:syntastic_python_python_exec = 'python3'
nmap <LocalLeader>s :SyntasticCheck<CR>

" Visual Tweaks
set ambiwidth=single
set t_ut= " Disable Background Color Erase to fix terminal rendering glitches
set t_Co=256
set background=dark
let g:solarized_termcolors = 256
let g:solarized_termtrans = 1
colorscheme my-custom-solarized

" 80 column vertical bar
set colorcolumn=81
highlight ColorColumn ctermfg=none ctermbg=235

" Search color highlights
highlight Search cterm=none ctermfg=white ctermbg=27

" Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_min_count = 2

" ALE
let g:airline#extensions#ale#enabled = 1
let g:ale_change_sign_column_color = 1
let g:ale_echo_cursor = 0
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 0
let g:ale_python_pylint_use_msg_id = 1
let g:ale_virtualtext_cursor = 0

" Set unicode support if possible.
if &termencoding == ''
  let &termencoding = &encoding
endif
scriptencoding utf-8                   " Set character encodings for vimscripts.
set encoding=utf-8                     " Sets the default encoding for text in buffers to UTF-8.
set fileencodings=ucs-bom,utf-8,latin1 " Defines the order of encoding detection when reading a file.

" Maps
map <silent> <LocalLeader>ri G=gg<CR>                " Reindent file
map <silent> <LocalLeader>Cs :%s/\s\+$//e<CR>        " Clear spaces at end of line
nnoremap <LocalLeader>pm :call TogglePasteMode()<CR> " Toggle paste mode.
noremap <LocalLeader>ww :set wrap!<CR>               " Toggle line wrapping.
map <LocalLeader>tc :tabnew %<CR>                    " New tab
map <LocalLeader>tk :tabclose<CR>                    " Close tab
map <LocalLeader>tn :tabnext<CR>                     " Next tab
map <LocalLeader>tp :tabprev<CR>                     " Previous tab
noremap F zf%                                        " Fold with paren begin/end matching
map <LocalLeader>hl :set hlsearch! hlsearch?<CR>     " Toggle highlighted search

" Commands
if !exists(':WQ')
  silent! command WQ wq
endif
if !exists(':Wq')
  silent! command Wq wq
endif
if !exists(':Q')
  silent! command Q q!
endif
if has('autocmd')
  if !exists('autocommands_loaded')
    let autocommands_loaded = 1

    " Save backupfile as backupdir/filename-06-13-1331
    autocmd BufWritePre * let &bex = strftime('-%m-%d-%H%M')

    autocmd BufRead /etc/apache/* setlocal filetype=apache2
    autocmd BufRead *.sh,/etc/cron* setlocal filetype=sh
    autocmd BufRead *.vim,vimrc setlocal filetype=vim
    autocmd BufRead *.c,*.h setlocal filetype=c
    autocmd BufRead syslog-ng.conf setlocal filetype=syslog-ng
    autocmd BufRead *.erb setlocal indentexpr= " disable auto indent
    autocmd BufRead *.eyaml setlocal filetype=yaml
    autocmd BufRead *.yml setlocal filetype=yaml
    autocmd BufRead *.yml setlocal indentexpr= " disable auto indent
    autocmd BufRead *.go setlocal filetype=go
    autocmd BufRead *.pp setlocal filetype=puppet
    autocmd BufRead *.plist setlocal noexpandtab
    autocmd BufRead *.plist.erb setlocal noexpandtab

    autocmd BufWinLeave *.sh,*.conf,*.vim,vimrc,*.c,*.txt mkview
    autocmd BufWinEnter *.sh,*.conf,*.vim,vimrc,*.c,*.txt silent loadview

    " When editing a file, always jump to the last known cursor position. Don't do it when the position is invalid or when inside an event handler
    " (happens when dropping a file on gvim). Also don't do it when the mark is in the first line, that is the default position when opening a file.
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

    autocmd BufWinLeave * call clearmatches()

    " Turn on omni-completion for the appropriate file types.
    autocmd FileType crontab set nobackup nowritebackup
    autocmd FileType python set omnifunc=pythoncomplete#Complete
    autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
    autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
    autocmd FileType css set omnifunc=csscomplete#CompleteCSS
    autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
    autocmd FileType php set omnifunc=phpcomplete#CompletePHP
    autocmd FileType c set omnifunc=ccomplete#Complete
    autocmd FileType ruby,eruby set omnifunc=rubycomplete#Complete
    autocmd FileType ruby,eruby let g:rubycomplete_rails = 1  " Rails support
    autocmd FileType go,java setlocal noexpandtab
    autocmd FileType go set colorcolumn=100
    autocmd FileType puppet set colorcolumn=0

    " Convenient command to see the difference between the current buffer and the
    " file it was loaded from, thus the changes you made.  Only define it when not defined already.
    if !exists(':DiffOrig')
      command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis
      nnoremap <Leader>d :DiffOrig<CR>
    endif
  endif
endif
