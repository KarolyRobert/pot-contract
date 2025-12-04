
import "GameNFT"
import "GameToken"

access(all) fun main(addr:Address,loot:[UInt64]): {String:AnyStruct} {

    let user = getAccount(addr)

    if let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
       return {"type":"result","collection":collection.getLoot(loot)}
    }
    return {"type":"error","error":"collection"}

}
