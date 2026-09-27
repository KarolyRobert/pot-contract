
import "GameNFT"
import "GameIdentity"
import "GameManager"

access(all) fun main(addr:Address,avatarId:UInt64,monsterIndex:Int): {String:AnyStruct} {

    let user = getAccount(addr)
    let block = getCurrentBlock().height
    var monsterStat:{String:AnyStruct} = {"effectiveness":0,"effectivenessEpoch":0}
    if monsterIndex > -1 {
        monsterStat = GameManager.getMonsterStat(UInt64(monsterIndex))
    }
    
    if let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
        if let gamer = user.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) {
            let quest = gamer.getQuest()
            return {
                "type":"gear",
                "joinBlock":block,
                "progress":quest["progress"],
                "effectiveness":monsterStat["effectiveness"],
                "effectivenessEpoch":monsterStat["effectivenessEpoch"],
                "gear":collection.getGear(avatarId: avatarId)
            }
            
        }
        return {
            "type":"gear",
            "joinBlock":block,
            "progress":0,
            "effectiveness":monsterStat["effectiveness"],
            "effectivenessEpoch":monsterStat["effectivenessEpoch"],
            "gear":collection.getGear(avatarId: avatarId)
        }
    }
    return {"type":"error","error":"collection"}

}

