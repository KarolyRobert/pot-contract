import "Upgrade"
import "GameNFT"
import "GameToken"
import "Random"
import "NonFungibleToken"

// flow transactions send cadence/transactions/revealItem.cdc --signer user1 --network emulator
transaction() {
    prepare(signer: auth(BorrowValue, LoadValue) &Account) {

        let receipt <- signer.storage.load<@Upgrade.Receipt>(from:Random.ReceiptStoragePath) ?? panic("No Receipt found in storage at path=".concat(Random.ReceiptStoragePath.toString()))

       // let request <-receipt.popRequest()
       // destroy request
        let loot <- Upgrade.revealUpgrade(receipt: <-receipt)

        while loot.length > 0 {
            let token <- loot.removeFirst()
            if let nft <- token as? @{GameNFT.INFT} {
            log(nft.getData())
            destroy  nft
            }else if let fabatka <- token as? @GameToken.Fabatka {
                log(fabatka.balance)
                destroy fabatka
            }else{
                destroy token
            }
        }
        destroy loot

    }

    execute {}
}