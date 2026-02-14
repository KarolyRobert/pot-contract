import "GameManager"
import "GameNFT"
import "GameIdentity"

transaction(isFarmer:Bool,isRanked:Bool,isTrader:Bool) {

    let gamer:auth (GameIdentity.Update) &GameIdentity.Gamer

    prepare(user: auth (BorrowValue ) &Account) {
       
        self.gamer = user.storage.borrow<auth (GameIdentity.Update) &GameIdentity.Gamer>(from:GameIdentity.GamerStoragePath) ?? panic("Missing idenity!")

    }

    execute {
        let newView:{GameIdentity.IdentityView:Bool} = {}
        if isFarmer {
            newView[GameIdentity.IdentityView.farmer] = true
        }
        if isRanked {
            newView[GameIdentity.IdentityView.ranked] = true
        }
        if isTrader {
            newView[GameIdentity.IdentityView.trader] = true
        }
        self.gamer.setView(view: newView)
    }
}