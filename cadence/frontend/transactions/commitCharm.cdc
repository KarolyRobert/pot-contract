import "GameContent"
import "Utils"
import "GameNFT"
import "GameToken"
import "FungibleToken"
import "NonFungibleToken"
import "Charm"
import "Random"


transaction(upgradeable:UInt64,uniq:UInt64,needs:[UInt64]) {

    prepare(user: auth (BorrowValue) &Account) {

        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        let vault = user.storage.borrow<auth (FungibleToken.Withdraw) &GameToken.Fabatka>(from: GameToken.VaultStoragePath) ?? panic("vault")
        let receipts = user.storage.borrow<auth (Random.TakePut) &Random.ReceiptStore>(from:Random.ReceiptStoragePath) ?? panic("ReceiptStore")

        let charm <- collection.withdraw(withdrawID:upgradeable) as! @GameNFT.MetaNFT
        
      
        let consts = GameContent.getConsts()

        let meta = charm.getMeta()
     
        let needPrice = Utils.getUpgradePrice(category:charm.category,meta:meta, Consts: consts)

        let price <- vault.withdraw(amount: needPrice) as! @GameToken.Fabatka

        let resources:@[{GameNFT.INFT}] <- []
        var tharion:@{GameNFT.INFT}? <- nil
        while needs.length > 0 {
            let need = needs.removeFirst()
            let needNft <- collection.withdraw(withdrawID:need) as! @{GameNFT.INFT}        
            resources.append(<- needNft)
        }
        if uniq > 0 {
            tharion <-! collection.withdraw(withdrawID:uniq) as! @{GameNFT.INFT}   
        }
        
        let receipt <- Charm.commitUpgrade(charm: <- charm,needs: <- resources,tharion: <- tharion,price:<-price)

        receipts.put(receipt: <- receipt)
    }

}