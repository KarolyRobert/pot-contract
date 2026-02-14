import "GameMarket"

transaction() {
    prepare(user: auth (BorrowValue) &Account) {
        let list = user.storage.borrow<auth (GameMarket.RemoveListing)  &GameMarket.ListingCollection>(from:GameMarket.MarketStoragePath) ?? panic("List")
        list.cleanResolved()
    }
}