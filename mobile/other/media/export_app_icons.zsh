#!/bin/zsh

# cSpell: ignore artboards
# set -x
set -e
source "${0:A:h:h:h}/scripts/script_lib.zsh"

SRC_FILE="${0:A:h}/rick_morty_app.sketch"
ASSETS_ROOT="${0:A:h:h:h}/app/assets"

ASSET_NAMES=(
  app_icon_ios
  app_icon_ios_dark
  app_icon_ios_tinted
  app_icon_android_legacy
  app_icon_android_mono
  app_icon_android_adaptive
)

FLAVORS=(prod stage dev)

for flavor in $FLAVORS; do
  print_header "Exporting <$flavor> flavor..."
 
  ITEMS=$(printf "%s," ${ASSET_NAMES/%/_${flavor}})
  ITEMS=${ITEMS%,}  # Remove trailing comma

  sketch_tool export artboards "$SRC_FILE" --output="$ASSETS_ROOT/app_icons/$flavor" --items=$ITEMS
done

print_bold "\nDone. Do not forget to run task <Build App Icons>"

