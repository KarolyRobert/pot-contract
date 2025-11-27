import "GameManager"
import "GameContent"
import "Utils"
import "GameNFT"
import "Upgrade"
import "Random"

// flow transactions send cadence/transactions/commitItem.cdc --authorizer user1,emulator-account --payer user1 --proposer emulator-account --network emulator 

transaction() {
    prepare(user: auth ( SaveValue ) &Account, admin: auth ( BorrowValue) &Account) {

        let manager = admin.storage.borrow< auth (GameManager.Mint) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")


        let item <- manager.test(category:"item",type:"kard",meta:{
            "level":5,
            "quality":"common",
            "zone":0,
            "needs":["copper"]
        })

        let consts = GameContent.getConsts()
    
        let needPrice = Utils.getPrice(category:"item", level:5, quality:"common", Consts: consts)

        let fab <- manager.fabatka(balance: needPrice - 0.0)

        let aids:@[{GameNFT.INFT}] <- []
        //let aid <- manager.testBase(category:"aid",type:"copper")
        let uniq <- manager.testBase(category: "uniq", type: "trogaris")
        //aids.append(<- aid)
        let receipt <- Upgrade.commitUpgrade(unit: <- item,needs: <- aids,uniq: <- uniq,price:<-fab)

        user.storage.save(<- receipt,to:Random.ReceiptStoragePath)
    }

    execute {}
}