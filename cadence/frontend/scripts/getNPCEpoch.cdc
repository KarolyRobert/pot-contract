
import "GameNPC"

access(all) fun main(): {String:AnyStruct} {
    return GameNPC.currentEpoch!.getData()
}


//flow scripts execute ./cadence/scripts/getExchange.cdc --network testnet