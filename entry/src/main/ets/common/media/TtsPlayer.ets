import { textToSpeech } from '@kit.CoreSpeechKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { appStore } from '../../store/AppStore'

const MAX_CHUNK_LEN: number = 10000

let ttsEngine: textToSpeech.TextToSpeechEngine | null = null
let engineReady: boolean = false
let enginePerson: number = -1
let pendingChunks: string[] = []
let chunkIndex: number = 0
let speakingPid: number = -1

function splitText(text: string): string[] {
  if (text.length <= MAX_CHUNK_LEN) {
    return [text]
  }
  const chunks: string[] = []
  let start: number = 0
  while (start < text.length) {
    if (start + MAX_CHUNK_LEN >= text.length) {
      chunks.push(text.substring(start))
      break
    }
    let cutPos: number = start + MAX_CHUNK_LEN
    let searchStart: number = start + MAX_CHUNK_LEN
    if (searchStart > text.length) {
      searchStart = text.length
    }
    for (let i = searchStart; i > start; i--) {
      const ch: string = text.charAt(i)
      if (ch === '\n' || ch === '。' || ch === '！' || ch === '？' || ch === '；' || ch === '.' || ch === '!' || ch === '?') {
        cutPos = i + 1
        break
      }
    }
    chunks.push(text.substring(start, cutPos))
    start = cutPos
  }
  return chunks
}

function initEngine(): void {
  const requestedPerson: number = appStore.settings.ttsPerson
  const extraParams: Record<string, Object> = {
    'style': 'interaction-broadcast',
    'locate': 'CN'
  }
  const initParams: textToSpeech.CreateEngineParams = {
    language: 'zh-CN',
    online: 1,
    person: requestedPerson,
    extraParams: extraParams
  }
  try {
    textToSpeech.createEngine(initParams, (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
      if (err) {
        if (err.code === 1002300003 || err.code === 1002300005) {
          appStore.showToast('音色未下载，请在设置中下载后使用')
        } else {
          appStore.showToast('语音引擎不可用')
        }
        return
      }
      ttsEngine = engine
      engineReady = true
      enginePerson = requestedPerson
      engine.setListener({
        onStart(requestId: string, response: textToSpeech.StartResponse) {
          appStore.showToast('正在朗读')
        },
        onComplete(requestId: string, response: textToSpeech.CompleteResponse) {
          if (response.type === 1) {
            playNextChunk()
          }
        },
        onStop(requestId: string, response: textToSpeech.StopResponse) {
          speakingPid = -1
          pendingChunks = []
          chunkIndex = 0
        },
        onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {
        },
        onError(requestId: string, errorCode: number, errorMessage: string) {
          speakingPid = -1
          pendingChunks = []
          chunkIndex = 0
          if (errorCode === 1002300007) {
            engineReady = false
            enginePerson = -1
            ttsEngine = null
          }
          appStore.showToast('朗读出错')
        }
      })
      if (pendingChunks.length > 0) {
        playNextChunk()
      }
    })
  } catch (e) {
    appStore.showToast('语音引擎不可用')
  }
}

function doSpeak(text: string): void {
  if (!ttsEngine) {
    return
  }
  const extraParams: Record<string, Object> = {
    'queueMode': 1,
    'speed': appStore.settings.ttsSpeed,
    'volume': appStore.settings.ttsVolume,
    'pitch': appStore.settings.ttsPitch,
    'languageContext': 'zh-CN',
    'audioType': 'pcm',
    'soundChannel': 3,
    'playType': 1
  }
  const speakParams: textToSpeech.SpeakParams = {
    requestId: Date.now().toString(),
    extraParams: extraParams
  }
  try {
    ttsEngine.speak(text, speakParams)
  } catch (e) {
  }
}

function playNextChunk(): void {
  if (chunkIndex < pendingChunks.length) {
    doSpeak(pendingChunks[chunkIndex])
    chunkIndex++
  } else {
    speakingPid = -1
    pendingChunks = []
    chunkIndex = 0
  }
}

function stopInternal(): void {
  speakingPid = -1
  pendingChunks = []
  chunkIndex = 0
  try {
    if (ttsEngine && ttsEngine.isBusy()) {
      ttsEngine.stop()
    }
  } catch (e) {
  }
}

export class TtsPlayer {
  static speak(text: string, pid: number): void {
    if (speakingPid === pid) {
      stopInternal()
      return
    }
    if (engineReady && appStore.settings.ttsPerson !== enginePerson) {
      try {
        ttsEngine?.shutdown()
      } catch (e) {
      }
      ttsEngine = null
      engineReady = false
    }
    stopInternal()
    speakingPid = pid
    pendingChunks = splitText(text)
    chunkIndex = 0
    if (!engineReady) {
      initEngine()
      return
    }
    playNextChunk()
  }

  static isSpeaking(pid: number): boolean {
    return speakingPid === pid
  }

  static stop(): void {
    stopInternal()
  }

  static shutdown(): void {
    stopInternal()
    try {
      ttsEngine?.shutdown()
    } catch (e) {
    }
    ttsEngine = null
    engineReady = false
    enginePerson = -1
  }
}
