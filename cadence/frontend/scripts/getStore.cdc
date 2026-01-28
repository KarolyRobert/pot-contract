

import "GameMarket"
import "GameToken"

access(all) fun main(addr:Address): {String:AnyStruct} {

    let user = getAccount(addr)

    if let collection = user.capabilities.borrow<&GameMarket.ListingCollection>(GameMarket.MarketPublicPath) {
       
            var listings:{UInt64:AnyStruct} = {}
          
            listings = collection.getStore()
    
            return {"type":"result","listings":listings}
       
    }
    return {"type":"error","error":"collection"}

}