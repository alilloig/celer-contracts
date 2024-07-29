import "VolumeControl"

transaction(length: UInt64) {

  let volumeControlAdminRef: &VolumeControl.Admin

  prepare(signer: auth(Storage) &Account) {
      self.volumeControlAdminRef = signer.storage.borrow<&VolumeControl.Admin>(from: VolumeControl.AdminPath) ?? panic("Could not borrow reference to the owner's VolumeControlAdmin!")
  }

  execute {
    self.volumeControlAdminRef.setEpochLength(newLength: length)
  }
}