#!/usr/bin/env bash
# Worktree dashboard for tmux popup — interactive cursor-based UI

# ── Arguments ────────────────────────────────────────────────────────────────
if [[ -n "$1" && "$1" != *"#{"* ]]; then
  PANE_PATH="$1"
else
  PANE_PATH=$(tmux display-message -p -t "${TMUX_PANE:-}" '#{pane_current_path}' 2>/dev/null || echo "$PWD")
fi

CALLER_PANE="$2"

# ── Colors ───────────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[1;32m"
RED="\033[1;31m"
WHITE="\033[37m"
CYAN="\033[36m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
REVERSE="\033[7m"

# ── Git check ────────────────────────────────────────────────────────────────
if ! git -C "$PANE_PATH" rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Not a git repository"
  exit 0
fi

repo_root=$(git -C "$PANE_PATH" rev-parse --show-toplevel 2>/dev/null)
repo_name=$(basename "$repo_root")
real_pane=$(cd "$PANE_PATH" 2>/dev/null && pwd -P || echo "$PANE_PATH")

filter_text=""

# ── Collect pane info ────────────────────────────────────────────────────────
# Build associative array: real_path → list of "pane_id:window_name"
declare -A pane_map
collect_panes() {
  pane_map=()
  while IFS=$'\t' read -r pid ppath wname; do
    local real_p
    real_p=$(cd "$ppath" 2>/dev/null && pwd -P || echo "$ppath")
    if [[ -n "${pane_map[$real_p]}" ]]; then
      pane_map[$real_p]="${pane_map[$real_p]},$pid"
    else
      pane_map[$real_p]="$pid"
    fi
  done < <(tmux list-panes -a -F $'#{pane_id}\t#{pane_current_path}\t#{window_name}' 2>/dev/null)
}

# Find panes whose path is inside a given worktree
find_panes_for_wt() {
  local wt_real="$1"
  local result=""
  for ppath in "${!pane_map[@]}"; do
    if [[ "$ppath" == "$wt_real" || "$ppath" == "$wt_real/"* ]]; then
      if [[ -n "$result" ]]; then
        result="${result},${pane_map[$ppath]}"
      else
        result="${pane_map[$ppath]}"
      fi
    fi
  done
  echo "$result"
}

