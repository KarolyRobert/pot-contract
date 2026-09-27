import "GameManager"

access(all) fun main(monsterIndex:UInt64): {String:AnyStruct} {
    let stat = GameManager.getMonsterStat(monsterIndex)
    return {
        "type":"monster_stat",
        "joinBlock":getCurrentBlock().id,
        "stat":stat
    }
}