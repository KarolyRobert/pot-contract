import "GameContent"
import "GameNFT"
import "GameToken"
import "Burner"
import "Xorshift128plus"
import "Random"
import "Utils"
import "GameIdentity"


access(all) contract GameNPC {

    access(all) event NPCExchange(epoch:UInt64,npc:String,nfts:[UInt64],buy_price:UFix64,sell_price:UFix64)
    access(all) event PackingEvent(epoch:UInt64,npc:String,pack:UInt64,packed:[UInt64],price:UFix64)

    access(all) var currentEpoch:EpochState?
    access(all) var prevEpoch:EpochState?
    access(self) var lastEpochStart:UInt64

    access(contract) var random:Random.RNG
 
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

    access(all) struct NPC {
        access(all) let name:String
        access(all) let epochTime:Int
        access(all) let meta:{String:AnyStruct}
      
        access(all) view fun getData():{String:AnyStruct} {
            return {"name":self.name,"meta":self.meta}
        }

        init(name:String,epochTime:Int,meta:{String:AnyStruct}) {
            self.name = name
            self.epochTime = epochTime
            self.meta = meta
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

    access(all) fun getSellPrice(npc:NPC,buy:[UInt8],fabatka:&{String:AnyStruct}):UFix64 {
        let expCache:{Int:UFix64} = {}

        let getZoneExp = fun (_ mul:UFix64,_ zone:Int):UFix64 {
            if let result = expCache[zone] {
                return result
            }else{
                let result = Utils.pow(base:mul,exp:zone)
                expCache[zone] = result
                return result
            }
        }

        var result:UFix64 = 0.0
        var index = 0
        let base = *(fabatka["sell"] as! &UFix64)
        let zoneMul = *(fabatka["zone"] as! &UFix64)
        let trade = npc.meta["trade"] as! {String:AnyStruct}
        let goods = trade["goods"] as! {UInt8:AnyStruct}
        let priceLevel = trade["priceLevel"] as! {String:UFix64}
        let sellLevel = priceLevel["sell"]!
        
        while buy.length > index {
            let key = buy[index]
            let item = goods[key] as! {String:AnyStruct}
            let zone = item["zone"] as! Int
            let zoneExp = getZoneExp(zoneMul,zone)
            let price = base * zoneExp * sellLevel
            result = result + price
            index = index + 1
        }
        return result
    }

    access(all) view fun getNPC(epoch:UInt64,time:UInt64):NPC? {
        var state:EpochState? = nil
        if self.currentEpoch != nil && self.currentEpoch!.id == epoch {
            state = self.currentEpoch
        }else if self.prevEpoch != nil && self.prevEpoch!.id == epoch {
            if (time - self.lastEpochStart) < 180 {
                state = self.prevEpoch
            }
        }
        if(state != nil){
            return state!.npc
        }
        return nil
    }

    access(self) view fun isAccepted(npc:NPC,roleName:String,category:String):Bool {
        var result = false
        let role = npc.meta[roleName] as! {String:AnyStruct}
        let pool = role["accept"] as! [String]
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

    access(all) fun getBuyPrice(npc:NPC,sell:[SellGood],fabatka:&{String:AnyStruct}):UFix64 {

        var result:UFix64 = 0.0
        var index = 0
        let base = *(fabatka["buy"] as! &UFix64)
        let zoneMul = *(fabatka["zone"] as! &UFix64)
        let levelMul = *(fabatka["level"] as! &UFix64)
        let qualityMul = *(fabatka["quality"] as! &UFix64)
        let trade = npc.meta["trade"] as! {String:AnyStruct}
        let priceLevel = trade["priceLevel"] as! {String:UFix64}
        let buyLevel = priceLevel["buy"]!

        let zoneExpCache:{Int:UFix64} = {}
        let levelExpCache:{Int:UFix64} = {}
        let qualityExpCache:{Int:UFix64} = {}

        let getExp = fun (type:String,exp:Int):UFix64 {
            switch(type){
                case "zone":
                    if let result = zoneExpCache[exp] {
                        return result
                    }else{
                        let result = Utils.pow(base:zoneMul,exp:exp)
                        zoneExpCache[exp] = result
                        return result
                    }
                case "level":
                    if let result = levelExpCache[exp] {
                        return result
                    }else{
                        let result = Utils.pow(base:levelMul,exp:exp)
                        levelExpCache[exp] = result
                        return result
                    }
                case "quality":
                    if let result = qualityExpCache[exp] {
                        return result
                    }else{
                        let result = Utils.pow(base:qualityMul,exp:exp)
                        qualityExpCache[exp] = result
                        return result
                    }
                default:panic("Illegal type of exp!")
            }
        }

        while sell.length > index {
            let sellGod = sell[index]
            if self.isAccepted(npc: npc, roleName:"trade",category: sellGod.category) {
                let qualityIndex = Utils.getQualityIndex(sellGod.quality)
                let zoneExp = getExp(type:"zone",exp:sellGod.zone)
                let levelExp = getExp(type:"level",exp:sellGod.level)
                let qualityExp = getExp(type:"quality",exp:qualityIndex)
                let price = base * zoneExp * levelExp * qualityExp * buyLevel
                result = result + price
            }else {
                panic("\(npc.name) not accept \(sellGod.category)!")
            }
            index = index + 1
        }
        return result
    }

    access(all) fun getPackPrice(npc:NPC):UFix64 {
        let pack = npc.meta["pack"] as! {String:AnyStruct}
        return pack["price"] as! UFix64
    }

    access(all) fun exchange(epoch:UInt64,buy:[UInt8],sell:@[GameNFT.MetaNFT],price:@GameToken.Fabatka,gamer: auth(GameIdentity.NPC) &GameIdentity.Gamer):@[AnyResource] {
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

            gamer.setLoot(lootToken:buyPrice,lootNFT:buy.length)
            gamer.setBurn(burnToken:sellPrice,burnNFT:sellGoods.length)

            let pay:Fix64 = Fix64(sellPrice) - Fix64(buyPrice) // fizetendő
            let result:@[AnyResource] <- []
            let nfts:[UInt64] = []

            let trade = npc!.meta["trade"] as! {String:AnyStruct}
            let goods = trade["goods"] as! {UInt8:AnyStruct}

            if pay > 0.0 { // 
                if pay == Fix64(price.balance) {// ha megvan az összeg csak el kell égetni mindent és ki kell mintelni a bye tömb tartalmát
                    while buy.length > 0 {
                        let buyId = buy.removeFirst()
                        let good = goods[buyId] as! {String:AnyStruct}
                        let category = good["category"] as! String
                        let type = good["type"] as! String
                        let nft <- GameNFT.minter.mintBase(category: category, type:type)
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
                        let good = goods[buyId] as! {String:AnyStruct}
                        let category = good["category"] as! String
                        let type = good["type"] as! String
                        let nft <- GameNFT.minter.mintBase(category: category, type: type)
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

    access(all) fun packing(epoch:UInt64,packed:@[{GameNFT.INFT}],price:@GameToken.Fabatka,gamer: auth(GameIdentity.NPC) &GameIdentity.Gamer):@GameNFT.PackNFT {
        let time = UInt64(getCurrentBlock().timestamp)
        let npc = self.getNPC(epoch:epoch,time:time)

        
        if(npc != nil){
            let packingPrice = self.getPackPrice(npc:npc!)
            let pack = npc!.meta["pack"] as! {String:AnyStruct}
            let maxCount = pack["maxCount"] as! Int
            gamer.setBurn(burnToken:packingPrice,burnNFT:0)
            if packed.length > maxCount && packingPrice == price.balance {
                panic("Pack to big!")
            }else{
                let packedIDs:[UInt64] = []
                let packing:@{UInt64:{GameNFT.INFT}} <- {}
                while packed.length > 0 {
                    let nft <- packed.removeFirst()
                    if self.isAccepted(npc:npc!,roleName:"pack",category:nft.category){
                        packedIDs.append(nft.id)
                        packing[nft.id] <-! nft
                    }else{
                        panic("Unacceptable! \(nft.category)")
                    }
                    
                }
                Burner.burn(<- price)
                destroy packed
                let packNFT <- GameNFT.minter.mintPack(type: "box", packed: <- packing)
                emit  PackingEvent(epoch:epoch,npc:npc!.name,pack:packNFT.id,packed:packedIDs,price:packingPrice)
                return <- packNFT
            }
        }
        panic("Epoch expired!")
    }

    access(contract) fun createTradeMeta(trade:&{String:AnyStruct}):{String:AnyStruct} {
        let npcGoods = trade["goods"] as! &[{String:AnyStruct}]
            var index:UInt8 = 0
        let goods:{UInt8:{String:AnyStruct}} = {}
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
                goods[index] = {"zone":*zone,"category":category,"type":goodType}
                index = index + 1
            }
            goodIndex = goodIndex + 1
        }

        let priceLevelContent = trade["priceLevel"] as! &{String:AnyStruct}
        let accept = *(trade["accept"] as! &[String])
        let buyLevel = *(priceLevelContent["buy"] as! &UFix64)
        let sellLevel = *(priceLevelContent["sell"] as! &UFix64)

        return {"accept":accept,"goods":goods,"priceLevel":{"buy":buyLevel,"sell":sellLevel}}
    }

    access(contract) fun createPackMeta(pack:&{String:AnyStruct}):{String:AnyStruct} {
        let accept = pack["accept"] as! &[String]
        let type = pack["type"] as! &String
        let price = pack["price"] as! &UFix64
        let maxCount = pack["maxCount"] as! &Int
        return {"type":*type,"accept":*accept,"price":*price,"maxCount":*maxCount}
    }

    access(contract) fun createNPC(name:String,npcs:&{String:AnyStruct}):NPC {
        let content = npcs[name] as! &{String:AnyStruct}
        let capabilitys = content["capability"] as! &[{String:String}]
        let epochTime = *(content["epochTime"] as! &Int)
        let meta:{String:AnyStruct} = {}
        for cap in capabilitys {
            let category = cap["category"]!
            let type = cap["type"]!
            let capability = GameContent.getContent(key: category)[type] as! &{String:AnyStruct}
            switch(category){
                case "trades":
                    let tradeMeta = self.createTradeMeta(trade:capability)
                    meta["trade"] = tradeMeta
                    break
                case "packs":
                    let packMeta = self.createPackMeta(pack:capability)
                    meta["pack"] = packMeta
            }
        }
        return NPC(name:name,epochTime:epochTime,meta:meta)
    }

    access(contract) fun newEpochState(_ id: UInt64): EpochState {
        let npcs = GameContent.getContent(key: "npcs")
        var npc:NPC? = nil
        if let epoch = self.currentEpoch {
            let prevName = epoch.npc.name
            let names = *npcs.keys
            let validNames:[String] = []
            for name in names {
                if name != prevName {
                    validNames.append(name)
                }
            }
            let npcIndex = self.random.nextInt(max: validNames.length)
            let npcName = validNames[npcIndex]
            let npcContent = npcs[npcName] as! &{String:AnyStruct}
            npc = self.createNPC(name:npcName,npcs:npcs)
        }else{
            let npcIndex = self.random.nextInt(max: npcs.keys.length)
            let npcName = npcs.keys[npcIndex]
            let npcContent = npcs[npcName] as! &{String:AnyStruct}
            npc = self.createNPC(name:npcName,npcs:npcs)
        }
      
        let close = UInt64(getCurrentBlock().timestamp) + UInt64(npc!.epochTime)
        return EpochState(id:id,npc:npc!,closeTime:close)
    }

    access(contract) fun rollEpoch() {
        self.prevEpoch = self.currentEpoch
        self.currentEpoch = self.newEpochState(self.prevEpoch!.id + 1)
        self.lastEpochStart = UInt64(getCurrentBlock().timestamp)
    }

    access(all) struct ExchangeManager {

        access(all) fun initExchange() {
            GameNPC.currentEpoch = GameNPC.newEpochState(0)
            GameNPC.prevEpoch = GameNPC.currentEpoch
        }
        
    }

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