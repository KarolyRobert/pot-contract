
import "Random"

access(all) fun main(addr:Address): {String:AnyStruct} {

    let user = getAccount(addr)

    if let receipts = user.capabilities.borrow<&Random.ReceiptStore>(Random.ReceiptPublicPath) {
        return {"type":"store","store":receipts.getData()}
    }else{
        return {"type":"error","error":"missing"}
    }

}

// flow scripts execute ./cadence/scripts/getReceipt.cdc --args-json '[{"type":"Address", "value":"0x179b6b1cb6755e31"}]'  --network emulator
