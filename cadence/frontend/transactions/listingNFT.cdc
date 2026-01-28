import "NonFungibleToken"
import "GameNFT"
import "GameMarket"


transaction(type:String,offers:{String:UFix64},nfts:[UInt64]) {

    prepare(user: auth (BorrowValue) &Account) {
        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        let list = user.storage.borrow<auth (GameMarket.CreateListing)  &GameMarket.ListingCollection>(from:GameMarket.MarketStoragePath) ?? panic("List")

        let sell:@[{GameNFT.INFT}] <- []
        while nfts.length > 0 {
            let nftID = nfts.removeFirst()
            let nft <- collection.withdraw(withdrawID: nftID) as! @{GameNFT.INFT}
            sell.append(<- nft)
        }
        
        list.nftListing(type:type, offers: offers, sell: <- sell)
    }


}