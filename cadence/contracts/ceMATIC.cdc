/// Canonical ceMATIC on Flow
import "FungibleToken"
import "FungibleTokenMetadataViews"
import "FTMinterBurner"

access(all) contract ceMATIC: FungibleToken, FTMinterBurner {
    // path for admin resource
    access(all) let AdminPath: StoragePath
    /// Total supply of tokens in existence, initial 0, and increase when new tokens are minted
    access(all) var totalSupply: UFix64

    /// TokensInitialized
    ///
    /// The event that is emitted when the contract is created
    access(all) event TokensInitialized(initialSupply: UFix64)

    /// TokensWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a Vault
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)

    /// TokensDeposited
    ///
    /// The event that is emitted when tokens are deposited to a Vault
    access(all) event TokensDeposited(amount: UFix64, to: Address?)

    /// TokensMinted
    ///
    /// The event that is emitted when new tokens are minted
    access(all) event TokensMinted(amount: UFix64)

    /// TokensBurned
    ///
    /// The event that is emitted when tokens are destroyed
    access(all) event TokensBurned(amount: UFix64)

    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    access(all) event MinterCreated(allowedAmount: UFix64)

    /// BurnerCreated
    ///
    /// The event that is emitted when a new burner resource is created
    access(all) event BurnerCreated()

    /// Vault
    ///
    /// Each user stores an instance of only the Vault in their storage
    /// The functions in the Vault and governed by the pre and post conditions
    /// in FungibleToken when they are called.
    /// The checks happen at runtime whenever a function is called.
    ///
    /// Resources can only be created in the context of the contract that they
    /// are defined in, so there is no way for a malicious user to create Vaults
    /// out of thin air. A special Minter resource needs to be defined to mint
    /// new tokens.
    ///
    access(all) resource Vault: FungibleToken.Vault {

        /// The total balance of this vault
        access(all) var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        /// withdraw
        ///
        /// Function that takes an amount as an argument
        /// and withdraws that amount from the Vault.
        ///
        /// It creates a new temporary Vault that is used to hold
        /// the money that is being transferred. It returns the newly
        /// created Vault to the context that called so it can be deposited
        /// elsewhere.
        ///
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        /// deposit
        ///
        /// Function that takes a Vault object as an argument and adds
        /// its balance to the balance of the owners Vault.
        ///
        /// It is allowed to destroy the sent Vault because the Vault
        /// was a temporary holder of the tokens. The Vault's balance has
        /// been consumed and therefore can be destroyed.
        ///
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @ceMATIC.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        /// Called when a fungible token is burned via the `Burner.burn()` method
        access(contract) fun burnCallback() {
            if self.balance > 0.0 {
                ceMATIC.totalSupply = ceMATIC.totalSupply - self.balance
                self.balance = 0.0
            }
        }
    
        access(all) view fun getViews(): [Type] {
            return ceMATIC.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return ceMATIC.resolveContractView(resourceType: nil, viewType: view)
        }

        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return amount <= self.balance
        }

        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            return <-create Vault(balance: 0.0)
        }
}

    /// createEmptyVault
    ///
    /// Function that creates a new Vault with a balance of zero
    /// and returns it to the calling context. A user must call this function
    /// and store the returned Vault in their storage in order to allow their
    /// account to be able to receive deposits of this token type.
    ///
    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <-create Vault(balance: 0.0)
    }

    access(all) resource Administrator {

        /// createNewMinter
        ///
        /// Function that creates and returns a new minter resource
        ///
        access(all) fun createNewMinter(allowedAmount: UFix64): @{FTMinterBurner.Minter} {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        /// createNewBurner
        ///
        /// Function that creates and returns a new burner resource
        ///
        access(all) fun createNewBurner(): @{FTMinterBurner.Burner} {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    /// Minter
    ///
    /// Resource object that token admin accounts can hold to mint new tokens.
    ///
    access(all) resource Minter: FTMinterBurner.Minter {

        /// The amount of tokens that the minter is allowed to mint
        access(all) var allowedAmount: UFix64

        /// mintTokens
        ///
        /// Function that mints new tokens, adds them to the total supply,
        /// and returns them to the calling context.
        ///
        access(all) fun mintTokens(amount: UFix64): @{FungibleToken.Vault} {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            ceMATIC.totalSupply = ceMATIC.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    /// Burner
    ///
    /// Resource object that token admin accounts can hold to burn tokens.
    ///
    access(all) resource Burner: FTMinterBurner.Burner {

        /// burnTokens
        ///
        /// Function that destroys a Vault instance, effectively burning the tokens.
        ///
        /// Note: the burned tokens are automatically subtracted from the
        /// total supply in the Vault destructor.
        ///
        access(all) fun burnTokens(from: @{FungibleToken.Vault}) {
            let vault <- from as! @ceMATIC.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    init() {
        self.totalSupply = 0.0

        // account owner only has admin resource, no vault as tokens are only minted later
        let admin <- create Administrator()
        self.AdminPath = /storage/ceMATICAdmin
        self.account.storage.save(<-admin, to: self.AdminPath)

        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: self.totalSupply)
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [Type<FungibleTokenMetadataViews.FTVaultData>()]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: /storage/ceMATICVault,
                    receiverPath: /public/ceMATICVault,
                    metadataPath: /public/ceMATICReceiver,
                    receiverLinkedType: Type<&ceMATIC.Vault>(),
                    metadataLinkedType: Type<&ceMATIC.Vault>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-self.createEmptyVault(vaultType: Type<@ceMATIC.Vault>())
                    })
                )
        }
        return nil
    }
}