#!/bin/zsh

set -euo pipefail
source "${0:A:h}/script_lib.zsh"

typeset -a pubspec_dirs=()
while IFS= read -r -d $'\0' pubspec; do
    pubspec_dirs+=("${pubspec:h}")
done < <(
    find "$mobile_directory" \
        \( -type d \( -name .dart_tool -o -name build \) -prune \) -o \
        \( -type f -name pubspec.yaml -print0 \) \
        | sort -z
)

if (( ${#pubspec_dirs[@]} == 0 )); then
    die "No pubspec.yaml files found under $mobile_directory"
fi

typeset -a dart_cmd flutter_cmd
if command -v fvm >/dev/null 2>&1; then
    dart_cmd=(fvm dart)
    flutter_cmd=(fvm flutter)
else
    dart_cmd=(dart)
    flutter_cmd=(flutter)
fi

# Run from the app directory so FVM resolves app/.fvmrc.
cd "$app_directory"

print_header "Running pub get in ${#pubspec_dirs[@]} packages..."

for dir in "${pubspec_dirs[@]}"; do
    relative_path="${dir#"$mobile_directory"/}"
    print_header "$relative_path"

    if grep -qE '^[[:space:]]*sdk:[[:space:]]*flutter[[:space:]]*$' "$dir/pubspec.yaml"; then
        "${flutter_cmd[@]}" pub get -C "$dir"
    else
        "${dart_cmd[@]}" pub get -C "$dir"
    fi
done

print_header "Done"
