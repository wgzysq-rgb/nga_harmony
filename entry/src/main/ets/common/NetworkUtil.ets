import { connection } from '@kit.NetworkKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN: number = 0x0000
const TAG: string = 'NetworkUtil'

export function isWifiConnected(): boolean {
  try {
    let netHandle: connection.NetHandle = connection.getDefaultNetSync()
    if (netHandle.netId === 0) {
      return false
    }
    let netCap: connection.NetCapabilities = connection.getNetCapabilitiesSync(netHandle)
    if (netCap.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
      return false
    }
    return true
  } catch (e) {
    hilog.warn(DOMAIN, TAG, 'isWifiConnected error: %{public}s', JSON.stringify(e))
    return true
  }
}
