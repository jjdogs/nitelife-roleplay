import { useEffect, useRef, useState } from 'react'

// ── NUI helper ──────────────────────────────────────────────────────────────

function nuiFetch<T = unknown>(endpoint: string, data: object): Promise<T | null> {
  return fetch(`https://nt_appearance/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
    .then(r => r.json() as Promise<T>)
    .catch(() => null)
}

// ── Constants ───────────────────────────────────────────────────────────────

const FACE_FEATURES: string[] = [
  'Nose Width','Nose Height','Nose Length','Nose Bridge','Nose Tip','Nose Shift',
  'Brow Height','Brow Width',
  'Cheekbone Height','Cheekbone Width',
  'Cheek Width',
  'Eye Opening',
  'Lip Thickness',
  'Jaw Width','Jaw Height',
  'Chin Length','Chin Position','Chin Width','Chin Hole',
  'Neck Width',
]

const CATEGORIES = [
  { id: 'inheritance', icon: '⚇', label: 'Inheritance' },
  { id: 'face',        icon: '☺', label: 'Face Features' },
  { id: 'hair',        icon: '✦', label: 'Hair' },
  { id: 'clothing',    icon: '👕', label: 'Clothing' },
  { id: 'props',       icon: '👜', label: 'Props' },
  { id: 'tattoos',     icon: '∧', label: 'Tattoos' },
]

// ── Types ───────────────────────────────────────────────────────────────────

interface HeadBlend {
  shapeFirst: number; shapeSecond: number
  skinFirst:  number; skinSecond:  number
  shapeMix:   number; skinMix:     number
}

interface AppearanceState {
  headBlend:     HeadBlend
  faceFeatures:  number[]
  hair:          number
  hairColor:     number
  hairHighlight: number
}

// ── Sub-components ───────────────────────────────────────────────────────────

function SectionLabel({ children }: { children: string }) {
  return (
    <p style={{ color: 'rgba(255,255,255,0.35)', letterSpacing: '0.06em' }}
       className="text-[9px] uppercase mb-2">
      {children}
    </p>
  )
}

function NumberGrid({
  count, active, onSelect,
}: { count: number; active: number; onSelect: (i: number) => void }) {
  return (
    <div className="grid grid-cols-5 gap-1 mb-4">
      {Array.from({ length: count }).map((_, i) => (
        <button
          key={i}
          onClick={() => onSelect(i)}
          className={`aspect-square rounded text-[9px] font-mono transition-all duration-100 ${
            active === i
              ? 'bg-white/20 border border-white/40 text-white'
              : 'bg-white/[0.04] border border-white/8 text-white/40 hover:bg-white/[0.09] hover:text-white/70'
          }`}
        >
          {i}
        </button>
      ))}
    </div>
  )
}

function MixSlider({
  label, value, leftLabel, rightLabel, onChange,
}: { label: string; value: number; leftLabel: string; rightLabel: string; onChange: (v: number) => void }) {
  return (
    <div className="mb-4">
      <div className="flex justify-between mb-1.5">
        <span style={{ color: 'rgba(255,255,255,0.50)' }}
              className="text-[9px] tracking-[0.06em] uppercase">{label}</span>
        <span style={{ color: 'rgba(255,255,255,0.35)' }}
              className="text-[9px] tabular-nums">{value.toFixed(2)}</span>
      </div>
      <input
        type="range" min="0" max="1" step="0.01" value={value}
        onChange={e => onChange(parseFloat(e.target.value))}
        className="nt-slider"
      />
      <div className="flex justify-between mt-1">
        <span style={{ color: 'rgba(255,255,255,0.35)' }} className="text-[8px]">{leftLabel}</span>
        <span style={{ color: 'rgba(255,255,255,0.35)' }} className="text-[8px]">{rightLabel}</span>
      </div>
    </div>
  )
}

function FeatureSlider({
  label, value, onChange,
}: { label: string; value: number; onChange: (v: number) => void }) {
  return (
    <div className="mb-3">
      <div className="flex justify-between mb-1.5">
        <span style={{ color: 'rgba(255,255,255,0.50)' }}
              className="text-[9px] tracking-[0.06em] uppercase">{label}</span>
        <span style={{ color: 'rgba(255,255,255,0.35)' }}
              className="text-[9px] tabular-nums">{value.toFixed(2)}</span>
      </div>
      <input
        type="range" min="-1" max="0.99" step="0.01" value={value}
        onChange={e => onChange(parseFloat(e.target.value))}
        className="nt-slider"
      />
    </div>
  )
}

// ── App ──────────────────────────────────────────────────────────────────────

function App() {
  const [visible, setVisible]                 = useState(false)
  const [isDragging, setIsDragging]           = useState(false)
  const [isRightDragging, setIsRightDragging] = useState(false)
  const [panelPosition, setPanelPosition]     = useState<'left' | 'right'>('right')
  const [activeCategory, setActiveCategory]   = useState<string | null>(null)
  const [hairTab, setHairTab]                 = useState<'model' | 'color' | 'highlight'>('model')
  const lastMouseRef = useRef({ x: 0, y: 0 })

  const [appearance, setAppearance] = useState<AppearanceState>({
    headBlend: {
      shapeFirst: 0, shapeSecond: 0,
      skinFirst:  0, skinSecond:  0,
      shapeMix: 0.5, skinMix: 0.5,
    },
    faceFeatures:  new Array(20).fill(0.0),
    hair:          0,
    hairColor:     0,
    hairHighlight: 0,
  })

  // ── Camera drag handlers ─────────────────────────────────────────────────

  const handleMouseDown = (e: React.MouseEvent) => {
    if (e.button === 0) setIsDragging(true)
    if (e.button === 2) setIsRightDragging(true)
    lastMouseRef.current = { x: e.clientX, y: e.clientY }
  }

  const handleMouseUp = () => { setIsDragging(false); setIsRightDragging(false) }

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging && !isRightDragging) return
    const deltaX = e.clientX - lastMouseRef.current.x
    const deltaY = e.clientY - lastMouseRef.current.y
    lastMouseRef.current = { x: e.clientX, y: e.clientY }
    if (isDragging)
      fetch('https://nt_appearance/rotateCam', { method: 'POST', body: JSON.stringify({ deltaX }) })
    if (isRightDragging)
      fetch('https://nt_appearance/adjustHeight', { method: 'POST', body: JSON.stringify({ deltaY }) })
  }

  const handleWheel = (e: React.WheelEvent) => {
    fetch('https://nt_appearance/zoomCam', {
      method: 'POST',
      body: JSON.stringify({ delta: e.deltaY > 0 ? 1 : -1 }),
    })
  }

  // ── NUI message listener ─────────────────────────────────────────────────

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

  // ── Appearance updaters ──────────────────────────────────────────────────

  const updateHeadBlend = (patch: Partial<HeadBlend>) =>
    setAppearance(prev => {
      const headBlend = { ...prev.headBlend, ...patch }
      nuiFetch('setHeadBlend', headBlend)
      return { ...prev, headBlend }
    })

  const updateFaceFeature = (index: number, value: number) =>
    setAppearance(prev => {
      const faceFeatures = [...prev.faceFeatures]
      const clamped = Math.max(-1.0, Math.min(0.99, value))
      faceFeatures[index] = clamped
      nuiFetch('setFaceFeature', { index, value: clamped })
      return { ...prev, faceFeatures }
    })

  const updateHair = (hair: number) =>
    setAppearance(prev => { nuiFetch('setHair', { hair }); return { ...prev, hair } })

  const updateHairColor = (color: number, highlight: number) =>
    setAppearance(prev => {
      nuiFetch('setHairColor', { color, highlight })
      return { ...prev, hairColor: color, hairHighlight: highlight }
    })

  // ── Tab content ───────────────────────────────────────────────────────────

  const renderContent = () => {
    switch (activeCategory) {

      case 'inheritance':
        return (
          <div className="flex-1 overflow-y-auto px-4 py-3">
            <SectionLabel>Father Face</SectionLabel>
            <NumberGrid
              count={45}
              active={appearance.headBlend.shapeFirst}
              onSelect={i => updateHeadBlend({ shapeFirst: i, skinFirst: i })}
            />

            <SectionLabel>Mother Face</SectionLabel>
            <NumberGrid
              count={45}
              active={appearance.headBlend.shapeSecond}
              onSelect={i => updateHeadBlend({ shapeSecond: i, skinSecond: i })}
            />

            <MixSlider
              label="Shape Mix"
              value={appearance.headBlend.shapeMix}
              leftLabel="Father" rightLabel="Mother"
              onChange={v => updateHeadBlend({ shapeMix: v })}
            />
            <MixSlider
              label="Skin Mix"
              value={appearance.headBlend.skinMix}
              leftLabel="Father" rightLabel="Mother"
              onChange={v => updateHeadBlend({ skinMix: v })}
            />
          </div>
        )

      case 'face':
        return (
          <div className="flex-1 overflow-y-auto px-4 py-3">
            {FACE_FEATURES.map((label, i) => (
              <FeatureSlider
                key={i}
                label={label}
                value={appearance.faceFeatures[i]}
                onChange={v => updateFaceFeature(i, v)}
              />
            ))}
          </div>
        )

      case 'hair':
        return (
          <div className="flex-1 flex flex-col overflow-hidden">
            {/* Sub-tabs */}
            <div className="flex border-b border-white/8 px-4 gap-4 flex-shrink-0">
              {(['model', 'color', 'highlight'] as const).map(tab => (
                <button
                  key={tab}
                  onClick={() => setHairTab(tab)}
                  style={hairTab === tab
                    ? { color: '#ffffff', borderBottomColor: 'rgba(255,255,255,0.5)' }
                    : { color: 'rgba(255,255,255,0.40)' }
                  }
                  className={`py-2.5 text-[9px] tracking-[0.12em] uppercase border-b-2 -mb-px transition-all ${
                    hairTab === tab ? '' : 'border-transparent hover:text-white/60'
                  }`}
                >
                  {tab === 'model' ? 'Style' : tab === 'color' ? 'Color' : 'Highlight'}
                </button>
              ))}
            </div>

            <div className="flex-1 overflow-y-auto px-4 py-3">
              {hairTab === 'model' && (
                <NumberGrid count={81} active={appearance.hair} onSelect={updateHair} />
              )}
              {hairTab === 'color' && (
                <NumberGrid
                  count={64}
                  active={appearance.hairColor}
                  onSelect={i => updateHairColor(i, appearance.hairHighlight)}
                />
              )}
              {hairTab === 'highlight' && (
                <NumberGrid
                  count={64}
                  active={appearance.hairHighlight}
                  onSelect={i => updateHairColor(appearance.hairColor, i)}
                />
              )}
            </div>
          </div>
        )

      default:
        return (
          <div className="flex-1 flex items-center justify-center px-6">
            <p className="text-xs text-center leading-relaxed"
               style={{ color: 'rgba(255,255,255,0.25)' }}>
              {activeCategory
                ? 'Coming soon'
                : <>Select a category<br />to begin</>
              }
            </p>
          </div>
        )
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────

  if (!visible) return null

  const hintsStyle: React.CSSProperties = {
    position: 'absolute',
    top: '1rem',
    left:  panelPosition === 'right' ? '1rem' : 'auto',
    right: panelPosition === 'left'  ? '1rem' : 'auto',
  }

  return (
    <div
      className="fixed inset-0 select-none text-white flex pointer-events-none"
      style={{ flexDirection: panelPosition === 'right' ? 'row' : 'row-reverse' }}
    >

      {/* Transparent world area — camera handlers only */}
      <div
        className="flex-1 relative pointer-events-auto"
        onMouseDown={handleMouseDown}
        onMouseUp={handleMouseUp}
        onMouseMove={handleMouseMove}
        onWheel={handleWheel}
        onContextMenu={e => e.preventDefault()}
      >
        {/* Camera control hints — top corner opposite the panel */}
        <div style={hintsStyle} className="flex flex-col items-start gap-1 pointer-events-none">
          {[['Left drag','Rotate'],['Right drag','Height'],['Scroll','Zoom']].map(([k, l]) => (
            <p key={k} className="text-[10px] tracking-wide"
               style={{ color: 'rgba(255,255,255,0.30)' }}>
              <span style={{ color: 'rgba(255,255,255,0.20)' }}>{k}</span>
              <span style={{ color: 'rgba(255,255,255,0.15)' }} className="mx-1.5">·</span>
              {l}
            </p>
          ))}
        </div>
      </div>

      {/* Panel */}
      <div
        className="w-[260px] flex flex-col pointer-events-auto overflow-hidden"
        style={{ background: 'rgba(11, 17, 32, 0.92)' }}
      >
        {/* Header */}
        <div className="px-6 pt-7 pb-5 border-b border-white/8 flex-shrink-0">
          <p className="text-[10px] font-semibold tracking-[0.22em] uppercase"
             style={{ color: 'rgba(255,255,255,0.95)' }}>
            Character Appearance
          </p>
          <p className="text-xs mt-1" style={{ color: 'rgba(255,255,255,0.50)' }}>
            Build your character
          </p>
        </div>

        {/* Category icons */}
        <div className="px-4 py-4 border-b border-white/8 flex-shrink-0">
          <div className="grid grid-cols-6 gap-1">
            {CATEGORIES.map(cat => (
              <button
                key={cat.id}
                onClick={() => setActiveCategory(cat.id === activeCategory ? null : cat.id)}
                title={cat.label}
                className={`flex flex-col items-center justify-center py-2 rounded-lg transition-all duration-150 ${
                  activeCategory === cat.id
                    ? 'bg-white/15 border border-white/30 text-white'
                    : 'bg-white/[0.04] border border-white/8 text-white/50 hover:bg-white/10 hover:text-white/80'
                }`}
              >
                <span className="text-sm leading-none">{cat.icon}</span>
              </button>
            ))}
          </div>
          {activeCategory && (
            <p className="text-[9px] text-center mt-2.5 tracking-[0.14em] uppercase"
               style={{ color: 'rgba(255,255,255,0.60)' }}>
              {CATEGORIES.find(c => c.id === activeCategory)?.label}
            </p>
          )}
        </div>

        {/* Scrollable content area */}
        <div className="flex-1 overflow-hidden flex flex-col">
          {renderContent()}
        </div>

        {/* Bottom actions */}
        <div className="px-6 py-5 border-t border-white/8 flex flex-col gap-2 flex-shrink-0">
          <button
            disabled
            className="w-full py-2.5 rounded bg-white/[0.06] text-xs font-semibold tracking-wide cursor-not-allowed"
            style={{ color: 'rgba(255,255,255,0.30)' }}
          >
            Save &amp; Continue
          </button>
          <button
            onClick={() => nuiFetch('exitAppearance', {})}
            className="w-full py-2.5 rounded border border-white/12 text-xs tracking-wide transition-all duration-150 hover:bg-white/[0.06] hover:border-white/22 cursor-pointer"
            style={{ color: 'rgba(255,255,255,0.60)' }}
          >
            Exit
          </button>
        </div>
      </div>

    </div>
  )
}

export default App
