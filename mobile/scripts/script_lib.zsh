# cSpell: ignore mdfind bohemiancoding sketchtool

set -euo pipefail

die() {  
    print -P -- "%B%F{red}\n$1%f%b" >&2
    exit 1
}

typeset -r system_name=$(uname)
# Resolve from this file (works when sourced from other scripts).
typeset -r _script_lib_path="${(%):-%x}"
typeset -r scripts_directory="${_script_lib_path:A:h}"
typeset -r mobile_directory="${scripts_directory:h}"
typeset -r repo_directory="${mobile_directory:h}"
typeset -r app_directory="${mobile_directory}/app"

# just to check if the scripts directory is correct
if [[ "${scripts_directory:t}" != "scripts" ]]; then
    die "Something wrong with paths: expected 'scripts' directory (found '${scripts_directory:t}')"
fi
if [[ ! -d "$app_directory" ]]; then
    die "Something wrong with paths: app directory not found at '$app_directory'"
fi

print_bold() { 
    print -P -- "%B$1%b"
}

print_header() {
    print -P -- "%B%F{green}\n$1%f%b"
}

make_path() {
    # Joins all non-empty arguments with "/" as separator
    local parts=()
    for arg in "$@"; do
        [[ -n "$arg" ]] && parts+=("$arg")
    done
    print -- "${(j:/:)parts}"
}

print_var() {
    local var_name="$1"
    local var_value="${(P)var_name}"
    print_bold "$var_name: $var_value"
}

# Parse CLI args in --name=value form into associative array ARGS
typeset -A ARGS

_print_usage() {    
    if ! typeset -f print_usage >/dev/null; then
        die "print_usage() function is not defined"
    fi
    print_usage
    exit 1
}

parse_args() {
    for arg in "$@"; do
        if [[ "$arg" == --*=* ]]; then
            key="${arg%%=*}"
            key="${key#--}"
            value="${arg#*=}"
            ARGS[$key]="$value"
        else
            die "Invalid argument format: '$arg'. Expected --name=value"
        fi
    done

    if [[ ${#ARGS[@]} -eq 0 ]]; then
        _print_usage
    fi
}

# Example: access with ${ARGS[name]}
# If you want to require certain args, check for their presence:
# [[ -z "${ARGS[project_name]:-}" ]] && die "Missing required argument: --project_name"

load_required_arg() {
    local var_name=$1
    if [[ -z ${ARGS[$var_name]-} ]]; then
        die "The required parameter <$var_name> is not defined or is empty"
    fi
    local var_value="${ARGS[$var_name]:-}"
    if [[ $# -eq 2 ]]; then
        typeset -g "${2}=${var_value}"
        var_name=$2
    else
        typeset -g "${1}=${var_value}"
    fi
    # print_bold "$var_name: $var_value"
    print_var "$var_name"
}

patch_file() {
    local file="$1"
    local old_string="$2"
    local new_string="$3"
    
    if [[ "$system_name" == "Darwin" ]]; then
        sed -i '' -e "s/$old_string/$new_string/g" "$file" || die "sed failed for $file"
    elif [[ "$system_name" == "Linux" ]]; then
        sed -i -e "s/$old_string/$new_string/g" "$file" || die "sed failed for $file"
    else
        echo "Unsupported operating system $system_name"
    fi   
}

sketch_tool() {
    if [[ -z "${_SKETCH_TOOL:-}" ]]; then
        _SKETCH_TOOL="$(mdfind kMDItemCFBundleIdentifier=='com.bohemiancoding.sketch3' | head -n 1)/Contents/MacOS/sketchtool"
    fi
    "$_SKETCH_TOOL" "$@"
}

generate_password() {
    python3 <<EOF
import secrets, string; 
print("".join(secrets.choice(string.ascii_letters + string.digits + "%^&*") for _ in range(20)))
EOF
}

create_destination_directory() {
    local output_directory="$1"
    if [[ -d $output_directory ]]; then
        # Allow .DS_Store  to be present in the output directory
        if find "$output_directory" -mindepth 1 -maxdepth 1 ! -name '.DS_Store' -print -quit | grep -q .; then
            die "The destination directory <$output_directory> already exists and it is not empty"
        fi
    fi

    mkdir -p "$output_directory" || die "Failed to create destination directory"
}

ensure_file_does_not_exist() {
    local file_path="$1"
    if [[ -e $file_path ]]; then
        die "The file <$file_path> already exists"
    fi
}