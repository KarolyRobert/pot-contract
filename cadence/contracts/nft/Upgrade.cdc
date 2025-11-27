import "GameNFT"
import "GameToken"
import "GameContent"
import "MintSalvage"
import "Random"
import "Utils"
import "RandomConsumer"
import "Burner"


access(all) contract Upgrade {

    access(all) event UpgradeCommit(nftID:UInt64, commitBlock: UInt64, receiptID: UInt64)
    access(all) event UpgradeReveal(nftID:UInt64, commitBlock: UInt64, receiptID: UInt64)

    access(all) resource Receipt : RandomConsumer.RequestWrapper {
        access(all) let type:String
        access(all) var request: @RandomConsumer.Request? 
        access(contract) var unit:@{GameNFT.INFT}?
        access(contract) var needs:@[{GameNFT.INFT}]?
        access(contract) var uniq:@{GameNFT.INFT}?
        access(contract) var price:@GameToken.Fabatka?
       // access(contract) var hasUniq:Bool

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


        init(unit:@{GameNFT.INFT},needs:@[{GameNFT.INFT}],uniq:@{GameNFT.INFT}?,price:@GameToken.Fabatka,request: @RandomConsumer.Request) {
            self.type = "item"
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

    access(contract) fun isValidUpgrade(_ needs:[String],_ needTypes:[String]):String {
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

    access(all) view fun validateUniq(type:String,length:Int):String {
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


    access(all) fun revealUpgrade(receipt:@Receipt):@[AnyResource] {
        let commitBlock = receipt.getRequestBlock()!
        let receiptID = receipt.uuid
        let result:@[AnyResource] <- []
        let temp:@[{GameNFT.INFT}] <- []
        var uniqType:String = "empty"
        if let uniqNFT <- receipt.getUniq() {
            uniqType = uniqNFT.type
            temp.append(<-uniqNFT)
        }

        let rng = Random.getRNG(request: <-receipt.popRequest())
        let nft <- receipt.getNFT()
        let nftID = nft.id
        let price <-receipt.getPrice()
        var nftMeta = nft.meta.build()

        let needs <- receipt.getNeeds()
        var success = false

        // uniq validation
        var validation = self.validateUniq(type:uniqType,length:needs.length)


        if validation == "needs" {
            // aids validation
            let currentNeeds = nftMeta["needs"] as! [String]
            let needTypes:[String] = []
            var i = 0
            while i < needs.length {
                if needs[i].category == "aid" {
                    needTypes.append(needs[i].type)   
                }else{
                    validation = "error"
                }
                i = i + 1
            }
            if validation != "error" {
                validation = self.isValidUpgrade(currentNeeds,needTypes)
            }
        }


        let consts = GameContent.getConsts()
        let quality = nftMeta["quality"] as! String
        let nftLevel = nftMeta["level"] as! Int
        let needPrice = Utils.getPrice(category:nft.category, level: nftLevel, quality: quality, Consts: consts)

        if needPrice != price.balance {
            validation = "error"
        }

        // destination
        if validation == "valid" {
            let currentEvent = GameContent.getCurrentEvent()
            let chance = Utils.getGrowChance(level:nftMeta["level"] as! Int,category:nft.category,Event:currentEvent,Consts:consts)
          
            var baseNeedCount = Utils.getNeedBase(quality: quality, category: nft.category)
            let zone = nftMeta["zone"] as! Int

            let needType = nft.category == "item" ? "aids" : "alcs"
            let needNames = *(GameContent.getZoneContent(key:needType, zone: zone).keys)

            if chance > rng.random() { // level up , change aids
                // level up
                nftMeta["level"] = nftLevel + 1
                // scroll needs
                let newNeedCount = Utils.getNeedCount(base: baseNeedCount, level:nftLevel + 1, category: nft.category, Consts: consts)//self.getNeedCount(base: baseNeedCount, category: nft.category, level:nftLevel + 1)
                let newNeeds = Utils.chooseMore(needNames,rng.intArray(length:newNeedCount,max:needNames.length))
                nftMeta["needs"] = newNeeds
                nft.meta.update(nftMeta)

                result.append(<- nft)
            }else{ // unsuccess
                if uniqType == "gift" || uniqType == "trogaris" {
                    //scroll needs
                    let needCount = Utils.getNeedCount(base: baseNeedCount, level: nftLevel, category: nft.category, Consts: consts)//self.getNeedCount(base: baseNeedCount, category: nft.category, level:nftLevel)
                    let newNeeds = Utils.chooseMore(needNames,rng.intArray(length:needCount,max:needNames.length))
                    nftMeta["needs"] = newNeeds
                    nft.meta.update(nftMeta)

                    result.append(<-nft)
                }else{ // destroy all mint uniqs 
                    let newNeedCount = Utils.getNeedCount(base: baseNeedCount, level: nftLevel, category: nft.category, Consts: consts) // self.getNeedCount(base: baseNeedCount, category: nft.category, level:nftLevel)
                    let salvage <- MintSalvage.salvage(category: nft.category, zone: zone, count: baseNeedCount, currentEvent: currentEvent, rng: rng)
                    while salvage.length > 0 {
                        result.append(<- salvage.removeFirst())
                    }
                    destroy salvage
                    destroy nft
                }
            }
            Burner.burn(<- price)
            destroy needs
            destroy temp
        }else{ // error
            result.append(<- nft)
            result.append(<- price)
            while needs.length > 0 {
                result.append(<- needs.removeFirst())
            }
            while temp.length > 0 {
                result.append(<- temp.removeFirst())
            }
            destroy temp
            destroy needs
        }
        
        destroy receipt

        emit UpgradeReveal(nftID:nftID,commitBlock:commitBlock, receiptID:receiptID)
        return <- result
        
    }

}