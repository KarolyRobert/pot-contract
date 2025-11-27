import "GameManager"
import "GameNFT"

transaction {

/* 
    flow transactions send cadence/transactions/MintChest.cdc --authorizer user1,emulator-account --payer user1 --proposer emulator-account --network emulator 
    multisig tranzakciónál az emulátor hibát dob, ha a payer és a propopser azonos.
*/

    let manager: auth (GameManager.Mint) &GameManager.Manager
    let collection:&GameNFT.Collection
    let winner:Address

    prepare(user: auth (BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account, admin: auth (Storage, BorrowValue ) &Account) {
  
        self.manager = admin.storage.borrow< auth (GameManager.Mint) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")
        self.winner = user.address
        log("usercollection:")
        log(user)
        self.collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Nincs collection")
        

    }

    execute {
        let nft <- self.manager.createChest(winner:self.winner,type:"pvp",gameId:"bbbbbbbbbbbb",hash:"qwert",meta:{"level":10,"wLevel":2,"event":"default","class":"elit"}) as! @GameNFT.MetaNFT
        log(nft.getData())
        self.collection.deposit(token: <- nft)
    }

}