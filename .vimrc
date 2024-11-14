" =============================
" 기본 설정
" =============================
set nocompatible          " Vi 호환 모드를 끄기
syntax on                 " 문법 강조 활성화
filetype plugin indent on " 파일 유형에 따른 플러그인 및 들여쓰기 설정

set number                " 줄 번호 표시
set relativenumber        " 상대 번호 표시 (현재 줄을 기준으로)
set showcmd               " 명령어 입력 시 화면에 표시
set cursorline            " 현재 줄 강조
set wildmenu              " 명령어 자동 완성 메뉴 활성화
set showmatch             " 일치하는 괄호를 강조 표시
set ignorecase            " 검색 시 대소문자 무시
set smartcase             " 대소문자가 포함된 경우에는 대소문자 구분

" =============================
" 편집 및 들여쓰기 설정
" =============================
set tabstop=2             " 탭 폭을 4로 설정
set shiftwidth=2          " 자동 들여쓰기 폭을 4로 설정
set expandtab             " 탭을 공백으로 변환
set autoindent            " 새 줄에서 이전 줄의 들여쓰기 유지
set smartindent           " 스마트한 들여쓰기

" =============================
" 검색 설정
" =============================
set hlsearch              " 검색 결과 하이라이트
set incsearch             " 입력하는 동안 점진적 검색
set wrapscan              " 파일의 끝에서 검색이 다시 시작되도록 설정

" =============================
" 화면 및 스크롤 설정
" =============================
set scrolloff=8           " 커서 위아래로 여백 유지
set sidescrolloff=8       " 커서 좌우로 여백 유지
set wrap                  " 텍스트 줄 바꿈
set linebreak             " 단어 단위로 줄 바꿈

" =============================
" 기타 편리한 설정
" =============================
set clipboard=unnamedplus " 시스템 클립보드와 연동
set backspace=indent,eol,start " 백스페이스로 들여쓰기 삭제 허용
set hidden                " 파일 수정 중 다른 파일 열기 허용
set mouse=a               " 마우스 사용 허용

" =============================
" 편리한 키 매핑
" =============================
nnoremap <C-s> :w<CR>     " Ctrl+s로 저장
nnoremap <C-q> :q<CR>     " Ctrl+q로 종료
vnoremap <C-c> "+y        " 비주얼 모드에서 Ctrl+c로 클립보드 복사
inoremap jk <Esc>         " 입력 모드에서 jk를 눌러서 빠르게 종료

" 플러그인 설정
call plug#begin('~/.vim/plugged')
Plug 'sheerun/vim-polyglot'
Plug 'morhetz/gruvbox'
call plug#end()

" ==============
" 플러그인 세팅
" ==============
syntax on
set background=dark
colorscheme gruvbox

" =============================
" vim-polyglot 세팅
" =============================
" polyglot은 설치 후 자동으로 언어에 맞는 하이라이트 적용
" 특정 언어만 강조하고 싶다면 다음과 같이 설정 가능:
" let g:polyglot_disabled = ['html', 'css']
