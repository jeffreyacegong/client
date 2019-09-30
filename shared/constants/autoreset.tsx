import {formatDurationForAutoreset as formatDuration} from '../util/timestamp'

export const waitingKeyCancelReset = 'autoreset:cancelWaitingKey'

export const formatTimeLeft = (endTime: number) => {
  return formatDuration(endTime - Date.now())
}
