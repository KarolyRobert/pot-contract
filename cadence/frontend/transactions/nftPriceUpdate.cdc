import "NonFungibleToken"
import "GameNFT"
import "GameMarket"


transaction(listingId:UInt64,offers:{String:UFix64}) {

    prepare(user: auth (BorrowValue) &Account) {
        let list = user.storage.borrow<auth (GameMarket.CreateListing)  &GameMarket.ListingCollection>(from:GameMarket.MarketStoragePath) ?? panic("List")   
        list.priceUpdate(id:listingId, offers: offers)
    }

}