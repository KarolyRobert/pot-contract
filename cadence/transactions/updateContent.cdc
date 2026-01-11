import "GameManager"

transaction(cVersion:[String],aVersion:[String],contents:{String:{String:AnyStruct}}) {

    // flow transactions send cadence/transactions/updateContent.cdc --args-json "[$(cat ./update/contentVersion.json),$(cat ./update/updateVersion.json),$(cat ./update/cadenceContent.json)]" --signer emulator-account --network emulator
   
    prepare(admin: auth (Storage, BorrowValue )  &Account) {
        let manager = admin.storage.borrow< auth (GameManager.Update) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")
        manager.update(contentVersion:cVersion,auditVersion:aVersion,contents:contents)
    }

    execute {}
}

 // flow transactions send cadence/transactions/updateContent.cdc --args-json "[$(cat ./update/contentVersion.json),$(cat ./update/updateVersion.json),$(cat ./update/cadenceContent.json)]" --signer roger-admin --network testnet
