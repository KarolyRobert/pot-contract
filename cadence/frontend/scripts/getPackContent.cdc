import "GameMarket"
import "GameNFT"

access(all) fun main(userAddress:Address,sellerAddress:Address,listing:Bool,id:UInt64):{UInt64:{String:AnyStruct}} {

    let seller = getAccount(sellerAddress)
    let user = getAccount(userAddress)
    if listing {
        if let market = seller.capabilities.borrow<&GameMarket.ListingCollection>(GameMarket.MarketPublicPath) {
            return market.getListingContent(listingID:id)
        }
    }else{
        if let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
            return collection.getPackContent(id)
        }
    }
    return {}

}