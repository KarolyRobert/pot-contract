import "GameManager"

transaction(batch:{String:String}) {

    let manager: auth (GameManager.StartBatch) &GameManager.Manager

    prepare(admin: auth (Storage, BorrowValue ) &Account) {
        self.manager = admin.storage.borrow< auth (GameManager.StartBatch) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")
    }

    execute {
        self.manager.startBatch(batch: batch)
    }

}