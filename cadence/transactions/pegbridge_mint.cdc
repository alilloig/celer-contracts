import "cBridge"
import "PegBridge"

// Is send [cBridge.SignerSig] instead of {String: String} better ? (for example: it will saving gas cost?)
// As cadence do not support custom type in go sdk well, let's try using [cBridge.SignerSig] in future.
transaction(msg: [UInt8], tokenId: String, pubKeySigs: [[UInt8]]) {
  prepare(signer: &Account) {}

  execute {
    let sigs :[cBridge.SignerSig] = []
    for sig in pubKeySigs {
      let bridgeSig = cBridge.SignerSig(sig: sig)
      sigs.append(bridgeSig)
    }
    PegBridge.mint(token: tokenId, pbmsg: msg, sigs: sigs)
  }
}