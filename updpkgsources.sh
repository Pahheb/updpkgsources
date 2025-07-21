#!/usr/bin/env bash

# Temp file to store the resulting PKGBUILD
tmpfile=$(mktemp)

# Read the PKGBUILD line by line
while IFS= read -r line; do
  # If line starts with "git+", it's a source
  if [[ "$line" =~ git\+ ]]; then
    # Capture leading indentation to restore it later
    indent=$(echo "$line" | sed -E 's/^([[:space:]]*).*/\1/')

    # Extract the full quoted URL
    url_quoted=$(echo "$line" | grep -oE "['\"][^'\"]*git\+[^'\"]*['\"]")
    # Remove quotes from the URL
    url_unquoted=$(echo "$url_quoted" | sed -E "s/^['\"]//;s/['\"]$//")

    # Strip old #commit if any
    clean_url=${url_unquoted%%#commit=*}

    # Extract actual git repo URL (remove :: prefix if any)
    repo_url="${clean_url#*git+}"

    # Fetch hash and save it in commit
    echo "Fetching commit for $repo_url" >&2
    commit=$(git ls-remote "$repo_url" HEAD | awk '{print $1}')

    # Detect original quote type
    quote_char=$(echo "$url_quoted" | cut -c1)

    # Reconstruct the line with the original quote and indentation
    new_line="${indent}${quote_char}${clean_url}#commit=${commit}${quote_char}"

    # Add line back in the place of the original
    echo "$new_line"
  else
    echo "$line"
  fi
done < PKGBUILD > "$tmpfile" # Save the result in a temp file

mv "$tmpfile" PKGBUILD # Replace old PKGBUILD with temp file
