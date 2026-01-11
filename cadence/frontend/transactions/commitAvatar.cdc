import "GameNFT"
import "GameToken"
import "Avatar"
import "Random"
import "FungibleToken"
import "NonFungibleToken"
import "GameContent"
import "Utils"

transaction(avatarID:UInt64,seconderID:UInt64,options:[Int]) {
    
    prepare(user: auth (BorrowValue) &Account) {

        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        let vault = user.storage.borrow<auth (FungibleToken.Withdraw) &GameToken.Fabatka>(from: GameToken.VaultStoragePath) ?? panic("vault")
        let receipts = user.storage.borrow<auth (Random.TakePut) &Random.ReceiptStore>(from:Random.ReceiptStoragePath) ?? panic("ReceiptStore")
        let avatar <- collection.withdraw(withdrawID:avatarID) as! @{GameNFT.INFT}
        let seconder <- collection.withdraw(withdrawID:seconderID) as! @{GameNFT.INFT}
        let consts = GameContent.getConsts()
        let level = (avatar.getData()["meta"] as! {String:AnyStruct})["level"] as! Int
        let needPrice = Utils.getPrice(category: "avatar", level: level, quality: "common", Consts: consts)
        let price <- vault.withdraw(amount: needPrice) as! @GameToken.Fabatka

        let receipt <- Avatar.commitUpgrade(avatar: <- avatar, sacrifice: <- seconder, options: options, price: <- price)

        receipts.put(receipt: <- receipt)
      
    }

}