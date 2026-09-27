import "GameIdentity"
import "GameManager"
access(all) fun main(user:Address,monsterIndex:Int): {String:AnyStruct} {

    let account = getAccount(user)
    var monsterStat:{String:AnyStruct} = {"effectiveness":0,"effectivenessEpoch":0}
    let block = getCurrentBlock().height
    if monsterIndex > -1 {
        monsterStat = GameManager.getMonsterStat(UInt64(monsterIndex))
    }

    if let gamer = account.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) {
        let quest = gamer.getQuest()
        return {
            "joinBlock":block,
            "progress":quest["progress"],
            "effectiveness":monsterStat["effectiveness"],
            "effectivenessEpoch":monsterStat["effectivenessEpoch"]
        }
    }else{
        return {
            "joinBlock":block,
            "progress":0,
            "effectiveness":monsterStat["effectiveness"],
            "effectivenessEpoch":monsterStat["effectivenessEpoch"]
        }
    }

}
