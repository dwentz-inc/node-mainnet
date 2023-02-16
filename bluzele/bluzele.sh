#!/bin/bash

sleep 2

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
BLUZELLE_PORT=10
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export BLUZELLE_CHAIN_ID=bluzelle-8" >> $HOME/.bash_profile
echo "export BLUZELLE_PORT=${BLUZELLE_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "moniker : \e[1m\e[32m$NODENAME\e[0m"
echo -e "wallet  : \e[1m\e[32m$WALLET\e[0m"
echo -e "chain-id: \e[1m\e[32m$BLUZELLE_CHAIN_ID\e[0m"
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt list --upgradable && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y

# install go
ver="1.17" && \
cd $HOME && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
source ~/.bash_profile && \
go version

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/bluzelle/bluzelle-public
cd bluzelle-public/curium
git checkout 7bc61cc3ffe0cc90228b10a4db11f678d1db1160
go build -o curiumd cmd/curiumd/main.go
mv curiumd /root/go/bin/curiumd


# config
curiumd config chain-id $BLUZELLE_CHAIN_ID
curiumd config keyring-backend file
curiumd config node tcp://localhost:${BLUZELLE_PORT}657

# init
curiumd init $NODENAME --chain-id $BLUZELLE_CHAIN_ID

# download genesis and addrbook
curl https://bluzelle-rpc.genznodes.dev/genesis | jq -r '.result.genesis' > genesis.json
mv genesis.json .curium/config/genesis.json

# set peers and seeds
PEERS=d3150799a6be2561ed6df3e266264140a6e2514d@35.158.183.94:26656,ec45a9687a7aa8c3aeebe1d135d255c450e5ad02@13.57.179.7:26656,ecec40366517cafc9db0b638ebab28ad6344a2f4@18.143.156.117:26656
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.curium/config/config.toml

# set custom ports
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${BLUZELLE_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${BLUZELLE_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${BLUZELLE_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${BLUZELLE_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${BLUZELLE_PORT}660\"%" $HOME/.curium/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${BLUZELLE_PORT}317\"%; s%^address = \":8080\"%address = \":${BLUZELLE_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${BLUZELLE_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${BLUZELLE_PORT}091\"%" $HOME/.curium/config/app.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.curium/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.curium/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.curium/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.curium/config/app.toml

# set minimum gas price and timeout commit
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025ubnt\"/" $HOME/.curium/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.curium/config/config.toml

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/curiumd.service > /dev/null <<EOF
[Unit]
Description=curium
After=network-online.target

[Service]
User=$USER
ExecStart=$(which curiumd) start --home $HOME/.curium
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable curiumd
sudo systemctl restart curiumd

echo '=============== SETUP FINISHED ==================='
