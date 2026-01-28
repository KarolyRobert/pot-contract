import "NonFungibleToken"
import "GameNFT"
import "GameMarket"
import "GameToken"

transaction(listingID:UInt64) {

    prepare(user: auth (BorrowValue) &Account) {

        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        let vault = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Nincs collection")
        let list = user.storage.borrow<auth (GameMarket.RemoveListing)  &GameMarket.ListingCollection>(from:GameMarket.MarketStoragePath) ?? panic("List")

        

        let delisted <- list.removeListing(id: listingID)

        GameNFT.collect(loot:<- delisted,collection:collection,fabatka:nil,flow:nil)

    }


}