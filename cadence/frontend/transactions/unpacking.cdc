import "NonFungibleToken"
import "GameNFT"

transaction(packID:UInt64) {

    prepare(user: auth (BorrowValue) &Account) {

        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        collection.unpack(packID: packID)

    }


}