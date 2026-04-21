#!/usr/bin/env bash
# Architecture check baseline v1.
# This rule set is frozen for the current architecture stage.
# Do not expand rules here without an explicit architecture change review.

set -euo pipefail

declare -A MODULE_DIRS
declare -A GROUP_SEEN

resolve_module_dir() {
  local module_name="$1"
  local direct_path="$module_name"
  local sources_path="Core/Sources/$module_name"

  if [[ -d "$direct_path" ]]; then
    echo "$direct_path"
    return 0
  fi

  if [[ -d "$sources_path" ]]; then
    echo "$sources_path"
    return 0
  fi

  return 1
}

require_module_dir() {
  local module_name="$1"
  local module_dir

  if ! module_dir="$(resolve_module_dir "$module_name")"; then
    echo "ERROR: $module_name directory not found"
    exit 1
  fi

  echo "$module_dir"
}

print_group_header_once() {
  local group_title="$1"

  if [[ -z "${GROUP_SEEN[$group_title]:-}" ]]; then
    echo "== $group_title =="
    GROUP_SEEN["$group_title"]=1
  fi
}

report_violation() {
  local group_title="$1"
  local matches="$2"
  local rule_message="$3"
  local fix_message="$4"

  print_group_header_once "$group_title"
  echo "$matches"
  echo "ERROR: $rule_message"
  echo "Fix: $fix_message"
  exit 1
}

check_rule() {
  local group_title="$1"
  local module_name="$2"
  local forbidden_import="$3"
  local fix_message="$4"
  local module_dir="${MODULE_DIRS[$module_name]}"
  local matches

  print_group_header_once "$group_title"

  matches="$(
    grep -R -n -E "^[[:space:]]*import[[:space:]]+$forbidden_import([[:space:]]|$)" "$module_dir" || true
  )"

  if [[ -n "$matches" ]]; then
    report_violation \
      "$group_title" \
      "$matches" \
      "$module_name must not import $forbidden_import" \
      "$fix_message"
  fi
}

MODULE_NAMES=(
  "ReaderCoreFoundation"
  "ReaderCoreModels"
  "ReaderCoreProtocols"
  "ReaderCoreParser"
  "ReaderCoreJSRenderer"
  "ReaderPlatformAdapters"
  "ReaderCoreNetwork"
  "ReaderCoreCache"
)

RULES=(
  "Foundation Boundary Rules|ReaderCoreFoundation|ReaderCoreParser|remove upward dependency and keep foundation isolated from parser"
  "Foundation Boundary Rules|ReaderCoreFoundation|ReaderCoreNetwork|remove upward dependency and keep foundation isolated from network"
  "Foundation Boundary Rules|ReaderCoreFoundation|ReaderCoreCache|remove upward dependency and keep foundation isolated from cache"
  "Foundation Boundary Rules|ReaderCoreFoundation|ReaderCoreJSRenderer|remove upward dependency and keep foundation isolated from JS rendering"
  "Foundation Boundary Rules|ReaderCoreFoundation|ReaderPlatformAdapters|remove upward dependency and keep foundation isolated from platform adapters"
  "Models Boundary Rules|ReaderCoreModels|ReaderCoreParser|remove upward dependency and keep models independent of parser"
  "Models Boundary Rules|ReaderCoreModels|ReaderCoreNetwork|remove upward dependency and keep models independent of network"
  "Models Boundary Rules|ReaderCoreModels|ReaderCoreCache|remove upward dependency and keep models independent of cache"
  "Models Boundary Rules|ReaderCoreModels|ReaderCoreJSRenderer|remove upward dependency and keep models independent of JS rendering"
  "Protocols Boundary Rules|ReaderCoreProtocols|ReaderCoreParser|remove upward dependency and keep protocols independent of parser"
  "Protocols Boundary Rules|ReaderCoreProtocols|ReaderCoreNetwork|remove upward dependency and keep protocols independent of network"
  "Protocols Boundary Rules|ReaderCoreProtocols|ReaderCoreCache|remove upward dependency and keep protocols independent of cache"
  "Protocols Boundary Rules|ReaderCoreProtocols|ReaderCoreJSRenderer|remove upward dependency and keep protocols independent of JS rendering"
  "Parser Boundary Rules|ReaderCoreParser|ReaderCoreJSRenderer|remove direct dependency and keep JS rendering behind the renderer boundary"
  "Parser Boundary Rules|ReaderCoreParser|ReaderCoreNetwork|remove cross-layer dependency and keep parser isolated from network"
  "Parser Boundary Rules|ReaderCoreParser|ReaderCoreCache|remove cross-layer dependency and keep parser isolated from cache"
  "Platform Adapter Boundary Rules|ReaderPlatformAdapters|ReaderCoreParser|remove direct dependency and access through Protocol layer"
  "Platform Adapter Boundary Rules|ReaderPlatformAdapters|ReaderCoreNetwork|remove direct dependency and access through Protocol layer"
  "Platform Adapter Boundary Rules|ReaderPlatformAdapters|ReaderCoreCache|remove direct dependency and access through Protocol layer"
  "Network Boundary Rules|ReaderCoreNetwork|ReaderCoreParser|remove parsing dependency and keep network logic independent of parser"
  "Cache Boundary Rules|ReaderCoreCache|ReaderCoreParser|remove parsing dependency and keep cache logic independent of parser"
)

for module_name in "${MODULE_NAMES[@]}"; do
  MODULE_DIRS["$module_name"]="$(require_module_dir "$module_name")"
done

for rule in "${RULES[@]}"; do
  IFS='|' read -r group_title module_name forbidden_import fix_message <<< "$rule"
  check_rule "$group_title" "$module_name" "$forbidden_import" "$fix_message"
done

echo "Checked ${#RULES[@]} rules across ${#MODULE_NAMES[@]} directories"
echo "Architecture check passed"
