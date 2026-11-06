#!/bin/zsh

# Formats every hand-written Dart file under mobile/.
# Usage: format.zsh          rewrite files in place
#        format.zsh --check  exit 1 if any file is not formatted (CI)

set -euo pipefail
source "${0:A:h}/script_lib.zsh"

typeset -a format_flags=()
for arg in "$@"; do
  case "$arg" in
    --check)
      format_flags+=(--set-exit-if-changed --output=none)
      ;;
    *)
      die "Unknown argument: '$arg'. Supported: --check"
      ;;
  esac
done

typeset -a dart_files=()

while IFS= read -r -d $'\0' file; do
  relative_path="${file#"$mobile_directory"/}"

  case "$relative_path" in
    */generated/* | *.g.dart | *.gen.dart | *.graphql.dart | *_generated.dart | *.freezed.dart | *.mocks.dart | */injectable.config.dart)
      continue
      ;;
  esac

  dart_files+=("$file")
done < <(
  find "$mobile_directory" \
    \( -type d \( -name .dart_tool -o -name build -o -name .github-runner \) -prune \) -o \
    \( -type f -name '*.dart' -print0 \)
)

if (( ${#dart_files[@]} == 0 )); then
  die "No non-generated Dart files found"
fi

if (( ${#format_flags[@]} > 0 )); then
  print_header "Checking formatting of ${#dart_files[@]} Dart files..."
else
  print_header "Formatting ${#dart_files[@]} Dart files..."
fi

# Run from the app directory so FVM resolves app/.fvmrc.
cd "$app_directory"
if command -v fvm >/dev/null 2>&1; then
  fvm dart format "${format_flags[@]}" "${dart_files[@]}"
else
  dart format "${format_flags[@]}" "${dart_files[@]}"
fi
