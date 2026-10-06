#!/usr/bin/env bash
# Interactive shell helpers, sourced by mybashrc.
# Also loads setup_lib.sh so its helpers (copy_precommit_config, renew_project, ...)
# stay available as shell commands.

# shellcheck source=setup_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/setup_lib.sh"

d1() { du -h --max-depth=1 "${1:-.}" 2>/dev/null | sort -h; }
dtop() { du -h --max-depth=2 "${1:-.}" 2>/dev/null | sort -hr | head -n 20; }

# Bash utility functions
countfiles() {
  local dir="${1:-.}"  # Use current directory if none provided
  for d in "$dir"/*/* ; do
    [ -d "$d" ] && echo -n "$d: " && find "$d" -type f | wc -l
  done
}

extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz) tar xzf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.rar) unrar x "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar xf "$1" ;;
      *.tbz2) tar xjf "$1" ;;
      *.tgz) tar xzf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7z x "$1" ;;
      *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

mkcd() {
  if [ -z "${1:-}" ]; then
    err "mkcd requires a directory argument"
    return 1
  fi
  mkdir -p "$1" || { err "Failed to create directory $1"; return 1; }
  cd "$1" || { err "Failed to change directory to $1"; return 1; }
}

backup() {
  cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

findreplace() {
  if [ $# -ne 3 ]; then
    echo "Usage: findreplace <find> <replace> <file_pattern>"
    return 1
  fi
  # Escape delimiter and special regex chars in find string
  local find_escaped
  find_escaped=$(printf '%s' "$1" | sed 's/[.[\]*^$\/|]/\\&/g')
  # Escape & and \ in replacement string
  local replace_escaped
  replace_escaped=$(printf '%s' "$2" | sed 's/[&\\/]/\\&/g')
  find . -type f -name "$3" -exec sed -i "s|$find_escaped|$replace_escaped|g" {} +
}

# Renew the homepage container stack
renew_homepage() {
  local dir="$HOME/containers/homepage"

  if [[ ! -d "$dir" ]]; then
    err "renew_homepage: directory not found: $dir"
    return 1
  fi

  cd "$dir" || { err "renew_homepage: failed to change directory to $dir"; return 1; }

  info "renew_homepage: stopping containers (podman-compose down)"
  if ! podman-compose down; then
    warn "renew_homepage: podman-compose down failed"
  fi

  info "renew_homepage: fixing ownership of config/"
  if ! sudo chown -R rhlabs:rhlabs "$HOME"/containers/homepage; then
    warn "renew_homepage: sudo chown failed (you may need to run manually)"
  fi

  if [[ -d ../.git ]]; then
    info "renew_homepage: pulling latest from git (in parent directory)"
    cd ..
    if ! git pull; then
      warn "renew_homepage: git pull failed"
    fi
    cd "$dir" || return
  else
    warn "renew_homepage: no .git directory found in parent, skipping git pull"
  fi

  info "renew_homepage: starting containers (podman-compose up -d)"
  if ! podman-compose up -d; then
    err "renew_homepage: podman-compose up failed"
    return 1
  fi

  info "renew_homepage: completed"
  return 0
}

# search_config_blocks
# --------------------
# Search configuration-like files under a directory, grouping lines into blocks
# and printing only the blocks that match the requested criteria.
#
# A "block" is defined by:
#   - start_re: regular expression that marks the beginning of a block
#   - end_re:   regular expression that marks the end of a block (optional)
#
# Parameters:
#   $1 dir       : Root directory to search. Must exist.
#   $2 pattern   : Pattern to test within each block (typically a regex used
#                  inside the AWK script). How it is interpreted depends on
#                  the AWK logic inside this function.
#   $3 start_re  : Regular expression that identifies the first line of each
#                  block (e.g., '^\\[tool\\.uv\\]' or '^\\[project\\]').
#   $4 mode      : Block selection mode (optional, default: "match"):
#                    - match : print only blocks where the block content
#                              matches "pattern"
#                    - invert: print only blocks where the block content does
#                              NOT match "pattern"
#                    - all   : print every block regardless of "pattern"
#   $5 end_re    : Regular expression that marks the end of a block
#                  (optional; default '^!' which is unlikely to occur,
#                  effectively treating the file end as the block terminator).
#
# Return codes:
#   0 : Success (one or more blocks processed; whether anything was printed
#       may depend on "mode" and "pattern").
#   1 : General failure from underlying commands / AWK (if used in the body).
#   2 : Invalid arguments (missing dir, pattern, or start_re).
#   3 : Directory not found.
#   4 : Invalid mode (must be 'match', 'invert', or 'all').
#
# Usage examples:
#   # Print [tool.uv] blocks that reference "pytest" within a project:
#   #   search_config_blocks "$PROJECT_DIR" "pytest" "^\\[tool\\.uv\\]"
#   #
#   # Print all [project] blocks, regardless of content:
#   #   search_config_blocks "$PROJECT_DIR" ".*" "^\\[project\\]" "all"
#   #
#   # Print blocks starting at '# BEGIN CUSTOM' that do NOT mention 'legacy':
#   #   search_config_blocks "." "legacy" "^# BEGIN CUSTOM" "invert" "^# END CUSTOM"
search_config_blocks() {
    local dir="${1:-}"
    local pattern="${2:-}"
    local start_re="${3:-}"
    local mode="${4:-match}"   # mode: match | invert | all
    local end_re="${5:-^!}"

    # Validate required parameters
    if [[ -z "$dir" || -z "$pattern" || -z "$start_re" ]]; then
      err "Usage: search_config_blocks <dir> <pattern> <start_re> [mode] [end_re]"
      err "  mode: match (default) | invert (non-matching blocks) | all (every block)"
      return 2
    fi

    if [[ ! -d "$dir" ]]; then
      err "Directory not found: $dir"
      return 3
    fi

    if [[ ! "$mode" =~ ^(match|invert|all)$ ]]; then
      err "Invalid mode: $mode (must be match|invert|all)"
      return 4
    fi

    # Save original IFS and set to handle filenames with spaces/newlines
    local OLD_IFS="$IFS"
    IFS=$'\n\t'

    # iterate files safely (handles spaces/newlines in names)
    find "$dir" -type f -print0 | while IFS= read -r -d '' file; do
      awk -v start_re="$start_re" -v end_re="$end_re" -v pat="$pattern" -v fname="$file" -v mode="$mode" '
        BEGIN { IGNORECASE = 1; inblock = 0; block = ""; header_printed = 0; hname = fname; sub(".*/", "", hname) }
        {
          if ($0 ~ /^[[:space:]]*hostname[[:space:]]+/) {
            split($0, a, /[[:space:]]+/)
            if (a[2] != "") hname = a[2]
          }

          if (!inblock && $0 ~ start_re) {
            inblock = 1
            block = $0 "\n"
            next
          }
          if (inblock) {
            if ($0 ~ end_re) {
              matched = (tolower(block) ~ tolower(pat))
              do_print = (mode == "all") || (mode == "match" && matched) || (mode == "invert" && !matched)
              if (do_print) {
                if (!header_printed) {
                  printf("%s\n", hname)
                  header_printed = 1
                }
                n = split(block, lines, "\n")
                for (i = 1; i <= n; i++)
                  if (length(lines[i])) printf("  %s\n", lines[i])
              }
              inblock = 0
              block = ""
            } else {
              block = block $0 "\n"
            }
          }
        }
        END {
          if (inblock) {
            matched = (tolower(block) ~ tolower(pat))
            do_print = (mode == "all") || (mode == "match" && matched) || (mode == "invert" && !matched)
            if (do_print) {
              if (!header_printed) {
                printf("%s\n", hname)
                header_printed = 1
              }
              n = split(block, lines, "\n")
              for (i = 1; i <= n; i++)
                if (length(lines[i])) printf("  %s\n", lines[i])
            }
          }
        }
      ' "$file"
    done

    # restore IFS
    IFS="$OLD_IFS"
}

