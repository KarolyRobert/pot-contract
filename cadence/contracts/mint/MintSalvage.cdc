import "GameNFT"
import "Random"
import "GameContent"
import "Utils"


access(all) contract MintSalvage {
    

    access(account) fun salvage(category:String,zone:Int,count:Int,currentEvent:&{String:AnyStruct},rng:Random.RNG):@[{GameNFT.INFT}] {
        let result:@[{GameNFT.INFT}] <- []

        let charmChance = *(currentEvent["charmChance"] as! &UFix64)
        let lootMul = *(currentEvent["lootMul"] as! &UFix64)
        var lootCount = Int(UFix64(count) * lootMul)

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

            let talizman <- GameNFT.minter.mintMeta(
                category:"charm",
                type:category,
                meta:{
                    "type":charmItem,
                    "level":0,
                    "quality":quality,
                    "zone":zone
                })
            result.append(<- talizman)
        }
        // uniq mint
        let uniqs = GameContent.getContent(key:"uniqs")
        let uniqNames = uniqs.keys
        let uniqChance:[UFix64] = []
        for key in uniqNames {
            uniqChance.append((uniqs[key] as! &{String:UFix64})["chance"]!)
        }
        log(uniqNames)
        log(uniqChance)
        while lootCount > 0 {
            let r = rng.random()
            log(r)
            let uniqName = uniqNames[Utils.chooseIndex(uniqChance,r)]
            //let uniqName = uniqNames[rng.nextInt(max: uniqNames.length)]
            let uniq <- GameNFT.minter.mintBase(category: "uinq", type: uniqName)
            result.append(<- uniq)
            lootCount = lootCount - 1
        }

        return <- result
    }

}