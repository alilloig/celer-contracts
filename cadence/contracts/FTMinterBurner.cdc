/// Support FT minter/burner, minimal interfaces
/// do we want mintToAccount?
import "FungibleToken"

access(all) contract interface FTMinterBurner {

  access(all) resource interface IMinter {
    // only define func for PegBridge to call, allowedAmount isn't strictly required
    access(all) fun mintTokens(amount: UFix64): @{FungibleToken.Vault}
  }
  access(all) resource interface IBurner {
    access(all) fun burnTokens(from: @{FungibleToken.Vault})
  }

  access(all) resource interface Minter: IMinter {
  }
  access(all) resource interface Burner: IBurner {
  }
}