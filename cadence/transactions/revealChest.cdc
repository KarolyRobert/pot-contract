import "Chest"
import "GameNFT"
import "Random"
import "NonFungibleToken"
import "Burner"
import "FungibleToken"
import "GameToken"


transaction() {
    prepare(signer: auth(BorrowValue, LoadValue) &Account) {
        // Load my receipt from storage
        let receipt <- signer.storage.load<@Chest.Receipt>(from:Random.ReceiptStoragePath) ?? panic("No Receipt found in storage at path=".concat(Random.ReceiptStoragePath.toString()))
        let loot <- Chest.reveilChest(receipt: <-receipt)

        let collection = signer.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Nincs collection")
        let vault = signer.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Nincs collection")

        while loot.length > 0 {
            let res <- loot.removeFirst()
            if let base <- res as? @GameNFT.BaseNFT{
                log(base.getData())
                collection.deposit(token: <- base)
                //Burner.burn(<-nft)
            }else if let meta <- res as? @GameNFT.MetaNFT{
                log(meta.getData())
                collection.deposit(token: <- meta)
                // Burner.burn(<-nft)
            }else if let token <- res as? @GameToken.Fabatka {
                log(token.balance)
                vault.deposit(from:<-token)
                //Burner.burn(<-token)
            }else{

            destroy res
            }
          //  let metaNFT <- nft as! @GameNFT.MetaNFT
           // let metaValue = metaNFT.meta
           
          //  log(nft.type)
          //  log(nft.category)
            //log(metaValue)
           
        }
        destroy loot
    }
    // flow transactions send cadence/transactions/revealChest.cdc --signer user1 --network emulator
}