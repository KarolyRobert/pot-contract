import "GameNFT"

transaction(avatar:UInt64,charm:UInt64,items:{String:UInt64},spells:{Int:UInt64}) {

    

    prepare(user: auth(BorrowValue) &Account) {
        
        let collection =  user.storage.borrow<auth (GameNFT.Equip)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        collection.setAvatarEquipment(avatarId: avatar, equipment:{"charm":charm,"items":items,"spells":spells})
    
    }
}