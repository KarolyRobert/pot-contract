import "Chest"
import "GameNFT"
import "Random"
import "GameToken"


transaction() {
    prepare(signer: auth(BorrowValue, LoadValue) &Account) {
    
        let receipt <- signer.storage.load<@Chest.Receipt>(from:Random.ReceiptStoragePath) ?? panic("No Receipt found in storage at path=".concat(Random.ReceiptStoragePath.toString()))
        let loot <- Chest.reveilChest(receipt: <-receipt)

        let collection = signer.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Nincs collection")
        let vault = signer.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Nincs collection")

        while loot.length > 0 {
            let res <- loot.removeFirst()
            if let base <- res as? @GameNFT.BaseNFT{
                collection.deposit(token: <- base)
            }else if let meta <- res as? @GameNFT.MetaNFT{
                collection.deposit(token: <- meta)
            }else if let token <- res as? @GameToken.Fabatka {
                vault.deposit(from:<-token)
            }else{
                destroy res
            }
        }
        destroy loot
    }
}