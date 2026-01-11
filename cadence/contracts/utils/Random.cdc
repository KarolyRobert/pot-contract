import "Xorshift128plus"
import "RandomConsumer"


access(all) contract Random {

    access(all) entitlement TakePut

    access(all) let ReceiptStoragePath: StoragePath
    access(all) let ReceiptPublicPath: PublicPath

    access(self) let consumer:@RandomConsumer.Consumer
    
    access(all) struct RNG {
        
        access(self) let prg: Xorshift128plus.PRG
     
        init(_ prg:Xorshift128plus.PRG) {
            self.prg = prg
        }

        access(account) fun nextInt(max: Int): Int {
            return Int(self.prg.nextUInt64() % UInt64(max))
        }

        access(account) fun descIntArray(length:Int,max:Int):[Int]{
            var d = max
            var i = 0
            let result:[Int] = []
            while i < length {
                result.append(self.nextInt(max: d))
                d = d - 1
                i = i + 1
            }
            return result
        }
        
        access(account) fun intArray(length:Int,max:Int):[Int]{
            var i = 0
            let result:[Int] = []
            while i < length {
                result.append(self.nextInt(max: max))
                i = i + 1
            }
            return result
        }

        access(account) fun random(): UFix64 {
            return UFix64(self.prg.nextUInt64() / 100000000) / 184467440737.0
        }

        access(self) fun nextSeed():[UInt8] {
            var seed = self.prg.nextUInt64().toBigEndianBytes()
            return seed.concat(self.prg.nextUInt64().toBigEndianBytes())
        }
        access(self) fun nextSalt():[UInt8] {
            return  self.prg.nextUInt64().toBigEndianBytes()
        }

        access(account) fun nextRNG():RNG {
            return RNG(Xorshift128plus.PRG(sourceOfRandomness:self.nextSeed(),salt:self.nextSalt()))
        }
        
    }
 
    access(account) fun getRNG(request: @RandomConsumer.Request): Random.RNG {
        let prg = self.consumer.fulfillWithPRG(request: <-request)
        return RNG(prg)
    }

    access(account) fun request():@RandomConsumer.Request {
        return <- self.consumer.requestRandomness()
    }

    access(all) resource ReceiptStore {
        access(all) var receipts: @{UInt64:{RandomConsumer.RequestWrapper}}

        access(TakePut) fun put(receipt: @{RandomConsumer.RequestWrapper}) {
            let res <- receipt
            self.receipts[res.uuid] <-! res
        }

        access(TakePut) fun getReceipts(_ ids:[UInt64]):@[{RandomConsumer.RequestWrapper}] {
            let result:@[{RandomConsumer.RequestWrapper}] <- []
            while ids.length > 0 {
                let id = ids.removeFirst()
                let receipt <- self.receipts.remove(key: id) 
                ?? panic("Receipt not found")
                result.append(<-receipt)
            }
            
            return <- result
        }

        access(all) view fun getData():{UInt64:{String:AnyStruct}} {  
            let keys = self.receipts.keys
            let result:{UInt64:{String:AnyStruct}} = {}
            for id in keys {
                result[id] = (&self.receipts[id] as &{RandomConsumer.RequestWrapper}?)!.getData()
            }
            return result
        }


        init(){
            self.receipts <- {}
        }
    }

    access(all) fun createEmptyReceiptStore():@ReceiptStore {
        return <- create ReceiptStore()
    }

    init() {
        self.consumer <- RandomConsumer.createConsumer()
        self.ReceiptStoragePath = StoragePath(identifier: "receipt_".concat(self.account.address.toString()))!
        self.ReceiptPublicPath = PublicPath(identifier: "receipt_public_".concat(self.account.address.toString()))!
    }


}