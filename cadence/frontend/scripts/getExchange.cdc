
import "Exchange"

access(all) fun main(): {String:AnyStruct} {
    return Exchange.currentEpoch!.getData()
}


//flow scripts execute ./cadence/scripts/getExchange.cdc --network testnet