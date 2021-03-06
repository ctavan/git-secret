#!/usr/bin/env bash


function add {
  local auto_add=0
  OPTIND=1

  while getopts "ih" opt; do
    case "$opt" in
      i) auto_add=1;;

      h) _show_manual_for "add";;
    esac
  done

  shift $((OPTIND-1))
  [ "$1" = "--" ] && shift

  _user_required

  local not_ignored=()
  local items=( "$@" )

  for item in "${items[@]}"; do
    # Checking if all files in options are ignored:
    if [[ ! -f "$item" ]]; then
      _abort "$item is not a file."
    fi

    local ignored
    ignored=$(_check_ignore "$item")
    if [[ ! "$ignored" -eq 0 ]]; then
      # Collect unignored files.
      not_ignored+=("$item")
    fi
  done

  if [[ ! "${#not_ignored[@]}" -eq 0 ]]; then
    # And show them all at once.
    local message
    message="these files are not ignored: $* ;"

    if [[ "$auto_add" -eq 0 ]]; then
      # This file is not ignored. user don't want it to be added automatically.
      # Raise the exception, since all files, which will be hidden, must be ignored.
      _abort "$message"
    else
      # In this case these files should be added to the `.gitignore` automatically:
      # see https://github.com/sobolevn/git-secret/issues/18 for more.
      echo "$message"
      echo "auto adding them to .gitignore"
      for item in "${not_ignored[@]}"; do
        _add_ignored_file "$item"
      done
    fi
  fi

  for item in "${items[@]}"; do
    # Adding files into system, skipping duplicates.
    local already_in
    already_in=$(_file_has_line "$item" "$SECRETS_DIR_PATHS_MAPPING")
    if [[ "$already_in" -eq 1 ]]; then
      echo "$item" >> "$SECRETS_DIR_PATHS_MAPPING"
    fi
  done

  echo "${#@} items added."
}
