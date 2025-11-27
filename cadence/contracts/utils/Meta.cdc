access(all) contract Meta {


    access(all) struct MetaBuilder {
        access(self) var data:{String:AnyStruct}
       /* 
        access(account) fun str(_ key:String,_ value:String): MetaBuilder {
            self.data[key] = value
            return self
        }
        access(account) fun int(_ key:String,_ value:Int): MetaBuilder {
            self.data[key] = value
            return self
        }
        access(account) fun astr(_ key:String,_ value:[String]): MetaBuilder {
            self.data[key] = value
            return self
        }
        access(account) fun aint(_ key:String,_ value:[Int]): MetaBuilder {
            self.data[key] = value
            return self
        }
        access(account) fun astruct(_ key:String,_ value:[AnyStruct]): MetaBuilder {
            self.data[key] = value
            return self
        }
        access(account) fun Meta(_ key:String,_ value:{String:AnyStruct}): MetaBuilder {
            self.data[key] = value
            return self
        }
        */
        access(account) fun update(_ meta:{String:AnyStruct}){
            self.data = meta
        }
        access(account) view fun build():{String:AnyStruct} {
            return self.data
        }
        init(_ data:{String:AnyStruct}){
            self.data = data
        }
    }

    init() {}
}