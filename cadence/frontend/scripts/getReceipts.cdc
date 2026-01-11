
import "Random"

access(all) fun main(addr:Address): {String:AnyStruct} {

    let user = getAccount(addr)

    if let receipts = user.capabilities.borrow<&Random.ReceiptStore>(Random.ReceiptPublicPath) {
        return {"type":"store","store":receipts.getData()}
    }else{
        return {"type":"error","error":"missing"}
    }

}
