import "GameNFT"
import "GameToken"

access(all) fun main(addr:Address,ids:[UInt64]): {String:AnyStruct} {

    let user = getAccount(addr)

    if let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
        if let fabatka = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) {
            let updates:{UInt64:AnyStruct} = {}
            while ids.length > 0 {
                let id = ids.removeFirst()
                let nft = collection.borrowNFT(id) as! &{GameNFT.INFT}
                updates[id] = nft.getData()
            }
            return {"type":"result","collection":updates,"fabatka":fabatka.balance}
        }
        return {"type":"error","error":"fabatka"}
    }
    return {"type":"error","error":"collection"}

}