import "GameNPC"


transaction() {

    
    prepare(admin: auth (BorrowValue)  &Account) {

        let manager = admin.storage.borrow<&GameNPC.ExchangeManager>(from:/storage/ExchangeManager) ?? panic("Only the owner can call this function")
        manager.initExchange()
      
    }

    execute {}
}

 // flow transactions send cadence/transactions/initExchange.cdc --signer emulator-account --network emulator
 // flow transactions send cadence/transactions/initExchange.cdc --signer roger-admin --network testnet

