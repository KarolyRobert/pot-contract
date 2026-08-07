
import "GameNFT"
import "GameIdentity"
import "GameManager"

access(all) fun main(addr:Address,avatarId:UInt64,monsterIndex:Int): {String:AnyStruct} {

    let user = getAccount(addr)
    var monsterStat:{String:AnyStruct} = {"effectiveness":0 as UInt16}
    if monsterIndex > -1 {
        monsterStat = GameManager.getMonsterStat(UInt64(monsterIndex))
    }

    if let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
        if let gamer = user.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) {
            let quest = gamer.getQuest()
            let progress = quest["progress"] as! Int
            return {
                "type":"gear",
                "progress":progress,
                "effectiveness":monsterStat["effectiveness"] as! UInt16,
                "gear":collection.getGear(avatarId: avatarId)}
            
        }
    }
    return {"type":"error","error":"collection"}

}

