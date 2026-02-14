import "GameNFT"
import "GameToken"
import "Avatar"
import "Random"
import "FungibleToken"
import "NonFungibleToken"
import "GameContent"
import "Utils"

transaction(avatarID:UInt64,seconder:UInt64,options:[Int]) {
    
    prepare(user: auth (BorrowValue,SaveValue) &Account) {

        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        let vault = user.storage.borrow<auth (FungibleToken.Withdraw) &GameToken.Fabatka>(from: GameToken.VaultStoragePath) ?? panic("vault")
        let receipts = user.storage.borrow<auth (Random.Put) &Random.ReceiptStore>(from:Random.ReceiptStoragePath) ?? panic("ReceiptStore")
        let avatar <- collection.withdraw(withdrawID:avatarID) as! @{GameNFT.INFT}
        let seconder <- collection.withdraw(withdrawID:avatarID) as! @{GameNFT.INFT}
        let consts = GameContent.getConsts()
        let level = (avatar.getData()["meta"] as! {String:AnyStruct})["level"] as! Int
        let needPrice = Utils.getPrice(category: "avatar", level: level, quality: "common", Consts: consts)
        let price <- vault.withdraw(amount: needPrice) as! @GameToken.Fabatka

        let receipt <- Avatar.commitUpgrade(avatar: <- avatar, sacrifice: <- seconder, options: options, price: <- price)

        receipts.put(receipt: <- receipt)
      
    }

}

/*
 gedam:{
        class:"warrior"
    },
    baray:{
        class:"warrior"
    },
    jaki:{
        class:"mage"
    },
    kaki:{
        class:"warrior"
    },
    suki:{
        class:"archer"
    },
    fireball:{
        class:"mage"
    },
    sung:{
        class:"archer"
    },
    mind:{
        class:"mage"
    },
    fafu:{
        class:"Scholar"
    },
    fifu:{
        class:"Scholar"
    },
    fufu:{
        class:"Scholar"
    }
 */