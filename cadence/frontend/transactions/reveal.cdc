
import "GameNFT"
import "Random"
import "GameToken"
import "RandomConsumer"


transaction(keys:[UInt64]) {

    prepare(user: auth(BorrowValue) &Account) {
        
        let store = user.storage.borrow<auth (Random.TakePut) &Random.ReceiptStore>(from: Random.ReceiptStoragePath) ?? panic("nincs store")
        let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Nincs collection")
        let vault = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Nincs collection")


        fun collect(_ loot:@[AnyResource]){
            while loot.length > 0 {
                let res <- loot.removeFirst()
                if let base <- res as? @GameNFT.BaseNFT{
                    collection.deposit(token: <- base)
                }else if let meta <- res as? @GameNFT.MetaNFT{
                    collection.deposit(token: <- meta)
                }else if let token <- res as? @GameToken.Fabatka {
                    vault.deposit(from:<-token)
                }else{
                    panic("Unexpected result!")
                }
            }
            destroy loot
        }

        let receipts <- store.getReceipts(keys)

        while receipts.length > 0 {
            let receipt <- receipts.removeFirst()
            let loot <-receipt.reveal()
            collect(<- loot)
            destroy receipt
        }
        destroy receipts
    }
}