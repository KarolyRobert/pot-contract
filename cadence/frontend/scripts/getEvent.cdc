import "GameContent"

access(all) fun main(): {String:AnyStruct} {
    let block = getCurrentBlock()
    return {
        "eventID":GameContent.getEventName(),
        "eventBlock":block.id
    }

}