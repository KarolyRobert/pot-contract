import "GameContent"
import "GameNFT"
import "GameToken"
import "Burner"
import "Xorshift128plus"
import "Random"
import "Utils"


access(all) contract Exchange {

    access(all) event NPCExchange(epoch:UInt64,npc:String,nfts:[UInt64],buy_price:UFix64,sell_price:UFix64)

    access(all) var currentEpoch:EpochState?
    access(all) var prevEpoch:EpochState?
    access(self) var lastEpochStart:UInt64

    access(contract) var random:Random.RNG

    access(all) struct Good {
        access(all) let zone:Int
        access(all) let category:String
        access(all) let type:String

        access(all) view fun getData():{String:AnyStruct} {
            return {"category":self.category,"type":self.type}
        }

        init(zone:Int,category:String,type:String){
            self.zone = zone
            self.category = category
            self.type = type
        }
    }

    access(all) struct SellGood {
        access(all) let category:String
        access(all) let level:Int
        access(all) let quality:String
        access(all) let zone:Int

        init(category:String,meta:{String:AnyStruct}) {
            let level = meta["level"] as! Int
            let quality = meta["quality"] as! String
            let zone = meta["zone"] as! Int
            self.category = category
            self.level = level
            self.quality = quality
            self.zone = zone
        }

    }

    access(all) struct PriceLevel {
        access(all) let buy:UFix64
        access(all) let sell:UFix64

        init(buy:UFix64,sell:UFix64) {
            self.buy = buy
            self.sell = sell
        }
    }

    access(all) struct NPC {
        access(all) let name:String
        access(all) let priceLevel:PriceLevel
        access(all) let accept:[String]
        access(all) let goods:{UInt8:Good}

        access(all) view fun getData():{String:AnyStruct} {
            let goods:{UInt8:{String:AnyStruct}} = {}
            var index = 0
            let keys = self.goods.keys
            while self.goods.length > index {
                let key = UInt8(index)
                goods[key] = self.goods[key]!.getData()
                index = index + 1
            }
            return {"name":self.name,"goods":goods}
        }

        init(name:String,priceLevel:PriceLevel,accept:[String],goods:{UInt8:Good}) {
            self.name = name
            self.priceLevel = priceLevel
            self.accept = accept
            self.goods = goods
        }
    }

    access(all) struct EpochState {
        access(all) let id:UInt64
        access(all) let npc:NPC
        access(all) let closeTime:UInt64

        access(all) view fun getData():{String:AnyStruct} {
            return {"id":self.id,"npc":self.npc.getData(),"closeTime":self.closeTime}
        }

        init(id:UInt64,npc:NPC,closeTime:UInt64){
            self.id = id
            self.npc = npc
            self.closeTime = closeTime
        }
    }

    access(all) view fun getSellPrice(npc:NPC,buy:[UInt8],fabatka:&{String:AnyStruct}):UFix64 {
        var result:UFix64 = 0.0
        var index = 0
        let base = *(fabatka["sell"] as! &UFix64)
        let zoneMul = *(fabatka["zone"] as! &UFix64)
        while buy.length > index {
            let key = buy[index]
            let item = npc.goods[key]!
            let zoneExp = Utils.pow(base:zoneMul,exp:item.zone)
            let price = base * zoneExp * npc.priceLevel.sell
            result = result + price
            index = index + 1
        }
        return result
    }

    access(all) view fun getNPC(epoch:UInt64,time:UInt64):NPC? {
        var state:EpochState? = nil
        if Exchange.currentEpoch != nil && Exchange.currentEpoch!.id == epoch {
            state = Exchange.currentEpoch
        }else if Exchange.prevEpoch != nil && Exchange.prevEpoch!.id == epoch {
            if (time - Exchange.lastEpochStart) < 180 {
                state = Exchange.prevEpoch
            }
        }
        if(state != nil){
            return state!.npc
        }
        return nil
    }

    access(self) view fun isAccepted(npc:NPC,category:String):Bool {
        var result = false
        let pool = npc.accept
        var index = 0
        while pool.length > index {
            if pool[index] == category {
                result = true
                break
            }
            index = index + 1
        }
        return result
    }

    access(all) view fun getBuyPrice(npc:NPC,sell:[SellGood],fabatka:&{String:AnyStruct}):UFix64 {
        var result:UFix64 = 0.0
        var index = 0
        let base = *(fabatka["buy"] as! &UFix64)
        let zoneMul = *(fabatka["zone"] as! &UFix64)
        let levelMul = *(fabatka["level"] as! &UFix64)
        let qualityMul = *(fabatka["quality"] as! &UFix64)
        while sell.length > index {
            let sellGod = sell[index]
            if self.isAccepted(npc: npc, category: sellGod.category) {
                let qualityIndex = Utils.getQualityIndex(sellGod.quality)
                let price = base * Utils.pow(base:zoneMul,exp:sellGod.zone) * Utils.pow(base:levelMul,exp:sellGod.level) * Utils.pow(base:qualityMul, exp: qualityIndex) * npc.priceLevel.buy
                result = result + price
            }else {
                panic(npc.name.concat(" not accept ".concat(sellGod.category).concat("!")))
            }
            index = index + 1
        }
        return result
    }


    access(all) fun exchange(epoch:UInt64,buy:[UInt8],sell:@[GameNFT.MetaNFT],price:@GameToken.Fabatka):@[AnyResource] {
        let time = UInt64(getCurrentBlock().timestamp)
        let npc = self.getNPC(epoch:epoch,time:time)
        
        if npc != nil {
            let fabatka = GameContent.getConsts()["fabatka"] as! &{String:AnyStruct}
            let sellPrice = self.getSellPrice(npc:npc!,buy:buy,fabatka:fabatka) // mennyibe kerül

            let sellGoods:[SellGood] = []
            var index = 0
            while sell.length > index {
                let meta = sell[index].getMeta()
              
                let category = sell[index].category
                sellGoods.append(SellGood(category:category,meta:meta))
                index = index + 1
            }

            let buyPrice = self.getBuyPrice(npc: npc!, sell: sellGoods, fabatka: fabatka) // mennyit ér

            let pay:Fix64 = Fix64(sellPrice) - Fix64(buyPrice) // fizetendő
            let result:@[AnyResource] <- []
            let nfts:[UInt64] = []
            if pay > 0.0 { // 
                if pay == Fix64(price.balance) {// ha megvan az összeg csak el kell égetni mindent és ki kell mintelni a bye tömb tartalmát
                    while buy.length > 0 {
                        let buyId = buy.removeFirst()
                        let good = npc!.goods[buyId]!
                        let nft <- GameNFT.minter.mintBase(category: good.category, type: good.type)
                        nfts.append(nft.id)
                        result.append(<- nft)
                    }
                }else {
                    panic("Invalid price!")
                }
            }else { // pay negatív, az absolút értékét kell visszaadni
                if price.balance == 0.0 { //
                    while buy.length > 0 {
                        let buyId = buy.removeFirst()
                        let good = npc!.goods[buyId]!
                        let nft <- GameNFT.minter.mintBase(category: good.category, type: good.type)
                        nfts.append(nft.id)
                        result.append(<- nft)
                    }
                }
            }

            self.random = self.random.nextRNG()

            if time > self.currentEpoch!.closeTime {
                self.rollEpoch()
            }

            Burner.burn(<-price)
            destroy sell

            if pay < 0.0 {
                let payment = Fix64(0.0) - pay
                let payout <- GameToken.createFabatka(balance: UFix64(payment))
                result.append(<- payout)
            }
            
            emit NPCExchange(epoch:epoch,npc:npc!.name,nfts:nfts,buy_price:buyPrice,sell_price:sellPrice)
            return <- result
           
        }        
        panic("Invalid epoch!")
    } 

    access(contract) fun newEpochState(_ id: UInt64): EpochState {
        let npcs = GameContent.getContent(key: "npcs")
        let npcIndex = self.random.nextInt(max: npcs.keys.length)
        let npcName = npcs.keys[npcIndex]
        let npcContent = npcs[npcName] as! &{String:AnyStruct}
        let npcGoods = npcContent["goods"] as! &[{String:AnyStruct}]

        let accept = *(npcContent["accept"] as! &[String])
        let epochTime = *(npcContent["epochTime"] as! &Int)

        let priceLevelContent = npcContent["priceLevel"] as! &{String:AnyStruct}
        let buyLevel = *(priceLevelContent["buy"] as! &UFix64)
        let sellLevel = *(priceLevelContent["sell"] as! &UFix64)
        let priceLevel = PriceLevel(buy:buyLevel,sell:sellLevel)

        var index:UInt8 = 0
        let goods:{UInt8:Good} = {}
        var goodIndex = 0
        while npcGoods.length > goodIndex {
            let npcGood = npcGoods[goodIndex]
            let key = npcGood["key"] as! &String
            let zone = npcGood["zone"] as! &Int
            let count = npcGood["count"] as! &Int
            let category = *key == "aids" ? "aid" : "alc"
            let resNames = *GameContent.getZoneContent(key: *key, zone: *zone).keys
            let goodNames = Utils.chooseSome(pool:resNames,source:self.random.descIntArray(length: *count, max: resNames.length))
            while goodNames.length > 0 {
                let goodType = goodNames.removeFirst()
                goods[index] = Good(zone:*zone,category:category,type:goodType)
                index = index + 1
            }
            goodIndex = goodIndex + 1
        }

        let npc:NPC = NPC(name:npcName,priceLevel:priceLevel,accept:accept,goods:goods)
        let close = UInt64(getCurrentBlock().timestamp) + UInt64(epochTime)
        return EpochState(id:id,npc:npc,closeTime:close)
    }

    access(contract) fun rollEpoch() {
        self.prevEpoch = self.currentEpoch
        self.currentEpoch = self.newEpochState(self.prevEpoch!.id + 1)
        self.lastEpochStart = UInt64(getCurrentBlock().timestamp)
    }

    access(all) struct ExchangeManager {

        access(all) fun initExchange() {
            Exchange.currentEpoch = Exchange.newEpochState(0)
            Exchange.prevEpoch = Exchange.currentEpoch
        }
        
    }

    access(all) view fun getState(){}

    init() {
        let initBlock = getCurrentBlock()
        let salt = initBlock.height.toBigEndianBytes()
        let seed = initBlock.timestamp.toBigEndianBytes().concat(salt)
        self.lastEpochStart = UInt64(initBlock.timestamp)
        self.random = Random.RNG(Xorshift128plus.PRG(sourceOfRandomness:seed,salt:salt))
        self.currentEpoch = nil
        self.prevEpoch = nil
        let manager = ExchangeManager()
        self.account.storage.save(manager, to: /storage/ExchangeManager)
    }
}