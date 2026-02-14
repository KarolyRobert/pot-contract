import "GameMarket"

access(all) fun main(addr:Address):UInt64 {
    let user = getAccount(addr)
    if let market = user.capabilities.borrow<&GameMarket.ListingCollection>(GameMarket.MarketPublicPath) {
        return market.getRevision()  
    }
    return 0
}