import "FTMinterBurner"
import "PegBridge"
import "ceMATIC"

transaction(contractAddr: Address) {

  let ftMinterMapRef: &{PegBridge.IAddMinter}
  let ftBurnerMapRef: &{PegBridge.IAddBurner}
  let tokenAdmin: &ceMATIC.Administrator

  prepare(signer: auth(Storage) &Account) {
      self.ftMinterMapRef = getAccount(contractAddr).capabilities.get(/public/AddMinter).borrow<&{PegBridge.IAddMinter}>() ?? panic("Could not borrow reference to the owner's ftMinterMapRef!")
      self.ftBurnerMapRef = getAccount(contractAddr).capabilities.get(/public/AddBurner).borrow<&{PegBridge.IAddBurner}>() ?? panic("Could not borrow reference to the owner's ftBurnerMapRef!")
  
      //self.tokenAdmin = signer.capabilities.borrow<&ceMATIC.Administrator>(ceMATIC.AdminPublicPath) ?? panic("Could not borrow reference to the owner's PegBridgeAdmin!")
      self.tokenAdmin = signer.storage.borrow<&ceMATIC.Administrator>(from: ceMATIC.AdminPath) ?? panic("Could not borrow reference to the owner's PegBridgeAdmin!")
  
  }

  execute {
    let minter <- self.tokenAdmin.createNewMinter(allowedAmount: 10000000000.0)
    let burner <- self.tokenAdmin.createNewBurner()
    self.ftMinterMapRef.addMinter(minter: <- minter)
    self.ftBurnerMapRef.addBurner(burner: <- burner)
  }
}