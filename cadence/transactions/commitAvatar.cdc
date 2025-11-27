import "GameManager"
import "GameNFT"
import "Avatar"
import "Random"

// flow transactions send cadence/transactions/commitAvatar.cdc --authorizer user1,emulator-account --payer user1 --proposer emulator-account --network emulator 

transaction() {
    prepare(user: auth ( SaveValue ) &Account, admin: auth ( BorrowValue) &Account) {

        let manager = admin.storage.borrow< auth (GameManager.Mint) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")


        let avatar <- manager.test(category:"avatar",type:"jani",meta:{
            "level":50,
            "class":"warrior",
            "subClass":"Scholar",
            "skills":[{"type":"gedam","level":1},{"type":"baray","level":0},{"type":"kaki","level":0},{"type":"fifu","level":0}]
        })
        let sacrifice <- manager.test(category:"avatar",type:"jozef",meta:{
            "level":0,
            "class":"mage",
            "subClass":"Scholar",
            "skills":[{"type":"fafu","level":1},{"type":"mind","level":0},{"type":"fufu","level":0},{"type":"fifu","level":0}]
        })

        let receipt <- Avatar.commitUpgrade(avatar: <- avatar, sacrifice: <- sacrifice, options:[0])

        user.storage.save(<- receipt,to:Random.ReceiptStoragePath)
    }

    execute {}
}

/*
 gedam:{
        class:"warrior"
    },
    baray:{
        class:"warrior"
    },
    jaki:{
        class:"mage"
    },
    kaki:{
        class:"warrior"
    },
    suki:{
        class:"archer"
    },
    fireball:{
        class:"mage"
    },
    sung:{
        class:"archer"
    },
    mind:{
        class:"mage"
    },
    fafu:{
        class:"Scholar"
    },
    fifu:{
        class:"Scholar"
    },
    fufu:{
        class:"Scholar"
    }
 */