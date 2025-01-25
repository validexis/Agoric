#!/bin/bash
cd $HOME
rm -rf agoric-upgrade-17
git clone https://github.com/Agoric/agoric-sdk.git agoric-upgrade-18
cd agoric-upgrade-18
git checkout agoric-upgrade-18

yarn install && yarn build

(cd packages/cosmic-swingset && make)

systemctl restart agoricd && journalctl -fu agoricd -o cat
