import "SafeBox"

transaction() {

  let safeBoxAdminRef: &SafeBox.SafeBoxAdmin

  prepare(signer: &Account) {
    self.safeBoxAdminRef = signer.borrow<&SafeBox.SafeBoxAdmin>(from: SafeBox.AdminPath) ?? panic("Could not borrow reference to the owner's SafeBoxAdmin!")
  }

  execute {
    self.safeBoxAdminRef.unPause()
  }
}