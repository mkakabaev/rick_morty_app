#!/bin/zsh

set -euo pipefail
source "${0:A:h}/script_lib.zsh"

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

print_header "Formatting ${#dart_files[@]} Dart files..."

# Run from the app directory so FVM resolves app/.fvmrc.
cd "$app_directory"
if command -v fvm >/dev/null 2>&1; then
  fvm dart format "${dart_files[@]}"
else
  dart format "${dart_files[@]}"
fi
