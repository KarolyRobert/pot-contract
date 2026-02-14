import "Chest"
import "GameNFT"
import "Random"
import "NonFungibleToken"

transaction(chestIDs:[UInt64]) {
    
    prepare(user: auth (BorrowValue) &Account) {

        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        let receipts = user.storage.borrow<auth (Random.Put) &Random.ReceiptStore>(from:Random.ReceiptStoragePath) ?? panic("ReceiptStore")

        while chestIDs.length > 0 {
            let chestID = chestIDs.removeFirst()
            let chest <- collection.withdraw(withdrawID: chestID) as! @{GameNFT.INFT}
            let receipt <- Chest.commitChest(chest: <- chest)
            receipts.put(receipt: <- receipt)
        }
       
    }

}