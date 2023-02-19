<p align="center">
  <img width="240" height="auto" src="https://user-images.githubusercontent.com/118625308/219937610-98268f9d-e9f1-44d3-8e0e-9456d41ea3c3.png">
</p>

### Spesifikasi Hardware :
NODE  | CPU     | RAM      | SSD     |
| ------------- | ------------- | ------------- | -------- |
| Mainnet | 8          | 32         | 1TB  |

### Install otomatis
```
wget -O 8ball.sh https://raw.githubusercontent.com/dwentz-inc/node-mainnet/main/8ball/8ball.sh && chmod +x 8ball.sh && ./8ball.sh
```
### Load variable ke system
```
source $HOME/.bash_profile
```
### Statesync
```
systemctl stop 8ball 
8ball tendermint unsafe-reset-all --home $HOME/.8ball --keep-addr-book

STATE_SYNC_RPC="https://8ball-rpc.genznodes.dev:443"

LATEST_HEIGHT=$(curl -s $STATE_SYNC_RPC/block | jq -r .result.block.header.height)
SYNC_BLOCK_HEIGHT=$(($LATEST_HEIGHT - 1000))
SYNC_BLOCK_HASH=$(curl -s "$STATE_SYNC_RPC/block?height=$SYNC_BLOCK_HEIGHT" | jq -r .result.block_id.hash)

PEERS=fb1aa0a42ceadeafaecb6dfa07215006b21ea1c1@154.26.138.73:28656
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.8ball/config/config.toml

sed -i.bak -e "s|^enable *=.*|enable = true|" $HOME/.8ball/config/config.toml
sed -i.bak -e "s|^rpc_servers *=.*|rpc_servers = \"$STATE_SYNC_RPC,$STATE_SYNC_RPC\"|" \
  $HOME/.8ball/config/config.toml
sed -i.bak -e "s|^trust_height *=.*|trust_height = $SYNC_BLOCK_HEIGHT|" \
  $HOME/.8ball/config/config.toml
sed -i.bak -e "s|^trust_hash *=.*|trust_hash = \"$SYNC_BLOCK_HASH\"|" \
  $HOME/.8ball/config/config.toml

systemctl restart 8ball && journalctl -fu 8ball -o cat
```
### Informasi node

   * cek sync node
```
8ball status 2>&1 | jq .SyncInfo
```
   * cek log node
```
journalctl -fu 8ball -o cat
```
   * cek node info
```
8ball status 2>&1 | jq .NodeInfo
```
   * cek validator info
```
8ball status 2>&1 | jq .ValidatorInfo
```
  * cek node id
```
8ball tendermint show-node-id
```

### Membuat wallet
   * wallet baru
```
8ball keys add $WALLET
```
   * recover wallet
```
8ball keys add $WALLET --recover
```
   * list wallet
```
8ball keys list
```
   * hapus wallet
```
8ball keys delete $WALLET
```
### Simpan informasi wallet
```
8BALL_WALLET_ADDRESS=$(8ball keys show $WALLET -a)
```
```
8BALL_VALOPER_ADDRESS=$(8ball keys show $WALLET --bech val -a)
```
```
echo 'export 8BALL_WALLET_ADDRESS='${8BALL_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export 8BALL_VALOPER_ADDRESS='${8BALL_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Membuat validator
 * cek balance
```
8ball query bank balances $8BALL_WALLET_ADDRESS
```
 * membuat validator
```
8ball tx staking create-validator \
  --amount=8800000uebl \
  --pubkey=$(8ball tendermint show-validator) \
  --moniker=$NODENAME \
  --chain-id=eightball-1 \
  --identity=F57A71944DDA8C4B \
  --commission-rate="0.05" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.10" \
  --min-self-delegation="1000000" \
  --gas=auto \
  --gas-adjustment="1.15" \
  --from=$WALLET 
```
 * edit validator
```
8ball tx staking edit-validator \
  --new-moniker="nama-node" \
  --identity="F57A71944DDA8C4B" \
  --website="website" \
  --details="your_validator_description" \
  --chain-id=eightball-1 \
  --gas=auto \
  --from=$WALLET
```
 ° unjail validator
```
8ball tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=eightball-1 \
  --gas=auto \
  --gas-prices="0.025uebl" \
```
### Voting
```
8ball tx gov vote 1 yes --from $WALLET --chain-id=eightball-1 --gas=auto
```
### Delegasi dan Rewards
  * delegasi
```
8ball tx staking delegate $8BALL_VALOPER_ADDRESS  200000uebl --from=$WALLET --chain-id=eightball-1 --gas=auto
```
  * withdraw reward
```
8ball tx distribution withdraw-all-rewards --from=$WALLET --chain-id=eightball-1 --gas=auto
```
  * withdraw reward beserta komisi
```
8ball tx distribution withdraw-rewards $8BALL_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=eightball-1 --gas=auto
```

### Hapus node
```
sudo systemctl stop 8ball && \
sudo systemctl disable 8ball && \
rm /etc/systemd/system/8ball.service && \
sudo systemctl daemon-reload && \
cd $HOME && \
rm -rf 8ball && \
rm -rf 8ball.sh && \
rm -rf .8ball && \
rm -rf $(which 8ball)
```
