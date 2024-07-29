import "PegBridge"

transaction(mintId: String) {
  prepare(acct: &Account) {
  }

  execute {
    PegBridge.executeDelayedTransfer(mintId: mintId)
  }
}