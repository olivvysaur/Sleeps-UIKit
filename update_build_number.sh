#!/bin/sh

#  update_build_number.sh
#  Sleeps
#
#  Created by Josh Asch on 12/05/2015.
#  Copyright (c) 2015 Bearhat. All rights reserved.
#
#  Usage: `update_build_number.sh [branch]`
#  Run this script after the 'Copy Bundle Resources' build phase
#  Ref: http://tgoode.com/2014/06/05/sensible-way-increment-bundle-version-cfbundleversion-xcode/

branch=${1:-'master'}
buildNumber=$(expr $(git rev-list $branch --count) - $(git rev-list HEAD..$branch --count))
echo "Updating build number to $buildNumber using branch '$branch'."
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist"