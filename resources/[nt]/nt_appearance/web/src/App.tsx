import { useEffect, useRef, useState } from 'react'

function nuiFetch<T = unknown>(endpoint: string, data: object): Promise<T | null> {
  return fetch(`https://nt_appearance/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
    .then(r => r.json() as Promise<T>)
    .catch(() => null)
}

function App() {
  const [visible, setVisible]                   = useState(false)
  const [isDragging, setIsDragging]             = useState(false)
  const [isRightDragging, setIsRightDragging]   = useState(false)
  const [panelPosition, setPanelPosition]       = useState<'left' | 'right'>('right')
  const lastMouseRef = useRef({ x: 0, y: 0 })

  const handleMouseDown = (e: React.MouseEvent) => {
    if (e.button === 0) setIsDragging(true)
    if (e.button === 2) setIsRightDragging(true)
    lastMouseRef.current = { x: e.clientX, y: e.clientY }
  }

  const handleMouseUp = () => {
    setIsDragging(false)
    setIsRightDragging(false)
  }

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging && !isRightDragging) return
    const deltaX = e.clientX - lastMouseRef.current.x
    const deltaY = e.clientY - lastMouseRef.current.y
    lastMouseRef.current = { x: e.clientX, y: e.clientY }

    if (isDragging) {
      fetch('https://nt_appearance/rotateCam', {
        method: 'POST',
        body: JSON.stringify({ deltaX }),
      })
    }
    if (isRightDragging) {
      fetch('https://nt_appearance/adjustHeight', {
        method: 'POST',
        body: JSON.stringify({ deltaY }),
      })
    }
  }

  const handleWheel = (e: React.WheelEvent) => {
    fetch('https://nt_appearance/zoomCam', {
      method: 'POST',
      body: JSON.stringify({ delta: e.deltaY > 0 ? 1 : -1 }),
    })
  }

  useEffect(() => {
    const handler = (e: MessageEvent) => {
      const data = e.data
      if (data.action === 'open')  setVisible(true)
      if (data.action === 'close') setVisible(false)
      if (data.type === 'setConfig') setPanelPosition(data.panelPosition ?? 'right')
    }
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  if (!visible) return null

  const hintsClass = panelPosition === 'right'
    ? 'absolute bottom-6 left-8 flex flex-col items-start gap-1 pointer-events-none'
    : 'absolute bottom-6 right-8 flex flex-col items-end gap-1 pointer-events-none'

  return (
    <div
      className="fixed inset-0 select-none text-white flex pointer-events-none"
      style={{ flexDirection: panelPosition === 'right' ? 'row' : 'row-reverse' }}
    >

      {/* Transparent world area — camera drag/zoom handlers live here only */}
      <div
        className="flex-1 relative pointer-events-auto"
        onMouseDown={handleMouseDown}
        onMouseUp={handleMouseUp}
        onMouseMove={handleMouseMove}
        onWheel={handleWheel}
        onContextMenu={e => e.preventDefault()}
      >
        {/* Camera control hints */}
        <div className={hintsClass}>
          {[
            ['Left drag', 'Rotate'],
            ['Right drag', 'Height'],
            ['Scroll', 'Zoom'],
          ].map(([key, label]) => (
            <p key={key} className="text-[10px] text-white/25 tracking-wide">
              <span className="text-white/18">{key}</span>
              <span className="text-white/12 mx-1.5">·</span>
              {label}
            </p>
          ))}
        </div>
      </div>

      {/* Panel */}
      <div
        className="w-[260px] flex flex-col pointer-events-auto"
        style={{ background: 'rgba(11, 17, 32, 0.92)' }}
      >
        {/* Header */}
        <div className="px-6 pt-7 pb-5 border-b border-white/8">
          <p className="text-[10px] font-semibold tracking-[0.22em] uppercase text-white/40">
            Character Appearance
          </p>
          <p className="text-xs text-white/20 mt-1">Build your character</p>
        </div>

        {/* Category icon slots */}
        <div className="px-6 py-5 border-b border-white/8">
          <p className="text-[9px] tracking-[0.18em] uppercase text-white/20 mb-3">Categories</p>
          <div className="grid grid-cols-6 gap-1.5">
            {Array.from({ length: 6 }).map((_, i) => (
              <div
                key={i}
                className="aspect-square rounded-lg bg-white/[0.04] border border-white/8"
              />
            ))}
          </div>
        </div>

        {/* Content area */}
        <div className="flex-1 flex items-center justify-center px-6">
          <p className="text-xs text-white/[0.18] text-center leading-relaxed">
            Select a category<br />to begin
          </p>
        </div>

        {/* Bottom actions */}
        <div className="px-6 py-5 border-t border-white/8 flex flex-col gap-2">
          <button
            disabled
            className="w-full py-2.5 rounded bg-white/[0.06] text-white/20 text-xs font-semibold tracking-wide cursor-not-allowed"
          >
            Save &amp; Continue
          </button>
          <button
            onClick={() => nuiFetch('exitAppearance', {})}
            className="w-full py-2.5 rounded border border-white/12 text-white/45 text-xs tracking-wide transition-all duration-150 hover:bg-white/[0.06] hover:border-white/22 hover:text-white/70 cursor-pointer"
          >
            Exit
          </button>
        </div>
      </div>

    </div>
  )
}

export default App
