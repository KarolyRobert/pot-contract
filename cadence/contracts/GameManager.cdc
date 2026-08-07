import "GameNFT"
import "GameToken"
import "FungibleToken"
import "GameContent"
import "GameIdentity"


access(all) contract GameManager {

    access(all) entitlement Mint
    access(all) entitlement Gamer
    access(all) entitlement Name
    access(all) entitlement Update
    access(all) entitlement GameEvent
    access(all) entitlement StartBatch
    

    access(all) event createChestEvent(id:UInt64,winner:Address,type:String,gameId:String,hash:String)

    
    access(all) event startGameEvent(gameID:String,startHash:String,contentVersion:String,auditVersion:String,claimDeadLine:UInt64)
    // kikerül
    access(all) event startGame(gameID:String,startHash:String,contentVersion:String,auditVersion:String,claimDeadLine:UInt64,eventID:String)
    access(all) event setAvatarName(id:UInt64)

    access(all) resource MonsterStat {
        access(all) var win: UInt32
        access(all) var lose: UInt32
        access(all) var counter: Int
        access(all) var value: UInt16

        init() {
            self.win = 0
            self.lose = 0
            self.counter = 0
            self.value = 0
        }

        access(all) fun update(_ victory:Bool) {

            if victory {
                self.win = self.win + 1
            }else {
                self.lose = self.lose + 1
            }

            if self.win < self.lose || self.value > 0 {

                let threshold = *(GameContent.getConsts()["monsterEffectivenessThreshold"] as! &Int)

                self.counter = victory ? self.counter + 1 : self.counter - 1
                if threshold < self.counter { // 
                    if self.value > 0 {
                        self.value = self.value - 1
                    }
                    self.counter = 0
                }
                if -threshold > self.counter {
                    self.value = self.value + 1
                    self.counter = 0
                }              
            }
        }
    }

    access(all) resource Monsters {
        access(all) var monsters: @{UInt64:MonsterStat}

        access(contract) fun getMonster(_ index:Int): &GameManager.MonsterStat {
            let id = UInt64(index)
            if let monster:&MonsterStat = &self.monsters[id]{
                return monster
            }else{
                self.monsters[id] <-! create MonsterStat()
                return (&self.monsters[id])!
            }
        }

        access(all) view fun getMonsterStat(_ index:UInt64):{String:AnyStruct} {
            let result:{String:AnyStruct} = {
                "win":0,
                "lose":0,
                "effectiveness":0
            }
            if let monster:&MonsterStat = &self.monsters[index] {
                result["win"] = monster.win
                result["lose"] = monster.lose
                result["effectiveness"] = monster.value
            }
            return  result
        }

        init() {
            self.monsters <- {}
        }
    }

    

    access(all) resource Manager {

        access(self) let monsters: @Monsters
        
        access(Mint) fun createChest(winner:Address,defeated:Address,type:String,monsterIndex:Int,gameId:String,hash:String,meta:{String:AnyStruct}): @{GameNFT.INFT} {
            let user = getAccount(winner)
            let winGamer =  user.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) ?? panic("Missing Gamer!")
            winGamer.setRank(victory: true)

            if type == "monster" {
                let progress = meta["level"] as! Int
                winGamer.setProgress(progress:progress + 1)
            }

            if type == "monster" || type == "avatar" {
                let victory = type == "avatar"
                let monster = self.monsters.getMonster(monsterIndex)
                monster.update(victory)
            }
            

            // TODO defeated gamer.setRank(victoty: false)

            let nft <- GameNFT.minter.mintMeta(category: "chest", type:type, meta: meta)
            emit createChestEvent(id:nft.id,winner:winner,type:type,gameId:gameId,hash:hash)
            return <- nft
        }

        access(Gamer) fun createGamer():@GameIdentity.Gamer {
            return <- GameIdentity.createGamer()
        }

        access(Name) fun setName(avatar:&GameNFT.MetaNFT,name:String) {
            if avatar.category == "avatar" {
                let meta = avatar.meta.build()
                if let currentName = meta["name"] as? String {
                    panic("Avatar has name! \(currentName)")
                }
                meta["name"] = name
                avatar.meta.update(meta)
                emit setAvatarName(id:avatar.id)
            }
        }

        access(Update) fun update(contentVersion:[String],auditVersion:[String],contents:{String:{String:AnyStruct}}) {
            GameContent.update(contentVersion:contentVersion,auditVersion:auditVersion,contents:contents)
        }

        access(GameEvent) fun setEvent(name:String){
            GameContent.setEvent(name)
        }

        access(StartBatch) fun startBatch(batch:{String:String}) {
            let deadLineWindow:UFix64 = 604800.0 // egy hét
            let block = getCurrentBlock()
            let claimDeadLine = UInt64(block.timestamp + deadLineWindow) * 1000
            let version = GameContent.currentVersion
            for id in batch.keys {
                // claim verifier létrehozása tárolása.
                emit startGameEvent(gameID:id,startHash:batch[id]!,contentVersion:version.content[0],auditVersion:version.audit[0],claimDeadLine:claimDeadLine)
            }
        }

        access(all) view fun getMonsterStat(_ index:UInt64): {String:AnyStruct} {
            return self.monsters.getMonsterStat(index)
        }

        init() {
            self.monsters <- create Monsters()
        }
    
    }

    access(all) view fun getMonsterStat(_ index: UInt64): {String: AnyStruct} {
        let manager = self.account
            .storage
            .borrow<&GameManager.Manager>(from: /storage/Manager)
            ?? panic("Missing Manager capability")

        return manager.getMonsterStat(index)
    }


    init() {
        let manager <- create Manager()
        self.account.storage.save(<- manager, to: /storage/Manager)
    }

}