# ── Parse worktrees ──────────────────────────────────────────────────────────
parse_worktrees() {
  wt_data=$(git -C "$PANE_PATH" worktree list --porcelain 2>/dev/null)
  collect_panes

  all_entries=()
  main_wt=""
  local cur_path="" cur_branch=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.+) ]]; then
      cur_path="${BASH_REMATCH[1]}"
      cur_branch=""
    elif [[ "$line" =~ ^branch\ refs/heads/(.+) ]]; then
      cur_branch="${BASH_REMATCH[1]}"
    elif [[ "$line" == "" && -n "$cur_path" ]]; then
      local tag=""
      if [[ "$cur_path" == *"/.claude/worktrees/"* ]]; then
        tag="claude"
      elif [[ "$cur_path" == *"/.dmux/worktrees/"* || "$cur_path" == *"/dmux-"* ]]; then
        tag="dmux"
      fi
      [[ -z "$main_wt" ]] && main_wt="$cur_path"

      local dirty="" ahead_behind=""
      if [[ -d "$cur_path/.git" || -f "$cur_path/.git" ]]; then
        if [[ -n "$(git -C "$cur_path" status --porcelain 2>/dev/null | head -1)" ]]; then
          dirty="*"
        fi
        local ab
        ab=$(git -C "$cur_path" rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null)
        if [[ -n "$ab" ]]; then
          local behind ahead
          behind=$(echo "$ab" | awk '{print $1}')
          ahead=$(echo "$ab" | awk '{print $2}')
          local parts=""
          (( ahead > 0 )) && parts="↑${ahead}"
          (( behind > 0 )) && parts="${parts}↓${behind}"
          ahead_behind="$parts"
        fi
      fi

      # Find panes in this worktree
      local real_cur
      real_cur=$(cd "$cur_path" 2>/dev/null && pwd -P || echo "$cur_path")
      local panes
      panes=$(find_panes_for_wt "$real_cur")

      all_entries+=("${cur_path}|${cur_branch}|${tag}|${dirty}|${ahead_behind}|${panes}")
      cur_path="" cur_branch=""
    fi
  done <<< "$wt_data"

  if [[ -n "$cur_path" ]]; then
    local tag=""
    if [[ "$cur_path" == *"/.claude/worktrees/"* ]]; then
      tag="claude"
    elif [[ "$cur_path" == *"/.dmux/worktrees/"* || "$cur_path" == *"/dmux-"* ]]; then
      tag="dmux"
    fi
    [[ -z "$main_wt" ]] && main_wt="$cur_path"
    local dirty="" ahead_behind=""
    if [[ -d "$cur_path/.git" || -f "$cur_path/.git" ]]; then
      if [[ -n "$(git -C "$cur_path" status --porcelain 2>/dev/null | head -1)" ]]; then
        dirty="*"
      fi
      local ab
      ab=$(git -C "$cur_path" rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null)
      if [[ -n "$ab" ]]; then
        local behind ahead
        behind=$(echo "$ab" | awk '{print $1}')
        ahead=$(echo "$ab" | awk '{print $2}')
        local parts=""
        (( ahead > 0 )) && parts="↑${ahead}"
        (( behind > 0 )) && parts="${parts}↓${behind}"
        ahead_behind="$parts"
      fi
    fi
    local real_cur
    real_cur=$(cd "$cur_path" 2>/dev/null && pwd -P || echo "$cur_path")
    local panes
    panes=$(find_panes_for_wt "$real_cur")
    all_entries+=("${cur_path}|${cur_branch}|${tag}|${dirty}|${ahead_behind}|${panes}")
  fi

  apply_filter
}

# ── Filter ───────────────────────────────────────────────────────────────────
apply_filter() {
  entries=()
  if [[ -z "$filter_text" ]]; then
    entries=("${all_entries[@]}")
  else
    for entry in "${all_entries[@]}"; do
      IFS='|' read -r _ branch _ _ _ _ <<< "$entry"
      if [[ "${branch,,}" == *"${filter_text,,}"* ]]; then
        entries+=("$entry")
      fi
    done
  fi
}

