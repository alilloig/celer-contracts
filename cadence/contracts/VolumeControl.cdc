access(all) contract VolumeControl {


  access(all) let AdminPath: StoragePath
  // ========== events ==========
  access(all) event EpochLengthUpdated(length: UInt64)

  access(all) var epochLength: UInt64 // seconds, how soon the volume in last window will be clear
  access(account) var epochVolumes: {String: UFix64} // the sum volume in last time window
  access(account) var lastOpTimestamps: {String: UInt64}  // unix seconds, the last time window record the volume

  // ========== admin resource ==========
  access(all) resource Admin {
    access(all) fun setEpochLength(newLength: UInt64) {
      VolumeControl.epochLength = newLength
      emit EpochLengthUpdated(
        length: newLength
      )
    }

    // createNewAdmin creates a new Admin resource
    access(all) fun createNewAdmin(): @Admin {
      return <-create Admin()
    }
  }

  // ========== functions ==========
  init() {
    self.epochLength = 0
    self.epochVolumes = {}
    self.lastOpTimestamps = {}
    self.AdminPath = /storage/VolumeControlAdmin
    self.account.storage.save<@Admin>(<- create Admin(), to: self.AdminPath)
  }

  access(account) fun updateVolume(token: String, amt: UFix64, cap: UFix64) {
    if self.epochLength == 0 {
      return
    }
    if cap == 0.0 {
      return
    }
    var volume = self.epochVolumes[token] ?? 0.0
    let timestamp = UInt64(getCurrentBlock().timestamp)
    let epochStartTime = (timestamp / self.epochLength) * self.epochLength;
    let lastOpTimestamp = self.lastOpTimestamps[token] ?? 0
    if (lastOpTimestamp < epochStartTime) {
       volume = amt
    } else {
       volume = volume + amt;
    }
    assert(volume <= cap, message: "volume exceeds cap")
    self.epochVolumes[token] = volume;
    self.lastOpTimestamps[token] = timestamp;
  }

  access(all) view fun getEpochVolume(token: String): UFix64 {
    return self.epochVolumes[token] ?? 0.0
  }

  access(all) view fun getLastOpTimestamp(token: String): UInt64 {
    return self.lastOpTimestamps[token] ?? 0
  }
}