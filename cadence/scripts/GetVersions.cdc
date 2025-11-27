
import "GameContent"

access(all) fun main(): &GameContent.Version {
    return GameContent.currentVersion
}
