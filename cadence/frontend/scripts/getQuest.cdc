import "GameIdentity"

access(all) fun main(user:Address): {String:AnyStruct} {

    let account = getAccount(user)

    if let gamer = account.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) {
        return  gamer.getQuest()
    }else{
        return {"progress":0}
    }

}
