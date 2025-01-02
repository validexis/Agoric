#!/bin/bash
cd $HOME
rm -rf agoric-upgrade-17
git clone https://github.com/Agoric/agoric-sdk.git agoric-upgrade-17
cd agoric-upgrade-17
git checkout agoric-upgrade-17

# Install and build Agoric Javascript packages
yarn install && yarn build

# Install and build Agoric Cosmos SDK support
(cd packages/cosmic-swingset && make)

systemctl restart agoricd && journalctl -fu agoricd -o cat
