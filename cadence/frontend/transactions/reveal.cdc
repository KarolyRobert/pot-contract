
import "GameNFT"
import "Random"
import "GameToken"
import "RandomConsumer"


transaction(keys:[UInt64]) {

    prepare(user: auth(BorrowValue) &Account) {
        
        let store = user.storage.borrow<auth (Random.Reveal) &Random.ReceiptStore>(from: Random.ReceiptStoragePath) ?? panic("nincs store")
        let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Nincs collection")
        let vault = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Nincs collection")

        while keys.length > 0 {
            let id = keys.removeFirst()
            let loot <- store.reveal(id)
            GameNFT.collect(loot:<- loot,collection:collection,fabatka:vault,flow:nil)
        }
    }
}