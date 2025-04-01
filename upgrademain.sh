#!/bin/bash
cd $HOME
rm -rf agoric-upgrade-18а
git clone https://github.com/Agoric/agoric-sdk.git agoric-upgrade-19
cd agoric-upgrade-19
git checkout agoric-upgrade-19

yarn install && yarn build

(cd packages/cosmic-swingset && make)

systemctl restart agoricd && journalctl -fu agoricd -o cat
