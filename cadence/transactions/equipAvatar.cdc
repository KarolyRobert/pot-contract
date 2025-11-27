import "NonFungibleToken"
import "GameNFT"


transaction() {
    prepare(account: auth (BorrowValue) &Account) {

        let collection = account.storage.borrow<auth (GameNFT.Equip) &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection not public")
        //collection.setAvatarEquipment(avatarId:12,equipment:{"items":{"weapon":23},"spells":{1:34,0:54}})
        let avatar = collection.getAvatar(avatarId: 23)

    }

}