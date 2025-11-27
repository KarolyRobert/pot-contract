import "Avatar"
import "GameNFT"
import "Random"
import "NonFungibleToken"

// flow transactions send cadence/transactions/revealAvatar.cdc --signer user1 --network emulator
transaction() {
    prepare(signer: auth(BorrowValue, LoadValue) &Account) {

        let receipt <- signer.storage.load<@Avatar.Receipt>(from:Random.ReceiptStoragePath) ?? panic("No Receipt found in storage at path=".concat(Random.ReceiptStoragePath.toString()))

       // let request <-receipt.popRequest()
       // destroy request
        let loot <- Avatar.revealUpgrade(receipt: <-receipt)

        while loot.length > 0 {
            let nft <- loot.removeFirst() as! @GameNFT.MetaNFT
            let metaValue = nft.meta
            log(nft.getData())
            destroy  nft
        }
        destroy loot

    }

    execute {}
}