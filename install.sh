#!/bin/bash

INSTALL_DIR=${1:-"$HOME/.pi-deploy-tools"}

if [ ! -f "$HOME/.profile" ];then
	echo ".profile don't exists for jenkins, we touch it"
	touch $HOME/.profile
fi

if ! grep -q "$INSTALL_DIR/bin" "$HOME/.profile" ; then
	echo "INSTALLING TO $INSTALL_DIR"
	cat >> $HOME/.profile <<EOF
#Add pi deploy tools to path
if [ -d "$INSTALL_DIR" ];then
  export PATH="$INSTALL_DIR/bin:\$PATH"
fi
EOF
fi
