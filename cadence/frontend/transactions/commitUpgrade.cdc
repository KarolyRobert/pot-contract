import "GameContent"
import "Utils"
import "GameNFT"
import "GameToken"
import "FungibleToken"
import "NonFungibleToken"
import "Upgrade"
import "Random"


transaction(upgradeable:UInt64,uniq:UInt64,needs:[UInt64]) {

    prepare(user: auth (BorrowValue) &Account) {

        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        let vault = user.storage.borrow<auth (FungibleToken.Withdraw) &GameToken.Fabatka>(from: GameToken.VaultStoragePath) ?? panic("vault")
        let receipts = user.storage.borrow<auth (Random.Put) &Random.ReceiptStore>(from:Random.ReceiptStoragePath) ?? panic("ReceiptStore")

        let item <- collection.withdraw(withdrawID:upgradeable) as! @GameNFT.MetaNFT
        
      
        let consts = GameContent.getConsts()

        let meta = item.getMeta()
     
        let needPrice = Utils.getUpgradePrice(category:item.category,meta:meta, Consts: consts)

        let price <- vault.withdraw(amount: needPrice) as! @GameToken.Fabatka

        let resources:@[{GameNFT.INFT}] <- []
        var uniqNft:@{GameNFT.INFT}? <- nil
        while needs.length > 0 {
            let need = needs.removeFirst()
            let needNft <- collection.withdraw(withdrawID:need) as! @{GameNFT.INFT}        
            resources.append(<- needNft)
        }
        if uniq > 0 {
            uniqNft <-! collection.withdraw(withdrawID:uniq) as! @{GameNFT.INFT}   
        }
        
        let receipt <- Upgrade.commitUpgrade(unit: <- item,needs: <- resources,uniq: <- uniqNft,price:<-price)

        receipts.put(receipt: <- receipt)
    }

}