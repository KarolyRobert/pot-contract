
import "GameMarket"
import "GameToken"
import "FlowToken"

access(all) fun main(userAddress:Address,sellerAddress:Address,id:UInt64):{String:Bool}{

    let seller = getAccount(sellerAddress)
    let user = getAccount(userAddress)

    if let collection = seller.capabilities.borrow<&GameMarket.ListingCollection>(GameMarket.MarketPublicPath) {
        
        if collection.isPurchaseable(id: id) {
            let result:{String:Bool} = {"isPurchable":true}
            let fab = collection.getListingPrice(listingID: id, token:Type<@GameToken.Fabatka>())
            let flow = collection.getListingPrice(listingID: id, token:Type<@FlowToken.Vault>())
            if fab != 0.0 {
                if let valut = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) {
                    if fab < valut.balance {
                        result["fabatka"] = true
                    }
                }
            }
            if flow != 0.0 {
                 if let valut = user.capabilities.borrow<&FlowToken.Vault>(/public/flowTokenBalance) {
                    if flow < valut.balance {
                        result["flow"] = true
                    }
                }
            }
            return result
        }
    }
    return {"isPurchable":false}

}