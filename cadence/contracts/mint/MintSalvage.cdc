import "GameNFT"
import "Random"
import "GameContent"
import "Utils"


access(all) contract MintSalvage {
    

    access(account) fun salvage(category:String,zone:Int,count:Int,currentEvent:&{String:AnyStruct},rng:Random.RNG):@[{GameNFT.INFT}] {
        let result:@[{GameNFT.INFT}] <- []

        let charmChance = *(currentEvent["charmChance"] as! &UFix64)
       
        var lootCount = count

        let contentKey = category == "item" ? "items" : "spells"
        var quality = "rare"
        
        if charmChance > rng.random() {
            lootCount = lootCount - 1
            let itemsContent = GameContent.getZoneContent(key:contentKey, zone: zone)
            let itemNames = itemsContent.keys
            let charmItem = itemNames[rng.nextInt(max: itemNames.length)]

            if category == "item" {
                let rolled = itemsContent[charmItem] as! &{String:AnyStruct}
                quality = *(rolled["quality"] as! &String)
            }

            let consts = GameContent.getConsts()
            let baseNeedCount = Utils.getNeedBase(quality: quality, category:"charm")
            let needCount = Utils.getNeedCount(base: baseNeedCount, level:0, category: "charm", Consts: consts)

            let charm <- GameNFT.minter.mintMeta(
                category:"charm",
                type:category,
                meta:{
                    "type":charmItem,
                    "level":0,
                    "needs":needCount,
                    "quality":quality,
                    "zone":zone
                })
            result.append(<- charm)
        }
        // uniq mint
        let uniqs = GameContent.getContent(key:"uniqs")
        let uniqNames = uniqs.keys
        let uniqChance:[UFix64] = []
        for key in uniqNames {
            uniqChance.append((uniqs[key] as! &{String:UFix64})["chance"]!)
        }
       
        while lootCount > 0 {
            let r = rng.random()
            let uniqName = uniqNames[Utils.chooseIndex(uniqChance,r)]
            //let uniqName = uniqNames[rng.nextInt(max: uniqNames.length)]
            let uniq <- GameNFT.minter.mintBase(category: "uniq", type: uniqName)
            result.append(<- uniq)
            lootCount = lootCount - 1
        }

        return <- result
    }

}