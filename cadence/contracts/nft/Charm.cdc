import "GameNFT"
import "GameToken"
import "GameContent"
import "Random"
import "Utils"
import "RandomConsumer"
import "Burner"


access(all) contract Charm {

    access(all) event CharmCommit(nftID:UInt64, commitBlock: UInt64, receiptID: UInt64)
   // access(all) event CharmReveal(charmID:UInt64, commitBlock: UInt64, receiptID: UInt64)

    access(all) resource Receipt : RandomConsumer.RequestWrapper {

        access(all) var request: @RandomConsumer.Request?
        access(contract) var charm:@{GameNFT.INFT}?
        access(contract) var needs:@[{GameNFT.INFT}]?
        access(contract) var tharion:@{GameNFT.INFT}?
        access(contract) var price:@GameToken.Fabatka?

        access(contract) fun getCharm():@GameNFT.MetaNFT {
            let temp <- self.charm <- nil
            return <- temp as! @GameNFT.MetaNFT
        }

        access(contract) fun getPrice():@GameToken.Fabatka {
            let temp <- self.price <- nil
            return <- temp!
        }

        access(contract) fun getNeeds():@[{GameNFT.INFT}] {
            let temp <- self.needs <- nil
            return <- temp!
        }

        access(contract) fun getTharion():@{GameNFT.INFT}? {
            let temp <- self.tharion <- nil
            return <- temp
        }

        access(all) view fun getData():{String:AnyStruct} {
            return {
                "type":"charm_upgrade",
                "nft":self.charm?.getData()
            }
        }

        access(contract) fun resolve():@RandomConsumer.RevealOutcome {
           

            var validation = "invalid"
            let result:@[AnyResource] <- []
            let temp:@[{GameNFT.INFT}] <- []
            let charm <- self.getCharm()
            let charmID = charm.id
            let needs <- self.getNeeds()
            let price <- self.getPrice()
            var tharion:Bool = false
            if let uniqNFT <- self.getTharion() {
                if uniqNFT.type != "tharion" || (uniqNFT.type == "tharion" && needs.length > 0) {
                    validation = "error"
                }
                tharion = true
                temp.append(<-uniqNFT)
            }

            let charmMeta = charm.meta.build()
            let consts = GameContent.getConsts()
            let level = charmMeta["level"] as! Int
            let quality = charmMeta["quality"] as! String

            let needPrice = Utils.getUpgradePrice(category:"charm",meta:charmMeta,Consts:consts)

            if needPrice != price.balance {
                validation = "error"
            }

            if validation != "error" { // tharion is not tharion
            
                let rng = Random.getRNG(request: <-self.popRequest())  
                let baseNeedCount = Utils.getNeedBase(quality: quality, category:"charm")
                let needCount = Utils.getNeedCount(base: baseNeedCount, level: level, category: "charm", Consts: consts)
                if !tharion { // check needs
                    let talentumCount = needs.length
                    if talentumCount == needCount {
                        validation = "valid"
                        var i = 0
                        while i < talentumCount {
                            if needs[i].type != "talentum" {
                                validation = "error"
                            }
                            i = i +1
                        }
                    }else{
                        validation = "error"
                    }
                }

                if validation == "valid" {
                    let currentEvent = GameContent.getCurrentEvent()
                    let chance = Utils.getGrowChance(level: level, category:"charm", Event: currentEvent, Consts: consts)
                    
                    if chance > rng.random() {
                        let newNeedCount = Utils.getNeedCount(base: baseNeedCount, level: level + 1, category: "charm", Consts: consts)
                        charmMeta["level"] = level + 1
                        charmMeta["needs"] = newNeedCount
                        charm.meta.update(charmMeta)
                    }
                }

            }

            let emitResult:[UInt64] = []
            let success:Bool = validation == "valid"
            var resultToken:UFix64 = 0.0

            if validation == "valid" {
                emitResult.append(charm.id)
                result.append(<- charm)
                destroy temp
                destroy needs
                Burner.burn(<- price)
            }else{
                emitResult.append(charm.id)    
                result.append(<- charm)
                resultToken = price.balance
                result.append(<- price)
                while temp.length > 0 {
                    let tempItem <- temp.removeFirst()
                    emitResult.append(tempItem.id)
                    result.append(<- tempItem)
                }
                while needs.length > 0 {
                    let needItem <- needs.removeFirst()
                    emitResult.append(needItem.id)
                    result.append(<- needItem)
                }
                destroy needs
                destroy temp
            }
           
            return <- RandomConsumer.createOutcome(success:success,ids:emitResult,balance:resultToken,result: <- result)
        }

        init(charm:@{GameNFT.INFT},needs:@[{GameNFT.INFT}],tharion:@{GameNFT.INFT}?,price:@GameToken.Fabatka,request:@RandomConsumer.Request){
            self.charm <- charm
            self.needs <- needs
            self.price <- price
            self.request <- request
             if let optional <- tharion {
                self.tharion <- optional
            }else{
                self.tharion <- nil
            }
        }
    }

    access(all) fun commitUpgrade(charm:@{GameNFT.INFT},needs:@[{GameNFT.INFT}],tharion:@{GameNFT.INFT}?,price:@GameToken.Fabatka):@Receipt {
        pre {
            charm.category == "charm" : "Only charm accepted"
        }
        let request <- Random.request()
        let id = charm.id
        let receipt<- create Receipt(charm:<-charm,needs:<-needs,tharion:<-tharion,price:<-price,request:<-request)

        emit CharmCommit(nftID:id,commitBlock:receipt.getRequestBlock()!, receiptID: receipt.uuid)
       
        return <-receipt
    }

}