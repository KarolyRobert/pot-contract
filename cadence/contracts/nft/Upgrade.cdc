import "GameNFT"
import "GameToken"
import "GameContent"
import "MintSalvage"
import "Random"
import "Utils"
import "RandomConsumer"
import "Burner"
import "GameIdentity"


access(all) contract Upgrade {

    access(all) event UpgradeCommit(nftID:UInt64, commitBlock: UInt64, receiptID: UInt64)
    access(all) event UpgradeReveal(result:[UInt64], commitBlock: UInt64, receiptID: UInt64)
    access(all) event RollReveal(chance:UFix64,roll:UFix64)

    access(all) resource Receipt : RandomConsumer.RequestWrapper {
        access(all) let id:UInt64
        access(all) var request: @RandomConsumer.Request? 
        access(contract) var unit:@{GameNFT.INFT}?
        access(contract) var needs:@[{GameNFT.INFT}]?
        access(contract) var uniq:@{GameNFT.INFT}?
        access(contract) var price:@GameToken.Fabatka?

        access(contract) fun getNFT():@GameNFT.MetaNFT {
            let temp <- self.unit <- nil
            return <- temp as! @GameNFT.MetaNFT
        }

        access(contract) fun getNeeds():@[{GameNFT.INFT}] {
            let temp <- self.needs <- nil
            return <- temp!
        }

        access(contract) fun getUniq():@{GameNFT.INFT}? {
            let temp <- self.uniq <- nil
            return <- temp
        }

        access(contract) fun getPrice():@GameToken.Fabatka {
            let temp <- self.price <- nil
            return <- temp!
        }

        access(all) view fun getData():{String:AnyStruct} {
            return {
                "type":"upgrade",
                "nft":self.unit?.getData(),
                "isDanger":self.uniq == nil
            }
        }

        access(contract) fun resolve():@RandomConsumer.RevealOutcome {

            fun isValidUpgrade(_ needs:[String],_ needTypes:[String]):String {
                var validation = "invalid"
                if needs.length == needTypes.length {
                    while needTypes.length > 0 {
                        let aid = needTypes.removeFirst()
                        if(validation != "error"){ // nem aid
                            var hIndex = 0
                            var hit = false
                            for need in needs {
                                if !hit {
                                    if need == aid {
                                        hit = true

                                    }else{
                                        hIndex = hIndex + 1
                                    }
                                }
                            }  
                            if hit {
                                let _ = needs.remove(at: hIndex)
                            }else{
                                validation = "error" // not need
                            }   
                        }
                    }
                
                    if needs.length > 0 { // has left need
                        validation = "error"
                    }else{
                        validation = "valid"
                    }
                }else{
                    validation = "error"
                }
                return validation
            }

            view fun validateUniq(type:String,length:Int):String {
                var result = "needs"
                if type == "talentum" || type == "tharion" {
                    result = "error"
                }else if type == "trogaris" {
                    if length > 0 {
                        result = "error"
                    }else{
                        result = "valid"
                    }
                }
                return result
            }

            let owner = self.owner ?? panic("Must have Collection in storage!")
            let gamer = owner.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) ?? panic("Missing Seller Identity!")
            var burnNFT = 0
            
            let result:@[AnyResource] <- []
            let resultIDs:[UInt64] = []
            var success = true
            var resultToken:UFix64 = 0.0
            let temp:@[{GameNFT.INFT}] <- []
            var uniqType:String = "empty"
            if let uniqNFT <- self.getUniq() {
                burnNFT = burnNFT + 1
                uniqType = uniqNFT.type
                temp.append(<-uniqNFT)
            }

            let rng = Random.getRNG(request: <-self.popRequest())
            let nft <- self.getNFT()
        //  let nftID = nft.id
            let price <-self.getPrice()
            var nftMeta = nft.meta.build()

            let needs <- self.getNeeds()

            burnNFT = burnNFT + needs.length

            // uniq validation
            var validation = validateUniq(type:uniqType,length:needs.length)


            if validation == "needs" {
                // aids validation
                let currentNeeds = nftMeta["needs"] as! [String]
                let needTypes:[String] = []
                var i = 0
                while i < needs.length {
                    if (nft.category == "item" && needs[i].category == "aid") || (nft.category == "spell" && needs[i].category == "alc") {
                        needTypes.append(needs[i].type)   
                    }else{
                        validation = "error"
                    }
                    i = i + 1
                }
                if validation != "error" {
                    validation = isValidUpgrade(currentNeeds,needTypes)
                }
            }


            let consts = GameContent.getConsts()
            let quality = nftMeta["quality"] as! String
            let nftLevel = nftMeta["level"] as! Int
            let fate = nftMeta["fate"] as! Int
            let needPrice = Utils.getUpgradePrice(category:nft.category,meta:nftMeta,Consts:consts)

            if needPrice != price.balance {
                validation = "error"
            }

            if fate == 0 {
                validation = "error"
            }

            // destination
            if validation == "valid" {
                gamer.setBurn(burnToken: needPrice, burnNFT: burnNFT)
                let currentEvent = GameContent.getCurrentEvent()
                let chance = Utils.getGrowChance(level:nftMeta["level"] as! Int,category:nft.category,Event:currentEvent,Consts:consts)
            
                var baseNeedCount = Utils.getNeedBase(quality: quality, category: nft.category)
                let zone = nftMeta["zone"] as! Int

                let needType = nft.category == "item" ? "aids" : "alcs"
                let needNames = *(GameContent.getZoneContent(key:needType, zone: zone).keys)

                let randomRoll = rng.random()
                emit RollReveal(chance:chance,roll:randomRoll)
                if chance > randomRoll { // level up , change aids os alcs
                    gamer.setCraft(success: true)
                    // level up
                    nftMeta["level"] = nftLevel + 1
                    // scroll needs
                    let newNeedCount = Utils.getNeedCount(base: baseNeedCount, level:nftLevel + 1, category: nft.category, Consts: consts)//self.getNeedCount(base: baseNeedCount, category: nft.category, level:nftLevel + 1)
                    let newNeeds = Utils.chooseMore(needNames,rng.intArray(length:newNeedCount,max:needNames.length))
                    nftMeta["needs"] = newNeeds
                    nft.meta.update(nftMeta)

                    resultIDs.append(nft.id)
                    result.append(<- nft)
                }else{ // unsuccess
                    gamer.setCraft(success: false)
                    if uniqType == "gift" || uniqType == "trogaris" {
                        //scroll needs
                        let needCount = Utils.getNeedCount(base: baseNeedCount, level: nftLevel, category: nft.category, Consts: consts)//self.getNeedCount(base: baseNeedCount, category: nft.category, level:nftLevel)
                        let newNeeds = Utils.chooseMore(needNames,rng.intArray(length:needCount,max:needNames.length))


                        nftMeta["needs"] = newNeeds
                        nftMeta["fate"] = (nftMeta["fate"] as! Int) - 1
                        nft.meta.update(nftMeta)
                        resultIDs.append(nft.id)
                        result.append(<-nft)
                    }else{ // destroy all mint uniqs 

                        let newNeedCount = Utils.getNeedCount(base: baseNeedCount, level: nftLevel, category: nft.category, Consts: consts) // self.getNeedCount(base: baseNeedCount, category: nft.category, level:nftLevel)
                        let salvage <- MintSalvage.salvage(category: nft.category, zone: zone, count: newNeedCount, currentEvent: currentEvent, rng:rng.nextRNG())
                        gamer.setLoot(lootToken: 0.0, lootNFT: salvage.length)
                        while salvage.length > 0 {
                            let salv <-salvage.removeFirst()
                            resultIDs.append(salv.id)
                            result.append(<- salv)
                        }
                        destroy salvage
                        destroy nft
                    }
                }
                Burner.burn(<- price)
                destroy needs
                destroy temp
            }else{ // error
                success = false
                resultIDs.append(nft.id)
                result.append(<- nft)
                resultToken = price.balance
                result.append(<- price)
                while needs.length > 0 {
                    let needItem <- needs.removeFirst()
                    resultIDs.append(needItem.id)
                    result.append(<- needItem)
                }
                while temp.length > 0 {
                    let tempItem <- temp.removeFirst()
                    resultIDs.append(tempItem.id)
                    result.append(<- tempItem)
                }
                destroy temp
                destroy needs
            }
            

            return <- RandomConsumer.createOutcome(success:success,ids:resultIDs,balance:resultToken,result: <- result)
        }

        init(unit:@{GameNFT.INFT},needs:@[{GameNFT.INFT}],uniq:@{GameNFT.INFT}?,price:@GameToken.Fabatka,request: @RandomConsumer.Request) {
            self.id = unit.id
            self.unit <- unit
            self.needs <- needs
            self.price <- price
            self.request <- request
            if let optional <- uniq {
                self.uniq <- optional
            }else{
                self.uniq <- nil
            }
        }
    }

    access(all) fun commitUpgrade(unit:@{GameNFT.INFT},needs:@[{GameNFT.INFT}],uniq:@{GameNFT.INFT}?,price:@GameToken.Fabatka):@Receipt {
        pre {
            unit.category == "item" || unit.category == "spell": "Only items and spells accepted"
        }
        let request <- Random.request()
        let id = unit.id
        let receipt <- create Receipt(unit:<-unit,needs:<-needs,uniq: <- uniq,price:<- price,request:<-request)
        emit UpgradeCommit(nftID:id,commitBlock:receipt.getRequestBlock()!, receiptID: receipt.uuid)
        return <- receipt
    }


}