import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "DailyNeeds",
        path: "../contracts/DailyNeeds.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}