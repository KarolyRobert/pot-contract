import "Chest"
import "GameNFT"
import "Random"
import "NonFungibleToken"

transaction(chestID:UInt64) {
    
    prepare(user: auth (BorrowValue,SaveValue) &Account) {
        
        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection not public")
        let chest <- collection.withdraw(withdrawID: chestID) as! @{GameNFT.INFT}

        let receipt <- Chest.commitChest(chest: <- chest)


        user.storage.save(<- receipt,to:Random.ReceiptStoragePath)
    }

}