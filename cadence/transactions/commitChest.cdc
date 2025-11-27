import "Chest"
import "GameNFT"
import "Random"
import "NonFungibleToken"

transaction(chestID:UInt64) {
    
    prepare(user: auth (BorrowValue,SaveValue) &Account) {
        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection not public")
        let chest <- collection.withdraw(withdrawID: chestID) as! @{GameNFT.INFT}

        let receipt <- Chest.commitChest(chest: <- chest)

      //  if user.storage.type(at: Chest.ChestReceiptPath) != nil {
      //      panic("Storage collision at path=".concat(Chest.ChestReceiptPath.toString()).concat(" a Receipt is already stored!"))
      //  }

        user.storage.save(<- receipt,to:Random.ReceiptStoragePath)
    }

    // flow transactions send cadence/transactions/commitChest.cdc --args-json '[{"type":"UInt64", "value":"1"}]' --signer user1 --network emulator

}