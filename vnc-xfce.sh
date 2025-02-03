#!/usr/bin/env bash

sudo apt install tightvncserver tigervnc-standalone-server

if [ ! -e $HOME/.Xresources ]; then
  touch $HOME/.Xresources
fi

echo ":1=$USER" | sudo tee -a /etc/tigervnc/vncserver.users

cat << _eof_ > $HOME/.vnc/config
session=xfce
alwaysshared
localhost=no
_eof_

vncpasswd

sudo systemctl start tigervncserver@:1
sudo systemctl enable tigervncserver@:1
