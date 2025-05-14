# Setup fzf
# ---------
if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
fi

_fzf_complete_m() {
  _fzf_complete --min-height 15 -- "$@" < <(
    mise tasks ls --no-header
  )
}
_fzf_complete_m_post() {
  awk '{print $1}'
}

_fzf_complete_make() {
  _fzf_complete --min-height 15 -- "$@" < <(
    make fzf-list
  )
}
_fzf_complete_make_post() {
  awk '{print $1}'
}

source <(fzf --zsh)
