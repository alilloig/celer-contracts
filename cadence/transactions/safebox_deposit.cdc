import "FungibleToken"
import "SafeBox"

    transaction() {
      let provRef: &{FungibleToken.Provider}

      prepare(acct: &Account) {
        self.provRef = acct.borrow<&{FungibleToken.Provider}>(from: /storage/USDCVault) ?? panic("Could not borrow a reference to the owner's vault")
      }

      execute {
        let depoInfo = SafeBox.DepoInfo(amt: UFix64(39963.66261962), mintChId: 1, mintAddr: "0x9b985d7A12A1CB5550Fe2990b6e9a51FE25d7D5F", nonce: 1721868804159)
        SafeBox.deposit(from: self.provRef, info: depoInfo)
      }
    }