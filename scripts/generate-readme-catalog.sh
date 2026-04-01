#!/bin/bash
set -euo pipefail

# Generates the Skills and Commands catalog sections for README.md
# from SKILL.md and command frontmatter.
# Usage: ./scripts/generate-readme-catalog.sh > catalog.md
#   or:  ./scripts/generate-readme-catalog.sh --update  (updates README.md in place)

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

generate_skills() {
  echo "## Skills"
  echo ""
  echo "| Skill | Description |"
  echo "|-------|-------------|"
  for dir in "$PLUGIN_DIR"/skills/*/; do
    [ -d "$dir" ] || continue
    file="$dir/SKILL.md"
    [ -f "$file" ] || continue
    name=$(basename "$dir")
    # Extract description from frontmatter, strip quotes
    desc=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description: *"?/, ""); sub(/"$/, ""); print; exit}' "$file")
    [ -n "$desc" ] || continue
    # Truncate to first sentence
    short_desc=$(echo "$desc" | sed 's/\. .*//')
    echo "| \`$name\` | $short_desc |"
  done
}

generate_commands() {
  echo "## Commands"
  echo ""
  echo "| Command | Description |"
  echo "|---------|-------------|"
  for file in "$PLUGIN_DIR"/commands/*.md; do
    [ -f "$file" ] || continue
    name=$(awk '/^---$/{n++; next} n==1 && /^name:/{sub(/^name: */, ""); print; exit}' "$file")
    desc=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description: *"?/, ""); sub(/"$/, ""); print; exit}' "$file")
    [ -n "$name" ] && [ -n "$desc" ] || continue
    echo "| \`/$name\` | $desc |"
  done
}

if [ "${1:-}" = "--update" ]; then
  README="$PLUGIN_DIR/README.md"
  TEMP=$(mktemp)

  # Generate new catalog
  {
    generate_skills
    echo ""
    generate_commands
  } > "$TEMP"

  # Replace between markers in README
  if grep -q '<!-- BEGIN GENERATED CATALOG -->' "$README"; then
    # Use awk for reliable marker-based replacement on macOS
    awk -v catalog="$TEMP" '
      /<!-- BEGIN GENERATED CATALOG -->/ { print; while ((getline line < catalog) > 0) print line; skip=1; next }
      /<!-- END GENERATED CATALOG -->/ { skip=0 }
      !skip { print }
    ' "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"
  else
    echo "ERROR: README.md missing <!-- BEGIN GENERATED CATALOG --> markers" >&2
    rm "$TEMP"
    exit 1
  fi

  rm "$TEMP"
  echo "README.md updated." >&2
else
  generate_skills
  echo ""
  generate_commands
fi
