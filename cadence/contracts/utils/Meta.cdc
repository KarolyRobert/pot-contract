access(all) contract Meta {


    access(all) struct MetaBuilder {
        access(self) var data:{String:AnyStruct}
    
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