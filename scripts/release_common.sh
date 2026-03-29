#!/usr/bin/env bash

release_root_dir() {
  cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
}

source_optional_env_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$path"
    set +a
  fi
}

load_local_release_env() {
  local root_dir="$1"
  source_optional_env_file "$root_dir/.local/release/notary.env"
  source_optional_env_file "$root_dir/.local/release/github.env"
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "ERROR: required command '$command_name' is not installed or not on PATH." >&2
    exit 1
  fi
}

require_clean_git_tree() {
  if ! git diff --quiet --ignore-submodules -- || ! git diff --cached --quiet --ignore-submodules --; then
    echo "ERROR: git working tree is not clean." >&2
    exit 1
  fi
}

resolve_github_repo() {
  if [[ -n "${SIGNALBAR_GITHUB_REPO:-}" ]]; then
    printf '%s\n' "$SIGNALBAR_GITHUB_REPO"
    return
  fi

  local remote_url
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$remote_url" ]]; then
    echo "ERROR: could not determine GitHub repository from origin remote." >&2
    exit 1
  fi

  printf '%s\n' "$remote_url" | sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##'
}