podman_volume_mounts() {
  # Or get detailed mount info for all containers
  for container in $(podman ps -aq); do
    echo "Container: $(podman inspect "$container" --format '{{.Name}}')"
    podman inspect "$container" | jq -r '.[0].Mounts[] | select(.Name != null) | "  \(.Name) -> \(.Destination)"'
    echo
  done
}

# List the contents of a Podman volume by name
podman_volume_ls() {
  if [ $# -lt 1 ]; then
    podman volume ls
    return 0
  fi

  local vol="$1"; shift
  local mp
  mp=$(podman volume inspect "$vol" --format '{{.Mountpoint}}' 2>/dev/null) || {
    echo "podman: volume not found: $vol" >&2
    return 3
  }

  if [ -z "$mp" ]; then
    echo "podman: mountpoint not found for volume: $vol" >&2
    return 4
  fi

  ls -la "$mp" "$@"
}
# ------------- ansible-vault secrets -------------
# Read values from an ansible-vault encrypted YAML file without writing it to disk.
# Override the file locations with VAULT_SECRETS_FILE / VAULT_PASS_FILE.
# vault_get '.some_key'   print one value (yq expression)
# vault_keys              list every key path in the file
# Tools resolve from PATH first, then the my_work_tools venv, so these work
# even when a project venv without ansible-core/yq is active.
_vault_tool() {
    local p
    p="$(command -v "$1")" || p="$HOME/my_work_tools/.venv/bin/$1"
    [[ -x "$p" ]] || { echo "vault: '$1' not found on PATH or in ~/my_work_tools/.venv/bin" >&2; return 127; }
    echo "$p"
}
_vault_query() {
    local av yq
    av="$(_vault_tool ansible-vault)" || return
    yq="$(_vault_tool yq)" || return
    "$av" view "${VAULT_SECRETS_FILE:-$HOME/.config/secrets.yml}" \
        --vault-password-file "${VAULT_PASS_FILE:-$HOME/.config/.vault_pass}" \
        | "$yq" -r "$1"
}
vault_get() { _vault_query "$1"; }
vault_keys() { _vault_query 'paths | join(".")'; }
# ------------- End of shell_functions.sh -------------
