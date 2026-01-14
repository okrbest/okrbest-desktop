#!/bin/sh
set -e
WORKING_DIR=`pwd`
THIS_PATH=`readlink -f $0`
cd `dirname ${THIS_PATH}`
FULL_PATH=`pwd`
cd "${WORKING_DIR}"
cat <<EOS > OKRBest.desktop
[Desktop Entry]
Name=OKR Best
Comment=OKR Best Desktop application for Linux
Exec="${FULL_PATH}/okrbest-desktop" %U
Terminal=false
Type=Application
MimeType=x-scheme-handler/okrbest;x-scheme-handler/mattermost;
Icon=${FULL_PATH}/app_icon.png
Categories=Network;InstantMessaging;
EOS
chmod +x OKRBest.desktop
