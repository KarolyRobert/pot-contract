
import "GameNFT"

access(all) fun main(addr:Address,avatarId:UInt64): {String:AnyStruct} {

    let user = getAccount(addr)

    if let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
        return collection.getGear(avatarId: avatarId)
    }
    return {"type":"error","error":"collection"}

}

