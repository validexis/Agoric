#!/bin/bash
sudo apt -q update 
sudo apt -qy install curl git jq lz4 build-essential 
sudo apt -qy upgrade

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt update
sudo apt remove -y nodejs
sudo apt autoremove -y

sudo apt install -y nodejs=18.* yarn

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:/usr/local/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -rf agoric-upgrade-17
git clone https://github.com/Agoric/agoric-sdk.git agoric-upgrade-18
cd agoric-upgrade-18
git checkout agoric-upgrade-18

yarn install && yarn build
(cd packages/cosmic-swingset && make)

agd config chain-id agoric-3
agd config keyring-backend file
agd config node tcp://localhost:26657

agd init Node --chain-id agoric-3

curl -Ls https://snapshots.kjnodes.com/agoric/genesis.json > $HOME/.agoric/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/agoric/addrbook.json > $HOME/.agoric/config/addrbook.json

sed -i -e "s|^seeds *=.*|seeds = \"400f3d9e30b69e78a7fb891f60d76fa3c73f0ecc@agoric.rpc.kjnodes.com:12759\"|" $HOME/.agoric/config/config.toml
​
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.025ubld\"|" $HOME/.agoric/config/app.toml
​
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
 $HOME/.agoric/config/app.toml

CUSTOM_PORT=166

sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CUSTOM_PORT}58\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${CUSTOM_PORT}57\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CUSTOM_PORT}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CUSTOM_PORT}56\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CUSTOM_PORT}66\"%" $HOME/.agoric/config/config.toml
sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${CUSTOM_PORT}17\"%; s%^address = \":8080\"%address = \":${CUSTOM_PORT}80\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${CUSTOM_PORT}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${CUSTOM_PORT}91\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CUSTOM_PORT}45\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CUSTOM_PORT}46\"%" $HOME/.agoric/config/app.toml

agd config node tcp://localhost:${CUSTOM_PORT}57

sudo tee /etc/systemd/system/agoricd.service > /dev/null << EOF
[Unit]
Description=Agoric node service
After=network-online.target

[Service]
Type=simple
User=${USER}
ExecStart=$(which agd) start --home ${HOME}/.agoric
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

curl -L https://snapshots.kjnodes.com/agoric/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.agoric

sudo systemctl daemon-reload
sudo systemctl enable agoricd
sudo systemctl start agoricd && sudo journalctl -u agoricd -f -o cat
