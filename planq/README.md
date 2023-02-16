<p align="center">
  <img width="240" height="auto" src="https://user-images.githubusercontent.com/108969749/208448900-1cd072da-d0cd-4d3b-b24c-11ae9db0ac76.png">
</p>

### Spesifikasi Hardware :
NODE  | CPU     | RAM      | SSD     |
| ------------- | ------------- | ------------- | -------- |
| Mainnet | 8          | 32         | 1TB  |

### Install otomatis
```
wget -O planq.sh https://raw.githubusercontent.com/dwentz-inc/node-mainnet/main/planq/planq.sh && chmod +x planq.sh && ./planq.sh
```
### Load variable ke system
```
source $HOME/.bash_profile
```
### Statesync by nodeist
```
systemctl stop planqd
planqd tendermint unsafe-reset-all --home $HOME/.planqd --keep-addr-book
SNAP_RPC="https://rpc-planq.nodeist.net:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.planqd/config/config.toml
```
```
systemctl restart planqd && sudo journalctl -u planqd -f --no-hostname -o cat
```
### Informasi node

   * cek sync node
```
planqd status 2>&1 | jq .SyncInfo
```
   * cek log node
```
journalctl -fu planqd -o cat
```
   * cek node info
```
planqd status 2>&1 | jq .NodeInfo
```
   * cek validator info
```
planqd status 2>&1 | jq .ValidatorInfo
```
  * cek node id
```
planqd tendermint show-node-id
```

### Membuat wallet
   * wallet baru
```
planqd keys add $WALLET
```
   * recover wallet
```
planqd keys add $WALLET --recover
```
   * list wallet
```
planqd keys list
```
   * hapus wallet
```
planqd keys delete $WALLET
```
### Simpan informasi wallet
```
PLANQ_WALLET_ADDRESS=$(planqd keys show $WALLET -a)
```
```
PLANQ_VALOPER_ADDRESS=$(planqd keys show $WALLET --bech val -a)
```
```
echo 'export PLANQ_WALLET_ADDRESS='${PLANQ_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export PLANQ_VALOPER_ADDRESS='${PLANQ_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Membuat validator
 * cek balance
```
planqd query bank balances $PLANQ_WALLET_ADDRESS
```
 * membuat validator
```
planqd tx staking create-validator \
  --amount=1000000000000aplanq \
  --pubkey=$(planqd tendermint show-validator) \
  --moniker=$NODENAME \
  --chain-id=planq_7070-2 \
  --commission-rate="0.05" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.10" \
  --min-self-delegation="1000000" \
  --gas="1000000" \
  --gas-prices="30000000000aplanq" \
  --gas-adjustment="1.15" \
  --from=$WALLET 
```
 * edit validator
```
planqd tx staking edit-validator \
  --new-moniker="nama-node" \
  --identity="keybase_id" \
  --website="website" \
  --details="your_validator_description" \
  --chain-id=planq_7070-2 \
  --gas="1000000" \
  --gas-prices="30000000000aplanq" \
  --from=$WALLET
```
 ° unjail validator
```
planqd tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=planq_7070-2 \
  --gas="1000000" \
  --gas-prices="30000000000aplanq" \
```
### Voting
```
planqd tx gov vote 1 yes --from $WALLET --chain-id=planq_7070-2 --gas=1000000 --gas-prices=30000000000aplanq
```
### Delegasi dan Rewards
  * delegasi
```
planqd tx staking delegate $PLANQ_VALOPER_ADDRESS  200000000000000000000aplanq --from=$WALLET --chain-id=planq_7070-2 --gas=1000000 --gas-prices=30000000000aplanq
```
  * withdraw reward
```
planqd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=planq_7070-2 --gas=1000000 --gas-prices=30000000000aplanq
```
  * withdraw reward beserta komisi
```
planqd tx distribution withdraw-rewards $PLANQ_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=planq_7070-2 --gas=1000000 --gas-prices=30000000000aplanq
```

### Hapus node
```
sudo systemctl stop planqd && \
sudo systemctl disable planqd && \
rm /etc/systemd/system/planqd.service && \
sudo systemctl daemon-reload && \
cd $HOME && \
rm -rf planq && \
rm -rf planq.sh && \
rm -rf .planqd && \
rm -rf $(which planqd)
```
