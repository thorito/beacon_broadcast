package pl.pszklarska.beaconbroadcast

import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import org.altbeacon.beacon.Beacon
import org.altbeacon.beacon.BeaconParser
import org.altbeacon.beacon.BeaconTransmitter
import org.altbeacon.beacon.BeaconTransmitter.checkTransmissionSupported

const val RADIUS_NETWORK_MANUFACTURER = 0x0118

class Beacon {

  private lateinit var context: Context
  private var beaconTransmitter: BeaconTransmitter? = null
  private var advertiseCallback: ((Boolean) -> Unit)? = null

  fun init(context: Context) {
    this.context = context
  }

  fun start(beaconData: BeaconData, advertiseCallback: ((Boolean) -> Unit)) {
    this.advertiseCallback = advertiseCallback

    if (isTransmissionSupported() == 0) {
      val beaconParser = BeaconParser().setBeaconLayout(beaconData.layout
          ?: BeaconParser.ALTBEACON_LAYOUT)
      beaconTransmitter = BeaconTransmitter(context, beaconParser)
    }

    val advertiseMode = beaconData.advertiseMode ?: 1

    val beacon = Beacon.Builder().apply {
      setId1(beaconData.uuid)
      if (beaconData.layout == BeaconParser.EDDYSTONE_UID_LAYOUT) {
        setId2(beaconData.identifier)
      } else {
        beaconData.majorId?.let { setId2(it.toString()) }
        beaconData.minorId?.let { setId3(it.toString()) }
      }
      setTxPower(beaconData.transmissionPower ?: -59)
      setDataFields(beaconData.extraData?.map { it.toLong() } ?: listOf(0L))
      setManufacturer(beaconData.manufacturerId ?: RADIUS_NETWORK_MANUFACTURER)
    }.build()

    beaconTransmitter?.advertiseMode = advertiseMode

    beaconTransmitter?.startAdvertising(beacon, object : AdvertiseCallback() {
      override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
        super.onStartSuccess(settingsInEffect)
        advertiseCallback(true)
      }

      override fun onStartFailure(errorCode: Int) {
        super.onStartFailure(errorCode)
        advertiseCallback(false)
      }
    })
  }

  fun isAdvertising(): Boolean {
    return beaconTransmitter?.isStarted ?: false
  }

  fun isTransmissionSupported(): Int {
    return checkTransmissionSupported(context)
  }

  fun stop() {
    beaconTransmitter?.stopAdvertising()
    advertiseCallback?.invoke(false)
  }

}