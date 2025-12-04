import "GameNFT"
import "GameContent"
import "Random"
import "RandomConsumer"
import "Utils"
import "GameToken"


access(all) contract Chest {

    access(all) let difBonus:Fix64
    access(all) let lootCount:UFix64

    access(all) event ChestCommit(chestID:UInt64, commitBlock: UInt64, receiptID: UInt64)

   
    access(all) event ChestReveal(chestID:UInt64, loot:[UInt64], commitBlock: UInt64, receiptID: UInt64)
    #removeType(ChestReveal)
    access(all) event Reveal(chestID:UInt64, loot:[UInt64],fabatka:UFix64, commitBlock: UInt64, receiptID: UInt64)

    access(all) resource Receipt : RandomConsumer.RequestWrapper {
        access(all) let type:String
        access(all) var request: @RandomConsumer.Request? 
        access(contract) var chest: @{GameNFT.INFT}?
       

        access(contract) fun getChest():@GameNFT.MetaNFT {
            let nft <- self.chest <- nil
            return <- nft! as! @GameNFT.MetaNFT
        }

        init(chest: @{GameNFT.INFT}, request: @RandomConsumer.Request) {
            self.type = "chest"
            self.chest <- chest
            self.request <- request
        }
    }

    access(all) fun commitChest(chest:@{GameNFT.INFT}):@Receipt {
        pre {
            chest.category == "chest" : "Not chest!"
        }
      
        let id = chest.id
        let request <- Random.request()
        let receipt <- create Receipt(
            chest: <- chest,
            request: <- request
        )
        emit ChestCommit(chestID:id,commitBlock:receipt.getRequestBlock()!, receiptID: receipt.uuid)
        return <- receipt
    }

    access(self) view fun modifyChance(array:[UFix64],dif:Int):[UFix64]{
        let base:Fix64 = (Fix64(dif) * self.difBonus)
        let main = Fix64(array[0]) + base < 0.0 ? 0.0 : UFix64(Fix64(array[0]) + base)        
        let seconder = Fix64(array[1]) + (base/2.0) < 0.0 ? 0.0 : UFix64(Fix64(array[1]) + (base/2.0))
        let aid = UFix64(Fix64(array[2]) + (Fix64(array[0]) - Fix64(main)) + (Fix64(array[1]) - Fix64(seconder)))
        let sum = main + seconder + aid
        return [
            main / sum,
            seconder / sum,
            aid / sum
        ]
    }

    access(self) fun normalize(_ array:[UFix64]):[UFix64] {
        var sum:UFix64 = 0.0
        for v in array {
            sum = sum + v
        }
        let result:[UFix64] = []
        for v in array {
            result.append(v / sum)
        }
        return result
    }

    access(all) fun reveilChest(receipt:@Receipt):@[AnyResource] {
        pre {
            receipt.request != nil: "Chest.revealChests: Cannot reveal the chest! The provided receipt has already been revealed."
            receipt.getRequestBlock()! <= getCurrentBlock().height:
            "Chest.revealChests: Cannot reveal the chest! The provided receipt was committed for block height ".concat(receipt.getRequestBlock()!.toString())
            .concat(" which is greater than the current block height of ")
            .concat(getCurrentBlock().height.toString())
            .concat(". The reveal can only happen after the committed block has passed.")
        }
        let commitBlock = receipt.getRequestBlock()!
        let receiptID = receipt.uuid

        let rng = Random.getRNG(request: <-receipt.popRequest())
        let content:{String:&{String:AnyStruct}} = {} //computeUnitsUsed=797 memoryEstimate=20191064  computeUnitsUsed=730 memoryEstimate=19597727
        let result:@[AnyResource] <- []
       
      
        let chest <- receipt.getChest()
        let chestId = chest.id
        let chestMeta = chest.meta.build()
        let chestLevel = chestMeta["level"] as! Int
        let wLevel = chestMeta["wLevel"] as! Int
        let chestClass = chestMeta["class"] as! String
        let dif = chestLevel - wLevel
        let zone = chestLevel / GameContent.zoneSize


        let needContent = fun(_ need:[String],_ z:Int?){
            if let zone = z {
                for key in need {
                    if content[key] == nil {
                        content[key] = GameContent.getZoneContent(key:key,zone:zone)
                    }
                }
            }else{
                for key in need {
                    if content[key] == nil {
                        content[key] = GameContent.getContent(key:key)
                    }
                }
            }
        }

        let mintItem = fun ():@{GameNFT.INFT}{
            needContent(["items","aids"],zone)
            let items = content["items"]!
            let byQuality:{String:[String]} = {}
            let keys = items.keys
        
            let QChance = ((content["consts"]!["consts"] as! &{String:{String:AnyStruct}})["qualityClass"]!)[chestClass]! as! &[UFix64]
        
            for key in keys {
                let item = items[key] as! &{String:AnyStruct}
                let qualiyt = *(item["quality"] as! &String)
                if byQuality[qualiyt] == nil {
                    byQuality[qualiyt] = []
                }
                byQuality[qualiyt]!.append(key)
            }
            let qualitys = byQuality.keys
            var qualityChance:[UFix64] = []
            for key in qualitys {
                let index = Utils.getQualityIndex(key)
                qualityChance.append(QChance[index])
            }
            qualityChance = self.normalize(qualityChance)
            let qualityIndex = Utils.chooseIndex(qualityChance,rng.random())
            let quality = qualitys[qualityIndex]
            let types = byQuality[quality]!
            let type = types[rng.nextInt(max: types.length)]
            let chainItem = items[type] as! &{String:AnyStruct}
            let itemClass = *(chainItem["class"] as! &String)
            let useFor = *(chainItem["useFor"] as! &[String])
            


            // aids sorsolás
            let aids = (content["aids"]!)
            let aidNames = aids.keys
            let aidCount = Utils.getQualityIndex(quality) + 1 
            let needs = Utils.chooseMore(*aidNames,rng.intArray(length:aidCount,max:aidNames.length))
        
            
            return <- GameNFT.minter.mintMeta(
                category: "item",
                type:type,
                meta:{
                    "level":0,
                    "class":itemClass,
                    "useFor":useFor,
                    "quality":quality,
                    "zone":zone,
                    "needs":needs
                })
        }


        let mintAvatar = fun():@{GameNFT.INFT}{
            needContent(["avatars","skills"],nil)
            let subClasses:[String] = ["Explorer","Collector","Scholar"]
            let subClass = subClasses[rng.nextInt(max:3)]
            let avatars = content["avatars"]! 
            let types = avatars.keys

            let type = types[rng.nextInt(max: types.length)]
            let classes = *((avatars[type] as! &{String:[String]})["class"]!)
            let class =  classes[rng.nextInt(max: classes.length)]

            let skills = content["skills"]!
            let skilltypes = skills.keys
            

            let validClass = [class,subClass]
            let skillPool = skilltypes.filter(view fun(element:String):Bool {
                return validClass.contains(*(skills[element] as! &{String:AnyStruct}["class"] as! &String))
            })
            log(skillPool)
            log(validClass)

            let skillNames:[String] = Utils.chooseSome(pool:skillPool,source:rng.descIntArray(length:4,max:skillPool.length))

            let avatarSkills = skillNames.map(fun(name:String):{String:AnyStruct} {
                return {"type":name,"level":0}
            })
        
            return <- GameNFT.minter.mintMeta(
                category: "avatar",
                type:type,
                meta:{
                    "level":0,
                    "class":class,
                    "subClass":subClass,
                    "skills":avatarSkills,
                    "charm":0,
                    "items":{
                        "weapon":0,
                        "armor":0,
                        "helmet":0,
                        "boots":0,
                        "ring":0,
                        "neck":0
                    },
                    "spells":{
                        0:0,
                        1:0,
                        2:0,
                        3:0,
                        4:0,
                        5:0,
                        6:0,
                        7:0
                    }
                })
        }

        let mintSpell = fun():@{GameNFT.INFT}{
            needContent(["spells","alcs"],zone)
            let spells = content["spells"]!
            let types = spells.keys
            let type = types[rng.nextInt(max: types.length)]

            let alcNames = (content["alcs"]!).keys
            let needs:[String] = []
            var i = 0
            while i < 3 {
                let aid = alcNames[rng.nextInt(max: alcNames.length)]
                needs.append(aid)
                i = i + 1
            }

            return <- GameNFT.minter.mintMeta(
                category: "spell",
                type:type,
                meta:{
                    "level":0,
                    "quality":"rare",
                    "zone":zone,
                    "needs":needs
                })
        }

        let mintNeed = fun ():@{GameNFT.INFT}{
            needContent(["aids","alcs"], zone)
            var types:[String] = []
            var category:String = ""
            if rng.random() > 0.5 {
                types = *(content["aids"]!).keys
                category = "aid"
            }else{
                types = *(content["alcs"]!).keys
                category = "alc"
            }

            let type = types[rng.nextInt(max: types.length)]

            return <- GameNFT.minter.mintBase(
                category:category,
                type:type
            )
        }
            
        needContent(["events","consts"],nil)
    
       
        let loot:[UInt64] = []

        let chestEvent = content["events"]![chestMeta["event"] as! String] as! &{String:AnyStruct}
       // log(chestEvent)
        var lootChance = *((content["consts"]!["consts"] as! &{String:AnyStruct}["loot"] as! &{String:[UFix64]})[*(chestEvent["lootChance"] as! &String)]!)
       // let currentEvent = GameContent.getCurrentEvent()//  = content["events"]![chestEvent] as! &{String:AnyStruct}
       // let consts = GameContent.getConsts()
       // let lootName = *(currentEvent["lootChance"] as! &String)
       // var lootChance = *((consts["loot"] as! &{String:[UFix64]})[lootName]!)
       // lootChance = self.modifyChance(array:lootChance,dif:dif)

      
        // fabatka
        let fabatkaConsts = content["consts"]!["consts"] as! &{String:AnyStruct}["fabatka"] as! &{String:AnyStruct} //consts["fabatka"] as! &{String:AnyStruct}
        let fabatkaMul = *(fabatkaConsts["level"] as! &UFix64)
        let fabatka = *(fabatkaConsts["base"] as! &UFix64) * (UFix64(chestLevel + 1) * fabatkaMul)

        result.append(<- GameToken.createFabatka(balance:fabatka))

      
        let lootMul = *(chestEvent["lootMul"] as! &UFix64)
        let lootCount = Int(self.lootCount * UFix64(lootMul))
      
        var lootType:[String] = []
        switch(chest.type) {
            case "avatar":
                lootType = ["avatar","item","need"]
                break
            case "monster":
                lootType = ["item","spell","need"]
                break
            case "pvp":
                lootType = ["spell","item","need"]
        }

       
        var i = 0
        while i < lootCount {
            let lType = lootType[Utils.chooseIndex(lootChance,rng.random())]
            var nft:@{GameNFT.INFT}? <- nil
            switch(lType){
                case "avatar":
                    nft <-! mintAvatar()
                    break
                case "spell":
                    nft <-! mintSpell()
                    break
                case "item":
                    nft <-! mintItem()
                    break
                case "need":
                    nft <-! mintNeed()
                    break
            }
            i = i + 1
            let minted <-nft!
            loot.append(minted.id)
            result.append(<- minted)
        }

        destroy chest
        destroy receipt
        emit Reveal(chestID:chestId,loot:loot,fabatka:fabatka,commitBlock:commitBlock,receiptID:receiptID)
        return <- result
    }

    init() {
        self.difBonus = 0.02
        self.lootCount = 4.0
    }
    
}