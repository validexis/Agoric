#!/bin/bash
cd $HOME
rm -rf agoric-upgrade-18
git clone https://github.com/Agoric/agoric-sdk.git agoric-upgrade-18a
cd agoric-upgrade-18a
git checkout agoric-upgrade-18a

yarn install && yarn build

(cd packages/cosmic-swingset && make)

systemctl restart agoricd && journalctl -fu agoricd -o cat
