import "DelayedTransfer"

transaction(delayPeriod: UInt64) {

  let delayedTransferAdminRef: &DelayedTransfer.Admin

  prepare(signer: &Account) {
      self.delayedTransferAdminRef = signer.borrow<&DelayedTransfer.Admin>(from: DelayedTransfer.AdminPath) ?? panic("Could not borrow reference to the owner's DelayedTransferAdmin!")
  }

  execute {
    self.delayedTransferAdminRef.setDelayPeriod(newP: delayPeriod)
  }
}