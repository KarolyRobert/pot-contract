import "GameManager"
import "GameNFT"
import "GameIdentity"

transaction(avatarID:UInt64,name:String,isMain:Bool) {

    let manager: auth (GameManager.Name) &GameManager.Manager
    let avatar:&GameNFT.MetaNFT
    let gamer:auth (GameIdentity.Update) &GameIdentity.Gamer

    prepare(user: auth (BorrowValue ) &Account, admin: auth ( BorrowValue ) &Account) {
       
        self.manager = admin.storage.borrow< auth (GameManager.Name) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")
        let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Missing colection!")
        self.avatar = collection.borrowNFT(avatarID) as? &GameNFT.MetaNFT ?? panic("Not a metaNFT")
        self.gamer = user.storage.borrow<auth (GameIdentity.Update) &GameIdentity.Gamer>(from:GameIdentity.GamerStoragePath) ?? panic("Missing idenity!")

    }

    execute {
        self.manager.setName(avatar: self.avatar, name: name)
        if(isMain){
            self.gamer.setAvatar(avatarID)
        }
    }
}