
import "GameMarket"
import "GameToken"

access(all) fun main(addr:Address,listingID:UInt64): {String:AnyStruct} {

    let user = getAccount(addr)

    if let collection = user.capabilities.borrow<&GameMarket.ListingCollection>(GameMarket.MarketPublicPath) {
       
            let listing = collection.getListingData(listingID: listingID)
    
            return {"type":"result","listing":listing}
       
    }
    return {"type":"error","error":"collection"}

}