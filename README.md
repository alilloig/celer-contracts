# cBridge on Flow Contracts
## How cBridge works
cBridge supports two token bridging models:
diagram and more details at [official doc](https://cbridge-docs.celer.network/introduction/canonical-token-bridge)
### Pool-based bridge model
This model is intended for tokens that have already been generated on different chains (e.g., USDT, USDC, ETH). When a token needs to be transferred between chain A and chain B, two liquidity pools need to be first created on chain A and chain B, respectively. The bridge rate is dynamically adjusted according to the balances of the two liquidity pools, using the StableSwap pricing curve.

### Canonical token bridge model (mint & burn).
This model is intended for the use case where a token has already been generated on chain A (e.g., Ethereum) but not yet on chain B (e.g., BSC) and bridging is needed between chain A and chain B as business grows (e.g., the dApp is launched on chain B). When a user transfers from chain A to chain B, the original token will be locked on chain A and an equal amount of pegged token will be minted and sent to the user on chain B. Reversely, when a user transfers from chain B to chain A, the pegged token will be burned on chain B and an equal amount of token will be sent back to the user on chain A.

### what is cBridge State Guardian Network (SGN)
SGN is a specialized Proof-of-Stake (PoS) chain that monitors all cBridge onchain events, validate and generate co-signed messages for onchain transactions.

Each node(also called validator or signer) in SGN has a voting power proportional to its stakes. **Simply put, the only way to withdraw fund from cBridge contract is to have a message co-signed by validators whose total power is more than 2/3 of total power.**

more details at [official doc](https://cbridge-docs.celer.network/introduction/sgn-and-cbridge)

## 1. Use Case
**In initial launch of cBridge on Flow only supports Canonical token bridge model (mint & burn).**

You can also find related the EVM contract from this [repo](https://github.com/celer-network/sgn-v2-contracts).

### cBridge EVM Asset to Flow
This is for an asset already has ERC20 token on EVM chains. The asset team needs to deploy PegToken.cdc as the canonical fungible token on Flow chain for the asset and give PegBridge the minter/burner resource.

(1) Deposit(Lock ERC20) into contract on EVM chain. -> Mint fungible token on flow chain by [PegBridge contract](https://github.com/celer-network/cbridge-flow/blob/main/contracts/PegBridge.cdc).

User deposit ERC20 asset on EVM chain into OriginalTokenVault or OriginalTokenVaultV2 solidity contract.

Once sgn monitor the deposit event on EVM chain, sgn will validate event, generate and cosign a mint fungible token message to the user on flow chain, and submit the onchain tx to [PegBridge contract](https://github.com/celer-network/cbridge-flow/blob/main/contracts/PegBridge.cdc).

(2) Burn fungible token into PegBridge contract on flow chain. -> Withdraw(Unlock ERC20) on EVM chain from contract.

User burn the fungible token into PegBridge contract.

Once sgn monitor and validate the burn event on flow chain, sgn will withdraw ERC20 asset to the user on EVM chain from contract.

Note all the burnable fungible tokens in this case are minted by (1).

### cBridge Flow Asset to EVM Asset
This is for an asset already has FungibleToken contract on Flow chain. The asset team needs to deploy [ERC20 contract](https://github.com/celer-network/sgn-v2-contracts/tree/main/contracts/pegged/tokens) on EVM chains.

(1) Deposit(Lock fungible token) into [SafeBox contract](https://github.com/celer-network/cbridge-flow/blob/main/contracts/SafeBox.cdc) on Flow chain. -> Mint ERC20 asset on EVM chain by contract.

User deposit fungible token on flow chain into SafeBox contract. Note our solidity contract name is OriginalTokenVault, we rename to SafeBox for flow to avoid confusion as Vault is a common term/resource for Flow fungible token.

Once sgn monitor the deposit event on Flow chain, sgn will mint ERC20 asset to the user on EVM chain by calling PeggedTokenBridge.sol contract.

(2) Burn(ERC20) on EVM chain into contract. -> Withdraw(Unlock fungible token) on Flow chain from [SafeBox contract](https://github.com/celer-network/cbridge-flow/blob/main/contracts/SafeBox.cdc).

User burn ERC20(minted from last step) on EVM chain by contract.

Once sgn monitor the burn event on EVM chain, sgn will withdraw fungible token to the user on Flow chain from SafeBox contract.

##2. All Contract Related(.cdc files in this directory)

### [Pb.cdc](https://github.com/celer-network/cbridge-flow/blob/main/contracts/Pb.cdc) / [PbPegged.cdc](https://github.com/celer-network/cbridge-flow/blob/main/contracts/PbPegged.cdc)

Pb.cdc and PbPegged.cdc is used for decode protobuf messages.

Pb.cdc define the method for decode protobuf bytes into different cadence type.

### [FTMinterBurner.cdc](https://github.com/celer-network/cbridge-flow/blob/main/contracts/FTMinterBurner.cdc)

The interface must be implemented by any token to be used with PegBridge. (if token is already deployed on Flow, it uses SafeBox and no need to support this)

The pegToken must implement [minter](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/FTMinterBurner.cdc#L14) and [burner](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/FTMinterBurner.cdc#L17), and give minter and burner to pegBridge contract.

So that, pegBridge can take control of mint and burn ft.

### [PegToken.cdc](https://github.com/celer-network/cbridge-flow/blob/main/contracts/PegToken.cdc)

Template fungible token contract to easily customize and deploy new fungible token contracts that work with PegBridge. Similar to [ERC20 tokens](https://github.com/celer-network/sgn-v2-contracts/tree/main/contracts/pegged/tokens)

Token admin needs to create minter/burner and save to PegBridge storage.

Note PegToken can create more than one minter resource and give to other bridge systems if needed. It's up to the token team to decide.

### [cBridge.cdc](https://github.com/celer-network/cbridge-flow/blob/main/contracts/cBridge.cdc)

cBridge contract will be supporting pool based model in the future. For now it is used for [saving signers](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/cBridge.cdc#L140) (public key with power) and [verify each sig](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/cBridge.cdc#L41).

Having signers related logic in bridge contract is to be compatible with existing cBridge systems.

#### Saving singers and powers.

We can update the signers by using func "resetSigners()" and "updateSigners()".

Only the owner who store the BridgeAdmin resource can using [resetSigners()](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/cBridge.cdc#L28) to set the signers and powers directly.

Also, we can use [updateSigners()](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/cBridge.cdc#L140) to do the same thing as resetSigners(). 

The difference is that if we use updateSigners(), sigs with more than [2/3 total power](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/cBridge.cdc#L43) is needed.

This ensures the system security that new signers/powers must be agreed by more than 2/3 power of existing signers.

#### Verify sigs

Out system security is based one sigs verify.

This func need two param, [sigs and data to sign](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/cBridge.cdc#L41).

For example, if we have four signers (four public key) in PbSignerPowerMap.

If each signer with power 1, which means the total power is 4.

Then, we should provide at least 3 sigs (from different signers) can reach power 3 [(> 2/3 total powers)](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/cBridge.cdc#L61).

### [SafeBox.cdc](https://github.com/celer-network/cbridge-flow/blob/main/contracts/SafeBox.cdc)

This contract works with existing fungible tokens on Flow and bridge to EVM chains.

#### Token config

To avoid unsupported tokens locked in contract storage(ie. user won't receive minted erc20), we have a map of allow fungible [token config](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/SafeBox.cdc#L32) save in [tokMap](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/SafeBox.cdc#L72)

#### Deposit

Only the account who have the [SafeBoxAdmin resource](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/SafeBox.cdc#L78) can be change the tokMap (add a config or remove a config).

When user deposits ft into the contract, the amount is transferred into contract's stored vault.
User on flow can lock the fungible token into this contract by using func [deposit()](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/SafeBox.cdc#L117).

The locked token is added into [the vault resource saved in the account storage](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/SafeBox.cdc#L134) which this contract belong to.

#### Withdraw

Withdraw is used to move token from contract to receiver. It's used when user burn ERC20 and expects to receive ft on flow, or mint erc20 failed due to eg. mint cap and user is getting refund (ie. deposited token back). In both cases, enough sigs from sgn validators are needed.

First, user burns the minted token on EVM chain.

Then sgn will verify the burn event, then collect enough sigs (with at least 2/3 total power) and call SafeBox withdraw.

When the func withdraw() receiver the tx from sgn, it will [check the sig is valid and enough](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/SafeBox.cdc#L155) with cBridge.cdc.

If the sigs are good, then contract will [withdraw the amt from the vault resource](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/SafeBox.cdc#L176) in this account and send it to the receiver.

### [PegBridge.cdc](https://github.com/celer-network/cbridge-flow/blob/main/contracts/PegBridge.cdc)

PegBridge is used to bridge ERC20 tokens to flow chain. It works with PegToken contract to mint/burn.

#### Token config

Only fungible [token config](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L34) save in [tokMap](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L73) can be used in this PegBridge contract.

This config map will work like a white list.

Each token should [give the minter and burner resource](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L121) to this contract, so that it can mint and burn token.

#### Mint

Mint can only called by sgn.

Once sgn confirm the deposit action on EVM chain, it will try to collect enough sigs(with at least 2/3 total power) from each sgn nodes.

After enough sigs is collected, sgn will call [mint func](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L189) of pegBridge contract.

When the func mint() receiver the tx from sgn, it will [check the sigs are valid](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L194) with cBridge.cdc.

If the sigs are good, then this contract will get the [minter resource](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L204) and use it to [mint vault resource](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L211) which will be added to the receiver.

#### Burn

Burn should be called by the user to transfer token from Flow to EVM chains.

Burn is done by calling func [burn()](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L226) of pegBridge contract.

After burn action is sealed on flow chain, sgn will monitor the event emitted, and call the contract on EVM chain to withdraw ERC20 to the receiver.

### [DelayedTransfer.cdc](https://github.com/celer-network/cbridge-flow/blob/main/contracts/DelayedTransfer.cdc)

This DelayedTransfer contract is used as a safeguard feature similar to a time-locked vault.

When the mint amount or the withdrawal amount exceeded the threshold configured for each token, SafeBox and pegBridge will not withdraw or mint fungible tokens immediately. Instead, it will call addDelayXfer which saves the vault and receiver for later release.

This contract provide a func [executeDelayXfer](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/DelayedTransfer.cdc#L87).

When executeDelayXfer is called, it will check whether the input id exist and enough time has passed. If both are true, the id will be [removed](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/DelayedTransfer.cdc#L96), and the vault resource will be [sent](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/DelayedTransfer.cdc#L101) to the receiver.

Both [SafeBox](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/SafeBox.cdc#L192) and [PegBridge](https://github.com/celer-network/cbridge-flow/blob/d09005b10c334cf39d932214e8651318c3cda954/contracts/PegBridge.cdc#L257) contract provide a pub func to executeDelayXfer
