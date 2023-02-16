<p align="center">
  <img width="240" height="auto" src="https://user-images.githubusercontent.com/118625308/218544655-cbc41b23-3e9f-4123-9529-21bed8ec7c3c.png">
</p>

### Spesifikasi Hardware :
NODE  | CPU     | RAM      | SSD     |
| ------------- | ------------- | ------------- | -------- |
| Mainnet | 8          | 32         | 1TB  |

### Install otomatis
```
wget -O bluzele.sh https://raw.githubusercontent.com/dwentz-inc/node-mainnet/main/bluzele/bluzele.sh && chmod +x bluzele.sh && ./bluzele.sh
```
### Load variable ke system
```
source $HOME/.bash_profile
```
### Statesync
```
N/A
```
### Informasi node

   * cek sync node
```
curiumd status 2>&1 | jq .SyncInfo
```
   * cek log node
```
journalctl -fu curiumd -o cat
```
   * cek node info
```
curiumd status 2>&1 | jq .NodeInfo
```
   * cek validator info
```
curiumd status 2>&1 | jq .ValidatorInfo
```
  * cek node id
```
curiumd tendermint show-node-id
```

### Membuat wallet
   * wallet baru
```
curiumd keys add $WALLET
```
   * recover wallet
```
curiumd keys add $WALLET --recover
```
   * list wallet
```
curiumd keys list
```
   * hapus wallet
```
curiumd keys delete $WALLET
```
### Simpan informasi wallet
```
BLUZELE_WALLET_ADDRESS=$(curiumd keys show $WALLET -a)
```
```
BLUZELE_VALOPER_ADDRESS=$(curiumd keys show $WALLET --bech val -a)
```
```
echo 'export BLUZELE_WALLET_ADDRESS='${BLUZELE_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export BLUZELE_VALOPER_ADDRESS='${BLUZELE_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Membuat validator
 * cek balance
```
curiumd query bank balances $BLUZELE_WALLET_ADDRESS
```
 * membuat validator
```
curiumd tx staking create-validator \
  --amount=1000000000000ubnt \
  --pubkey=$(curiumd tendermint show-validator) \
  --moniker=$NODENAME \
  --chain-id=bluzelle-8 \
  --commission-rate="0.05" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.10" \
  --min-self-delegation="1000000" \
  --gas=auto \
  --gas-prices="0.025ubnt" \
  --gas-adjustment="1.15" \
  --from=$WALLET 
```
 * edit validator
```
curiumd tx staking edit-validator \
  --new-moniker="nama-node" \
  --identity="keybase_id" \
  --website="website" \
  --details="your_validator_description" \
  --chain-id=bluzelle-8 \
  --gas=auto \
  --gas-prices="0.025ubnt" \
  --from=$WALLET
```
 ° unjail validator
```
curiumd tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=bluzelle-8 \
  --gas=auto \
  --gas-prices="0.025ubnt" \
```
### Voting
```
curiumd tx gov vote 1 yes --from $WALLET --chain-id=bluzelle-8 --gas=auto --gas-prices=0.025ubnt
```
### Delegasi dan Rewards
  * delegasi
```
curiumd tx staking delegate $BLUZELE_VALOPER_ADDRESS  200000000000000000000ubnt --from=$WALLET --chain-id=bluzelle-8 --gas=auto --gas-prices=0.025ubnt
```
  * withdraw reward
```
curiumd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=bluzelle-8 --gas=auto --gas-prices=0.025ubnt
```
  * withdraw reward beserta komisi
```
curiumd tx distribution withdraw-rewards $BLUZELE_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=bluzelle-8 --gas=auto --gas-prices=0.025ubnt
```

### Hapus node
```
sudo systemctl stop curiumd && \
sudo systemctl disable curiumd && \
rm /etc/systemd/system/curiumd.service && \
sudo systemctl daemon-reload && \
cd $HOME && \
rm -rf bluzelle-public && \
rm -rf bluzele.sh && \
rm -rf .curium && \
rm -rf $(which curiumd)
```
