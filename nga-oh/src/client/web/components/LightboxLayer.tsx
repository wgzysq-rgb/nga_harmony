import { useState, useEffect, useRef, useCallback } from 'react'
import { createPortal } from 'react-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useUiStore } from '@/stores/ui'

function LightboxInner({ urls, initialIndex, onClose }: {
  urls: string[]
  initialIndex: number
  onClose: () => void
}) {
  const [index, setIndex] = useState(initialIndex)
  const touchStartX = useRef(0)

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
      if (e.key === 'ArrowLeft') setIndex((i) => (i - 1 + urls.length) % urls.length)
      if (e.key === 'ArrowRight') setIndex((i) => (i + 1) % urls.length)
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [urls.length, onClose])

  const goPrev = useCallback(() => setIndex((i) => (i - 1 + urls.length) % urls.length), [urls.length])
  const goNext = useCallback(() => setIndex((i) => (i + 1) % urls.length), [urls.length])

  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX
  }, [])

  const handleTouchEnd = useCallback((e: React.TouchEvent) => {
    const dx = e.changedTouches[0].clientX - touchStartX.current
    if (Math.abs(dx) > 50) {
      if (dx > 0) goPrev()
      else goNext()
    }
  }, [goPrev, goNext])

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[60] bg-black/95 flex items-center justify-center"
      onClick={onClose}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
    >
      <button
        className="absolute top-4 right-4 z-10 w-8 h-8 flex items-center justify-center rounded-full bg-white/10"
        onClick={(e) => { e.stopPropagation(); onClose() }}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
          <line x1="18" y1="6" x2="6" y2="18" />
          <line x1="6" y1="6" x2="18" y2="18" />
        </svg>
      </button>

      {urls.length > 1 && (
        <>
          <button
            className="absolute left-3 top-1/2 -translate-y-1/2 z-10 w-10 h-10 flex items-center justify-center rounded-full bg-white/10 active:bg-white/20 transition-colors"
            onClick={(e) => { e.stopPropagation(); goPrev() }}
          >
            <ChevronLeft size={24} className="text-white" />
          </button>
          <button
            className="absolute right-3 top-1/2 -translate-y-1/2 z-10 w-10 h-10 flex items-center justify-center rounded-full bg-white/10 active:bg-white/20 transition-colors"
            onClick={(e) => { e.stopPropagation(); goNext() }}
          >
            <ChevronRight size={24} className="text-white" />
          </button>
        </>
      )}

      <AnimatePresence mode="wait">
        <motion.img
          key={`${index}-${urls[index]}`}
          initial={{ opacity: 0, scale: 0.92 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.92 }}
          transition={{ duration: 0.15 }}
          src={urls[index]}
          alt=""
          className="max-w-[95vw] max-h-[90vh] object-contain"
          onClick={(e) => e.stopPropagation()}
        />
      </AnimatePresence>

      {urls.length > 1 && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 text-white/70 text-[14px] select-none">
          {index + 1} / {urls.length}
        </div>
      )}
    </motion.div>
  )
}

export default function LightboxLayer() {
  const lightbox = useUiStore((s) => s.lightbox)
  const closeLightbox = useUiStore((s) => s.closeLightbox)

  if (typeof document === 'undefined') return null

  return createPortal(
    <AnimatePresence>
      {lightbox && (
        <LightboxInner
          key={lightbox.urls.join(',')}
          urls={lightbox.urls}
          initialIndex={lightbox.index}
          onClose={closeLightbox}
        />
      )}
    </AnimatePresence>,
    document.body
  )
}
