#!/bin/bash 
# Indítod az emulátort háttérben 
flow emulator -v & 
# Vársz pár másodpercet hogy biztosan elinduljon 
sleep 2 
# Létrehozod az accountokat 
flow accounts create --key 3869d995e97bbf433063b0c64fd4359a8cff6dd00a862b5617b9ddb467387182b6f8c7e09743a52f5511e40ffd63fc3c38ac5de8758a4e8f1998de5cd67aa880 --network emulator

flow project deploy

flow transactions send cadence/transactions/updateContent.cdc --args-json "[$(cat ./update/contentVersion.json),$(cat ./update/updateVersion.json),$(cat ./update/cadenceContent.json)]" --signer emulator-account --network emulator

flow transactions send cadence/transactions/CreateCollection.cdc --signer user1 --network emulator

flow transactions send cadence/transactions/MintChest.cdc --authorizer user1,emulator-account --payer user1 --proposer emulator-account --network emulator

