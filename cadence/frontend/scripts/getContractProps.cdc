import "Chest"
import "GameContent"

access(all) fun main(): {String:AnyStruct} {

    return {
        "versions":GameContent.currentVersion
    }
}

// &GameContent.Version?