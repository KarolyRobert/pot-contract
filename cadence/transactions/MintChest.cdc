import "GameManager"
import "GameIdentity"
import "GameNFT"

transaction {

/* 
    flow transactions send cadence/transactions/MintChest.cdc --authorizer user1,emulator-account --payer user1 --proposer emulator-account --network emulator 
    multisig tranzakciónál az emulátor hibát dob, ha a payer és a propopser azonos.
*/

    let manager: auth (GameManager.Mint,GameManager.Gamer) &GameManager.Manager
    let collection:&GameNFT.Collection
    let winner:Address

    prepare(user: auth (BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account, admin: auth (Storage, BorrowValue ) &Account) {
  
        self.manager = admin.storage.borrow< auth (GameManager.Mint, GameManager.Gamer) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")
        self.winner = user.address
        log("usercollection:")
        log(user)
        self.collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Nincs collection")

        if let gamer = user.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) {

        }else{
            let gamer <- self.manager.createGamer()
            user.storage.save(<- gamer, to:GameIdentity.GamerStoragePath)
            let gamerCap = user.capabilities.storage.issue<&GameIdentity.Gamer>(GameIdentity.GamerStoragePath)
            user.capabilities.publish(gamerCap, at: GameIdentity.GamerPublicPath)
        }
        
    }

    execute {
        let nft <- self.manager.createChest(winner:self.winner,defeated:self.winner,type:"pvp",gameId:"bbbbbbbbbbbb",hash:"qwert",meta:{"level":10,"wLevel":2,"event":"default","class":"elit"}) as! @GameNFT.MetaNFT
        log(nft.getData())
        self.collection.deposit(token: <- nft)
    }

}