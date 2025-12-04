
import "GameNFT"
import "GameToken"

access(all) fun main(addr:Address): {String:AnyStruct} {

    let user = getAccount(addr)

    if let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
        if let fabatka = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) {
            return {"type":"result","collection":collection.getData(),"fabatka":fabatka.balance}
        }
        return {"type":"error","error":"fabatka"}
    }
    return {"type":"error","error":"collection"}

}
