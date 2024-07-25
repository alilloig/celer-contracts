import "VolumeControl"

transaction(length: UInt64) {

  let volumeControlAdminRef: &VolumeControl.Admin

  prepare(signer: &Account) {
      self.volumeControlAdminRef = signer.borrow<&VolumeControl.Admin>(from: VolumeControl.AdminPath) ?? panic("Could not borrow reference to the owner's VolumeControlAdmin!")
  }

  execute {
    self.volumeControlAdminRef.setEpochLength(newLength: length)
  }
}