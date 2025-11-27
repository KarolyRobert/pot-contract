import "GameNFT"
import "GameToken"
import "GameContent"
import "Random"
import "Utils"
import "RandomConsumer"
import "Burner"


access(all) contract Charm {

    access(all) event CharmCommit(charmID:UInt64, commitBlock: UInt64, receiptID: UInt64)
    access(all) event CharmReveal(charmID:UInt64, commitBlock: UInt64, receiptID: UInt64)

    access(all) resource Receipt : RandomConsumer.RequestWrapper {
        access(all) let type:String
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

        init(charm:@{GameNFT.INFT},needs:@[{GameNFT.INFT}],tharion:@{GameNFT.INFT}?,price:@GameToken.Fabatka,request:@RandomConsumer.Request){
            self.type = "charm"
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
        emit CharmCommit(charmID:id,commitBlock:receipt.getRequestBlock()!, receiptID: receipt.uuid)
        return <-receipt
    }

    access(all) fun revealUpgrade(receipt:@Receipt):@[AnyResource] {
        let commitBlock = receipt.getRequestBlock()!
        let receiptID = receipt.uuid

        var validation = "invalid"
        let result:@[AnyResource] <- []
        let temp:@[{GameNFT.INFT}] <- []
        let charm <- receipt.getCharm()
        let charmID = charm.id
        let needs <- receipt.getNeeds()
        let price <- receipt.getPrice()
        var tharion:Bool = false
        if let uniqNFT <- receipt.getTharion() {
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
        let needPrice = Utils.getPrice(category:"charm",level:level,quality:quality,Consts:consts)

        if needPrice != price.balance {
            validation = "error"
        }

        if validation != "error" { // tharion is not tharion
           
            let rng = Random.getRNG(request: <-receipt.popRequest())  
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
                    charmMeta["level"] = level + 1
                    charm.meta.update(charmMeta)
                }
            }

        }


        if validation == "valid" {
            result.append(<- charm)
            destroy temp
            destroy needs
            Burner.burn(<- price)
        }else{    
            result.append(<- charm)
            result.append(<- price)
            while temp.length > 0 {
                result.append(<- temp.removeFirst())
            }
            while needs.length > 0 {
                result.append(<- needs.removeFirst())
            }
            destroy needs
            destroy temp
        }
        destroy receipt
        emit CharmReveal(charmID:charmID,commitBlock:commitBlock,receiptID:receiptID)
        return <-result
    }
}