# ── Render ───────────────────────────────────────────────────────────────────
render() {
  local wt_count="${#entries[@]}"
  local total_count="${#all_entries[@]}"
  printf "\033[?25l"
  clear

  echo ""
  if [[ -n "$filter_text" ]]; then
    printf " ${BOLD} Worktrees — %s (%s/%s)${RESET}  ${YELLOW}/%s${RESET}\n" \
      "$repo_name" "$wt_count" "$total_count" "$filter_text"
  else
    printf " ${BOLD} Worktrees — %s (%s)${RESET}\n" "$repo_name" "$total_count"
  fi
  echo " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local i=0
  for entry in "${entries[@]}"; do
    IFS='|' read -r wt_path branch tag dirty ahead_behind panes <<< "$entry"
    local real_wt
    real_wt=$(cd "$wt_path" 2>/dev/null && pwd -P || echo "$wt_path")

    local marker
    if [[ "$real_pane" == "$real_wt" || "$real_pane" == "$real_wt/"* ]]; then
      marker="${GREEN}●${RESET}"
    elif [[ "$wt_path" == "$main_wt" ]]; then
      marker="${WHITE}●${RESET}"
    else
      marker="${CYAN}◆${RESET}"
    fi

    local display_branch="$branch"
    (( ${#display_branch} > 22 )) && display_branch="${display_branch:0:20}.."

    local tag_str=""
    [[ -n "$tag" ]] && tag_str=" ${YELLOW}[$tag]${RESET}"

    local dirty_str=""
    [[ -n "$dirty" ]] && dirty_str=" ${RED}*${RESET}"

    local ab_str=""
    [[ -n "$ahead_behind" ]] && ab_str=" ${MAGENTA}${ahead_behind}${RESET}"

    # Pane display
    local pane_str=""
    if [[ -n "$panes" ]]; then
      pane_str=" ${CYAN}[${panes}]${RESET}"
    fi

    local display_path
    if [[ "$wt_path" == "$main_wt" ]]; then
      display_path="$wt_path"
    else
      display_path="${wt_path/#$HOME/~}"
      (( ${#display_path} > 28 )) && display_path="..${display_path: -26}"
    fi

    if (( i == cursor )); then
      printf " ${REVERSE} ▸ ${marker}${REVERSE} %-22s${dirty_str}${ab_str}${tag_str}${pane_str}${REVERSE}  %-28s ${RESET}\n" \
        "$display_branch" "$display_path"
    else
      printf "   ${marker} %-22s${dirty_str}${ab_str}${tag_str}${pane_str}  ${DIM}%s${RESET}\n" \
        "$display_branch" "$display_path"
    fi
    (( i++ ))
  done

  echo ""
  echo -e " ${DIM}j/k=move  Enter=go  o=open  l=log  d=delete  p=prune  /=filter  q=quit${RESET}"
}

# ── Actions ──────────────────────────────────────────────────────────────────
get_selected() {
  IFS='|' read -r sel_path sel_branch sel_tag sel_dirty sel_ab sel_panes <<< "${entries[$cursor]}"
}

do_go() {
  get_selected

  if [[ -z "$sel_panes" ]]; then
    # No panes in this worktree — cd in caller pane
    if [[ -n "$CALLER_PANE" && "$CALLER_PANE" != *"#{"* ]]; then
      tmux send-keys -t "$CALLER_PANE" "cd $(printf '%q' "$sel_path")" C-m
    fi
    printf "\033[?25h"
    exit 0
  fi

  # Split panes by comma
  IFS=',' read -ra pane_list <<< "$sel_panes"

  if (( ${#pane_list[@]} == 1 )); then
    # Single pane — switch directly
    tmux switch-client -t "${pane_list[0]}" 2>/dev/null || \
      tmux select-pane -t "${pane_list[0]}" 2>/dev/null
    printf "\033[?25h"
    exit 0
  fi

  # Multiple panes — sub-selection
  local pane_cursor=0
  while true; do
    clear
    echo ""
    printf " ${BOLD} %s — select pane${RESET}\n" "$sel_branch"
    echo " ──────────────────────────────────"
    echo ""

    local pi=0
    for pid in "${pane_list[@]}"; do
      # Get pane details
      local pane_info
      pane_info=$(tmux display-message -p -t "$pid" \
        '#{window_index}.#{pane_index} #{window_name} #{pane_current_command}' 2>/dev/null)
      if (( pi == pane_cursor )); then
        printf " ${REVERSE} ▸ %s  %s ${RESET}\n" "$pid" "$pane_info"
      else
        printf "   ${DIM}%s${RESET}  %s\n" "$pid" "$pane_info"
      fi
      (( pi++ ))
    done

    echo ""
    echo -e " ${DIM}j/k=move  Enter=switch  q=back${RESET}"

    local pkey
    read -rsn1 pkey </dev/tty

    if [[ "$pkey" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 pseq </dev/tty
      case "$pseq" in
        '[A') pkey="k" ;;
        '[B') pkey="j" ;;
        *) continue ;;
      esac
    fi

    case "$pkey" in
      j) (( pane_cursor < ${#pane_list[@]} - 1 )) && (( pane_cursor++ )) ;;
      k) (( pane_cursor > 0 )) && (( pane_cursor-- )) ;;
      "")
        tmux switch-client -t "${pane_list[$pane_cursor]}" 2>/dev/null || \
          tmux select-pane -t "${pane_list[$pane_cursor]}" 2>/dev/null
        printf "\033[?25h"
        exit 0
        ;;
      q|Q) return ;;
    esac
  done
}

do_open() {
  get_selected
  local branch_short
  branch_short=$(basename "$sel_branch")
  branch_short="${branch_short:0:20}"
  tmux new-window -c "$sel_path" -n "$branch_short"
  printf "\033[?25h"
  exit 0
}

do_log() {
  get_selected
  clear
  echo ""
  printf " ${BOLD} %s${RESET}\n" "$sel_branch"
  echo " ──────────────────────────────────"
  git -C "$sel_path" log --oneline -5 2>/dev/null | while IFS= read -r logline; do
    echo "  $logline"
  done
  echo ""
  printf " Press any key to return..."
  read -rsn1 </dev/tty
}

do_delete() {
  get_selected
  if [[ "$sel_path" == "$main_wt" ]]; then
    clear
    echo ""
    echo " Cannot delete main worktree"
    echo ""
    printf " Press any key..."
    read -rsn1 </dev/tty
    return
  fi
  clear
  echo ""
  printf " Delete '${sel_branch}'? [y/N]: "
  printf "\033[?25h"
  local confirm
  read -r confirm </dev/tty
  printf "\033[?25l"
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    git worktree remove "$sel_path" 2>&1
    parse_worktrees
    local max=$(( ${#entries[@]} - 1 ))
    (( cursor > max )) && cursor=$max
    (( cursor < 0 )) && cursor=0
  fi
}

do_prune() {
  clear
  echo ""
  printf " ${BOLD} Pruning stale worktrees...${RESET}\n"
  echo " ──────────────────────────────────"
  git -C "$PANE_PATH" worktree prune -v 2>&1 | while IFS= read -r line; do
    echo "  $line"
  done
  echo ""
  printf " Done. Press any key to return..."
  read -rsn1 </dev/tty
  parse_worktrees
  local max=$(( ${#entries[@]} - 1 ))
  (( cursor > max )) && cursor=$max
  (( cursor < 0 )) && cursor=0
}

do_filter() {
  filter_text=""
  while true; do
    apply_filter
    local max=$(( ${#entries[@]} - 1 ))
    (( max < 0 )) && max=0
    (( cursor > max )) && cursor=$max
    render
    printf "\033[?25h"
    printf "\r ${BOLD}/${RESET}${filter_text}\033[K"

    local ch
    read -rsn1 ch </dev/tty

    if [[ "$ch" == "" ]]; then
      printf "\033[?25l"
      return
    elif [[ "$ch" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 _ </dev/tty
      filter_text=""
      apply_filter
      cursor=0
      printf "\033[?25l"
      return
    elif [[ "$ch" == $'\x7f' || "$ch" == $'\x08' ]]; then
      if [[ -n "$filter_text" ]]; then
        filter_text="${filter_text%?}"
      fi
    else
      filter_text="${filter_text}${ch}"
    fi
  done
}

# ── Main loop ────────────────────────────────────────────────────────────────
parse_worktrees
cursor=0

trap 'printf "\033[?25h"' EXIT

while true; do
  render

  local_count="${#entries[@]}"
  if (( local_count == 0 )); then
    if [[ -n "$filter_text" ]]; then
      read -rsn1 </dev/tty
      filter_text=""
      apply_filter
      cursor=0
      continue
    fi
    echo " No worktrees found."
    read -rsn1 </dev/tty
    exit 0
  fi

  read -rsn1 key </dev/tty

  if [[ "$key" == $'\x1b' ]]; then
    read -rsn2 -t 0.1 seq </dev/tty
    case "$seq" in
      '[A') key="k" ;;
      '[B') key="j" ;;
      *) continue ;;
    esac
  fi

  case "$key" in
    j) (( cursor < local_count - 1 )) && (( cursor++ )) ;;
    k) (( cursor > 0 )) && (( cursor-- )) ;;
    "") do_go ;;
    o) do_open ;;
    l) do_log ;;
    d) do_delete ;;
    p) do_prune ;;
    /) do_filter ;;
    q|Q) exit 0 ;;
    g) cursor=0 ;;
    G) cursor=$(( local_count - 1 )) ;;
  esac
done
