import "GameContent"

access(all) fun main(): {String:AnyStruct} {
    let block = getCurrentBlock().height
    return {
        "eventName":GameContent.eventName,
        "eventEpoch":GameContent.eventEpoch,
        "eventBlock":block
    }

}