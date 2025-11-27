import "GameNFT"
import "GameToken"
import "FungibleToken"
import "GameContent"


access(all) contract GameManager {

    access(all) entitlement Mint
    access(all) entitlement Update
    access(all) entitlement GameEvent
    


   

    access(all) event createChestEvent(id:UInt64,winner:Address,type:String,gameId:String,hash:String)

    

    access(all) resource Manager {
        
        access(Mint) fun createChest(winner:Address,type:String,gameId:String,hash:String,meta:{String:AnyStruct}): @{GameNFT.INFT} {
            //let Meta = PoTUtils.MetaBuilder({}).int("zone",1).str("class","avatar").build()
            let nft <- GameNFT.minter.mintMeta(category: "chest", type:type, meta: meta)
            emit createChestEvent(id:nft.id,winner:winner,type:type,gameId:gameId,hash:hash)
            return <- nft
        }

        access(Mint) fun test(category:String,type:String,meta:{String:AnyStruct}):@{GameNFT.INFT}{
            return <- GameNFT.minter.mintMeta(category: category, type: type, meta: meta)
        }

        access(Mint) fun testBase(category:String,type:String):@{GameNFT.INFT}{
            return <- GameNFT.minter.mintBase(category: category, type: type)
        }

        access(Mint) fun fabatka(balance:UFix64):@GameToken.Fabatka{
            let token <- GameToken.createFabatka(balance:balance)
            return <- token as! @GameToken.Fabatka
        }

        access(Update) fun update(contentVersion:[String],auditVersion:[String],contents:{String:{String:AnyStruct}}) {
            GameContent.update(contentVersion:contentVersion,auditVersion:auditVersion,contents:contents)
        }

        access(GameEvent) fun setEvent(name:String){
            GameContent.setEvent(name)
        }
    
    }


    init() {
        let manager <- create Manager()
        self.account.storage.save(<- manager, to: /storage/Manager)
        let managerCb = self.account.capabilities.storage.issue<&GameManager.Manager>(/storage/Manager)
        self.account.capabilities.publish(managerCb, at: /public/Manager)
    }

}