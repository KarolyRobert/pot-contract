import Test

access(all) let account = Test.createAccount()


access(all) fun setup() {
    var err = Test.deployContract(
        name: "Xorshift128plus",
        path: "../contracts/utils/Xorshift128plus.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "RandomConsumer",
        path: "../contracts/utils/RandomConsumer.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "Random",
        path: "../contracts/utils/Random.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "GameNFT",
        path: "../contracts/GameNFT.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    err = Test.deployContract(
        name: "GameContent",
        path: "../contracts/GameContent.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    err = Test.deployContract(
        name: "Meta",
        path: "../contracts/utils/Meta.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    err = Test.deployContract(
        name: "GameManager",
        path: "../contracts/GameManager.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "Avatar",
        path: "../contracts/nft/Avatar.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())

   // let tx = Test.addTransaction(tx)

    let admin = Test.getAccount(0x0000000000000007)

    let tx = Test.Transaction(code:"import \"GameManager\"; transaction(cVersion:[String],aVersion:[String],contents:{String:{String:AnyStruct}}) {prepare(admin: auth (Storage, BorrowValue )  &Account) {let manager = admin.storage.borrow< auth (GameManager.Update) &GameManager.Manager>(from:/storage/Manager) ?? panic(\"Only the owner can call this function\");manager.update(contentVersion:cVersion,auditVersion:aVersion,contents:contents)}execute {}}",
        authorizers:[admin.address],signers:[admin],arguments:[["0.1","asda"],["0.1","sdfdf"],{"avatars":{"lala":{"class":"warrior"},"rofi":{"class":"mage"},"rudi":{"class":"archer"},"tata":{"class":"warrior"}},"skills":{"baray":{"class":"warrior"},"fireball":{"class":"mage"},"gedam":{"class":"warrior"},"jaki":{"class":"mage"},"mind":{"class":"mage"},"suki":{"class":"archer"},"sung":{"class":"archer"}},"aids":{"copper":{"zone":0},"iron":{"zone":0},"lether":{"zone":3},"stone":{"zone":1},"wood":{"zone":0}},"spells":{"firefing":"","kobold":"","mano":"","mindgeri":""},"items":{"guitar":{"type":"weapon"},"kard":{"type":"weapon"},"zubi":{"type":"clothes"}},"events":{"default":{"lootChance":[0.25,0.15,0.6],"lootCount":10},"kanaan":{"lootChance":[0.35,0.15,0.5],"lootCount":50}}}])
    
    // "import \"GameManager\" transaction(cVersion:[String],aVersion:[String],contents:{String:{String:AnyStruct}}) {prepare(admin: auth (Storage, BorrowValue )  &Account) {let manager = admin.storage.borrow< auth (GameManager.Update) &GameManager.Manager>(from:/storage/Manager) ?? panic(\"Only the owner can call this function\")manager.update(contentVersion:cVersion,auditVersion:aVersion,contents:contents)}execute {}}"
    let result = Test.executeTransaction(tx)
    Test.expect(result.error, Test.beNil())
}   


access(all) fun testContract() {
  

    let result = Test.executeScript("import \"GameContent\";access(all) fun main(): &GameContent.Version {return GameContent.currentVersion}",[])
    log(result.returnValue)
    //Test.expect(result, Test.beSucceeded())


    
    

}