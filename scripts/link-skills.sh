#!/bin/sh
# Links the shared UNITE skills (unite-meta/skills/*) for Claude Code
# (.claude/skills) and Codex (.agents/skills).
#
# Usage:
#   sh unite-meta/scripts/link-skills.sh            # into the source workspace (parent of unite-meta)
#   sh unite-meta/scripts/link-skills.sh --user     # into ~/.claude/skills and ~/.agents/skills
#
# Workspace links work when the agent is started in the workspace root.
# User links also work when it is started inside a single repository.

set -e

meta_dir="$(cd "$(dirname "$0")/.." && pwd)"
skills_dir="$meta_dir/skills"

if [ "$1" = "--user" ]; then
  target_root="$HOME"
else
  target_root="$(dirname "$meta_dir")"
fi

for tool_dir in .claude/skills .agents/skills; do
  mkdir -p "$target_root/$tool_dir"
  for skill in "$skills_dir"/*/; do
    name="$(basename "$skill")"
    link="$target_root/$tool_dir/$name"
    if [ -e "$link" ] && [ ! -L "$link" ]; then
      echo "Skipped $link: exists and is not a link"
      continue
    fi
    ln -sfn "${skill%/}" "$link"
    echo "Linked $link -> ${skill%/}"
  done
done
