
import "GameNFT"
import "Random"
import "GameToken"
import "RandomConsumer"


transaction(keys:[UInt64]) {

    prepare(user: auth(BorrowValue) &Account) {
        
        let store = user.storage.borrow<auth (Random.TakePut) &Random.ReceiptStore>(from: Random.ReceiptStoragePath) ?? panic("nincs store")
        let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Nincs collection")
        let vault = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Nincs collection")

        let receipts <- store.getReceipts(keys)

        while receipts.length > 0 {
            let receipt <- receipts.removeFirst()
            let loot <-receipt.reveal()
            GameNFT.collect(loot:<- loot,collection:collection,fabatka:vault,flow:nil)
            destroy receipt
        }
        destroy receipts
    }
}