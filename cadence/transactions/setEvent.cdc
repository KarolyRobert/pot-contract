import "GameManager"

transaction(eventName:String) {

   
    prepare(admin: auth (Storage, BorrowValue )  &Account) {
        let manager = admin.storage.borrow< auth (GameManager.GameEvent) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")
        manager.setEvent(name: eventName)
    }

    execute {}
}

// flow transactions send cadence/transactions/setEvent.cdc "kanaan" --signer roger-admin --network testnet --compute-limit 9999
// flow transactions send cadence/transactions/setEvent.cdc "default" --signer roger-admin --network testnet --compute-limit 9999