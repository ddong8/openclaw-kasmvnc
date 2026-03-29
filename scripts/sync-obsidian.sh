#!/usr/bin/env bash
# Sync repo docs to Obsidian vault after git pull / release
# Usage: ./scripts/sync-obsidian.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OBSIDIAN_DIR="$HOME/Documents/Obsidian/HaixingVault/Claude Code/openclaw-kasmvnc"

mkdir -p "$OBSIDIAN_DIR"

# Convert GitHub markdown links to Obsidian wikilinks
# e.g. [README-zh.md](README-zh.md) → [[README-zh]]
# e.g. [DOCKER-en.md](DOCKER-en.md) → [[Docker Image Guide (EN)]]
convert_links() {
  sed \
    -e 's|\[README-zh\.md\](README-zh\.md)|[[README-zh]]|g' \
    -e 's|\[README\.md\](README\.md)|[[README]]|g' \
    -e 's|\[DOCKER\.md\](DOCKER\.md)|[[Docker 镜像使用指南]]|g' \
    -e 's|\[DOCKER-en\.md\](DOCKER-en\.md)|[[Docker Image Guide (EN)]]|g'
}

# Strip GitHub-specific elements (image badges, star history, etc.)
strip_github() {
  sed \
    -e '/^\[!\[Star History/,/^$/d' \
    -e '/^!\[OpenClaw/d' \
    -e 's|!\[OpenClaw [^]]*\]([^)]*)| |g'
}

echo "Syncing docs to Obsidian: $OBSIDIAN_DIR"

# README.md (EN)
< "$REPO_ROOT/README.md" convert_links | strip_github > "$OBSIDIAN_DIR/README.md"

# README-zh.md
< "$REPO_ROOT/README-zh.md" convert_links | strip_github > "$OBSIDIAN_DIR/README-zh.md"

# DOCKER.md → Docker 镜像使用指南.md
cp "$REPO_ROOT/DOCKER.md" "$OBSIDIAN_DIR/Docker 镜像使用指南.md"

# DOCKER-en.md → Docker Image Guide (EN).md
cp "$REPO_ROOT/DOCKER-en.md" "$OBSIDIAN_DIR/Docker Image Guide (EN).md"

# CLAUDE.md → 架构设计.md (中文) + Architecture.md (EN)
# These are manually curated, only overwrite if repo CLAUDE.md is newer
for f in "架构设计.md" "Architecture.md"; do
  target="$OBSIDIAN_DIR/$f"
  if [ ! -f "$target" ] || [ "$REPO_ROOT/CLAUDE.md" -nt "$target" ]; then
    # Keep existing curated content — only touch the timestamp
    touch "$target"
    echo "  [skip] $f (curated, touch only)"
  else
    echo "  [skip] $f (up to date)"
  fi
done

echo "Done. Synced 4 docs to Obsidian."
