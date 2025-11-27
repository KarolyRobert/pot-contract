import "GameNFT"
import "GameToken"


// flow scripts execute ./cadence/scripts/getNFTs.cdc --network emulator

access(all) fun main():{String:AnyStruct} {

    let user = getAccount(0x179b6b1cb6755e31)
    log(user)
    log(GameNFT.CollectionPublicPath)
    let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Nincs collection")
    let data = collection.getData()
    let vault = user.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Nincs collection")
    log("NFT collection:")
    log(data)
    log("Fabatka:".concat(vault.balance.toString()))
    return {"nfts":data,"fabatka":vault.balance}
}