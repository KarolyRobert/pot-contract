import "GameMarket"
import "GameToken"

access(all) fun main(addr:Address,ids:[UInt64]): {String:AnyStruct} {

    let user = getAccount(addr)

    if let collection = user.capabilities.borrow<&GameMarket.ListingCollection>(GameMarket.MarketPublicPath) {
        if let fabatka = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) {
            var listings:{UInt64:AnyStruct} = {}
            if ids.length > 0 {
                while ids.length > 0 {
                    let id = ids.removeFirst()
                    let listing = collection.getListingData(listingID: id)
                    listings[id] = listing
                }
            }else{
                listings = collection.getListings()
            }
          
            return {"type":"result","listings":listings,"fabatka":fabatka.balance}
        }
        return {"type":"error","error":"fabatka"}
    }
    return {"type":"error","error":"collection"}

}