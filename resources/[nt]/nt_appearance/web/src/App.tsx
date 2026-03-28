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
  { id: 'overlays',    icon: '◉', label: 'Overlays' },
  { id: 'outfits',     icon: '☰', label: 'Outfits' },
  { id: 'tattoos',     icon: '∧', label: 'Tattoos' },
]

const CLOTHING_SLOTS = [
  { id: 11, label: 'Tops' },
  { id: 4,  label: 'Pants' },
  { id: 6,  label: 'Shoes' },
  { id: 8,  label: 'Undershirt' },
  { id: 3,  label: 'Torso' },
  { id: 1,  label: 'Mask' },
  { id: 7,  label: 'Accessories' },
  { id: 5,  label: 'Bags' },
  { id: 10, label: 'Decals' },
]

const PROP_SLOTS = [
  { id: 0, label: 'Hat' },
  { id: 1, label: 'Glasses' },
  { id: 2, label: 'Ear' },
  { id: 6, label: 'Watch' },
  { id: 7, label: 'Bracelet' },
]

const OVERLAYS = [
  { id: 0,  key: 'blemishes',       label: 'Blemishes',       maxStyles: 23, hasColor: false, maleOnly: false },
  { id: 1,  key: 'beard',           label: 'Beard',           maxStyles: 28, hasColor: true,  maleOnly: true  },
  { id: 2,  key: 'eyebrows',        label: 'Eyebrows',        maxStyles: 33, hasColor: true,  maleOnly: false },
  { id: 3,  key: 'ageing',          label: 'Ageing',          maxStyles: 14, hasColor: false, maleOnly: false },
  { id: 4,  key: 'makeUp',          label: 'Make-up',         maxStyles: 74, hasColor: false, maleOnly: false },
  { id: 5,  key: 'blush',           label: 'Blush',           maxStyles: 6,  hasColor: true,  maleOnly: false },
  { id: 6,  key: 'complexion',      label: 'Complexion',      maxStyles: 11, hasColor: false, maleOnly: false },
  { id: 7,  key: 'sunDamage',       label: 'Sun Damage',      maxStyles: 10, hasColor: false, maleOnly: false },
  { id: 8,  key: 'lipstick',        label: 'Lipstick',        maxStyles: 9,  hasColor: true,  maleOnly: false },
  { id: 9,  key: 'moleAndFreckles', label: 'Mole / Freckles', maxStyles: 17, hasColor: false, maleOnly: false },
  { id: 10, key: 'chestHair',       label: 'Chest Hair',      maxStyles: 16, hasColor: true,  maleOnly: true  },
  { id: 11, key: 'bodyBlemishes',   label: 'Body Blemishes',  maxStyles: 11, hasColor: false, maleOnly: false },
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

interface DrawableTex { drawable: number; texture: number }

interface OverlayState {
  style: number
  opacity: number
  color: number
  secondColor: number
}

interface Outfit {
  id: number
  outfitname: string
  components: string
  props: string
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
  label, value, leftLabel, rightLabel, onChange, max = '1',
}: { label: string; value: number; leftLabel: string; rightLabel: string; onChange: (v: number) => void; max?: string }) {
  return (
    <div className="mb-4">
      <div className="flex justify-between mb-1.5">
        <span style={{ color: 'rgba(255,255,255,0.50)' }}
              className="text-[9px] tracking-[0.06em] uppercase">{label}</span>
        <span style={{ color: 'rgba(255,255,255,0.35)' }}
              className="text-[9px] tabular-nums">{value.toFixed(2)}</span>
      </div>
      <input
        type="range" min="0" max={max} step="0.01" value={value}
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
        type="range" min="-0.99" max="0.99" step="0.01" value={value}
        onChange={e => onChange(parseFloat(e.target.value))}
        className="nt-slider"
      />
    </div>
  )
}

// Horizontal scrollable slot selector strip
function SlotStrip({
  slots, active, onSelect,
}: { slots: { id: number; label: string }[]; active: number; onSelect: (id: number) => void }) {
  return (
    <div className="overflow-x-auto flex-shrink-0 border-b border-white/8">
      <div className="flex gap-1 px-3 py-2" style={{ minWidth: 'max-content' }}>
        {slots.map(s => (
          <button
            key={s.id}
            onClick={() => onSelect(s.id)}
            style={active === s.id
              ? { color: '#ffffff', background: 'rgba(255,255,255,0.15)', borderColor: 'rgba(255,255,255,0.30)' }
              : { color: 'rgba(255,255,255,0.40)' }
            }
            className={`px-2 py-1.5 rounded text-[9px] tracking-[0.08em] uppercase border transition-all duration-100 whitespace-nowrap ${
              active === s.id ? '' : 'border-white/8 bg-white/[0.03] hover:text-white/65'
            }`}
          >
            {s.label}
          </button>
        ))}
      </div>
    </div>
  )
}

// Model / Texture sub-tab bar (shared by clothing and props)
function DrawableTabBar({
  active, onChange,
}: { active: 'model' | 'texture'; onChange: (t: 'model' | 'texture') => void }) {
  return (
    <div className="flex border-b border-white/8 px-4 gap-4 flex-shrink-0">
      {(['model', 'texture'] as const).map(tab => (
        <button
          key={tab}
          onClick={() => onChange(tab)}
          style={active === tab
            ? { color: '#ffffff', borderBottomColor: 'rgba(255,255,255,0.5)' }
            : { color: 'rgba(255,255,255,0.40)' }
          }
          className={`py-2.5 text-[9px] tracking-[0.12em] uppercase border-b-2 -mb-px transition-all ${
            active === tab ? '' : 'border-transparent hover:text-white/60'
          }`}
        >
          {tab === 'model' ? 'Model' : 'Texture'}
        </button>
      ))}
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
  const [appearanceReady, setAppearanceReady] = useState(false)
  const [saving, setSaving]                   = useState(false)
  const [currentGender, setCurrentGender]     = useState(0)  // 0=male 1=female

  // Hair sub-tab
  const [hairTab, setHairTab] = useState<'model' | 'color' | 'highlight'>('model')

  // Clothing state
  const [activeClothingSlot, setActiveClothingSlot] = useState(11)
  const [clothingSubTab, setClothingSubTab]         = useState<'model' | 'texture'>('model')
  const [clothing, setClothing] = useState<Record<number, DrawableTex>>({
    11: { drawable: 0, texture: 0 },
    4:  { drawable: 0, texture: 0 },
    6:  { drawable: 0, texture: 0 },
    8:  { drawable: 0, texture: 0 },
    3:  { drawable: 0, texture: 0 },
    1:  { drawable: 0, texture: 0 },
    7:  { drawable: 0, texture: 0 },
    5:  { drawable: 0, texture: 0 },
    10: { drawable: 0, texture: 0 },
  })

  // Props state
  const [activePropSlot, setActivePropSlot] = useState(0)
  const [propSubTab, setPropSubTab]         = useState<'model' | 'texture'>('model')
  const [pedProps, setPedProps] = useState<Record<number, DrawableTex>>({
    0: { drawable: -1, texture: 0 },
    1: { drawable: -1, texture: 0 },
    2: { drawable: -1, texture: 0 },
    6: { drawable: -1, texture: 0 },
    7: { drawable: -1, texture: 0 },
  })

  // Overlays state
  const [activeOverlay, setActiveOverlay] = useState(0)
  const [overlays, setOverlays] = useState<Record<number, OverlayState>>(() => {
    const init: Record<number, OverlayState> = {}
    for (const o of OVERLAYS) init[o.id] = { style: 255, opacity: 0, color: 0, secondColor: 0 }
    return init
  })

  // Eye color state (-1 = default/game default)
  const [eyeColor, setEyeColor] = useState(-1)

  // Outfits state
  const [outfits, setOutfits]             = useState<Outfit[]>([])
  const [outfitName, setOutfitName]       = useState('')
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null)

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
      if (data.action === 'open') setVisible(true)
      if (data.action === 'close') {
        setVisible(false)
        setSaving(false)
        setAppearanceReady(false)
        setOutfits([])
        setDeleteConfirm(null)
        setOutfitName('')
      }
      if (data.type === 'setConfig') {
        setPanelPosition(data.panelPosition ?? 'right')
        if (data.appearanceReady) setAppearanceReady(true)
        if (data.gender !== undefined) setCurrentGender(data.gender)
      }
      if (data.type === 'setOutfits') {
        setOutfits(data.outfits ?? [])
      }
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
      faceFeatures[index] = value
      nuiFetch('setFaceFeature', { index, value })
      return { ...prev, faceFeatures }
    })

  const updateHair = (hair: number) =>
    setAppearance(prev => { nuiFetch('setHair', { hair }); return { ...prev, hair } })

  const updateHairColor = (color: number, highlight: number) =>
    setAppearance(prev => {
      nuiFetch('setHairColor', { color, highlight })
      return { ...prev, hairColor: color, hairHighlight: highlight }
    })

  const updateClothing = (component: number, drawable: number, texture: number) => {
    nuiFetch('setClothing', { component, drawable, texture })
    setClothing(prev => ({ ...prev, [component]: { drawable, texture } }))
  }

  const updateProp = (prop: number, drawable: number, texture: number) => {
    nuiFetch('setProp', { prop, drawable, texture })
    setPedProps(prev => ({ ...prev, [prop]: { drawable, texture } }))
  }

  const updateOverlay = (id: number, patch: Partial<OverlayState>) => {
    setOverlays(prev => {
      const current = prev[id] ?? { style: 255, opacity: 0, color: 0, secondColor: 0 }
      const updated = { ...current, ...patch }
      nuiFetch('setHeadOverlay', { overlay: id, ...updated })
      return { ...prev, [id]: updated }
    })
  }

  const updateEyeColor = (color: number) => {
    setEyeColor(color)
    nuiFetch('setEyeColor', { color })
  }

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
            <SectionLabel>Eye Color</SectionLabel>
            <button
              onClick={() => updateEyeColor(-1)}
              style={eyeColor === -1
                ? { color: '#ffffff', background: 'rgba(255,255,255,0.15)', borderColor: 'rgba(255,255,255,0.35)' }
                : { color: 'rgba(255,255,255,0.40)' }
              }
              className={`w-full mb-2 py-1.5 rounded text-[9px] tracking-[0.10em] uppercase border transition-all duration-100 ${
                eyeColor === -1 ? '' : 'border-white/8 bg-white/[0.03] hover:text-white/65'
              }`}
            >
              Default
            </button>
            <NumberGrid count={32} active={eyeColor} onSelect={updateEyeColor} />
            <div className="border-t border-white/8 mb-3 mt-1" />
            <SectionLabel>Face Features</SectionLabel>
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

      case 'clothing': {
        const slot = clothing[activeClothingSlot] ?? { drawable: 0, texture: 0 }
        return (
          <div className="flex-1 flex flex-col overflow-hidden">
            <SlotStrip
              slots={CLOTHING_SLOTS}
              active={activeClothingSlot}
              onSelect={id => { setActiveClothingSlot(id); setClothingSubTab('model') }}
            />
            <DrawableTabBar active={clothingSubTab} onChange={setClothingSubTab} />
            <div className="flex-1 overflow-y-auto px-4 py-3">
              {clothingSubTab === 'model' && (
                <NumberGrid
                  count={128}
                  active={slot.drawable}
                  onSelect={i => updateClothing(activeClothingSlot, i, slot.texture)}
                />
              )}
              {clothingSubTab === 'texture' && (
                <NumberGrid
                  count={16}
                  active={slot.texture}
                  onSelect={i => updateClothing(activeClothingSlot, slot.drawable, i)}
                />
              )}
            </div>
          </div>
        )
      }

      case 'props': {
        const slot = pedProps[activePropSlot] ?? { drawable: -1, texture: 0 }
        return (
          <div className="flex-1 flex flex-col overflow-hidden">
            <SlotStrip
              slots={PROP_SLOTS}
              active={activePropSlot}
              onSelect={id => { setActivePropSlot(id); setPropSubTab('model') }}
            />
            <DrawableTabBar active={propSubTab} onChange={setPropSubTab} />
            <div className="flex-1 overflow-y-auto px-4 py-3">
              {propSubTab === 'model' && (
                <>
                  <button
                    onClick={() => updateProp(activePropSlot, -1, 0)}
                    style={slot.drawable === -1
                      ? { color: '#ffffff', background: 'rgba(255,255,255,0.15)', borderColor: 'rgba(255,255,255,0.35)' }
                      : { color: 'rgba(255,255,255,0.40)' }
                    }
                    className={`w-full mb-3 py-1.5 rounded text-[9px] tracking-[0.10em] uppercase border transition-all duration-100 ${
                      slot.drawable === -1 ? '' : 'border-white/8 bg-white/[0.03] hover:text-white/65'
                    }`}
                  >
                    None
                  </button>
                  <NumberGrid
                    count={128}
                    active={slot.drawable}
                    onSelect={i => updateProp(activePropSlot, i, slot.texture)}
                  />
                </>
              )}
              {propSubTab === 'texture' && slot.drawable !== -1 && (
                <NumberGrid
                  count={16}
                  active={slot.texture}
                  onSelect={i => updateProp(activePropSlot, slot.drawable, i)}
                />
              )}
              {propSubTab === 'texture' && slot.drawable === -1 && (
                <p className="text-[9px] text-center mt-6"
                   style={{ color: 'rgba(255,255,255,0.25)' }}>
                  Select a model first
                </p>
              )}
            </div>
          </div>
        )
      }

      case 'overlays': {
        const visibleOverlays = OVERLAYS.filter(o => !o.maleOnly || currentGender === 0)
        const activeOv  = OVERLAYS.find(o => o.id === activeOverlay)
        const ovState   = overlays[activeOverlay] ?? { style: 255, opacity: 0, color: 0, secondColor: 0 }
        return (
          <div className="flex-1 flex flex-col overflow-hidden">
            <SlotStrip
              slots={visibleOverlays.map(o => ({ id: o.id, label: o.label }))}
              active={activeOverlay}
              onSelect={id => setActiveOverlay(id)}
            />
            {activeOv && (
              <div className="flex-1 overflow-y-auto px-4 py-3">
                {/* None */}
                <button
                  onClick={() => updateOverlay(activeOverlay, { style: 255, opacity: 0 })}
                  style={ovState.style === 255
                    ? { color: '#ffffff', background: 'rgba(255,255,255,0.15)', borderColor: 'rgba(255,255,255,0.35)' }
                    : { color: 'rgba(255,255,255,0.40)' }
                  }
                  className={`w-full mb-3 py-1.5 rounded text-[9px] tracking-[0.10em] uppercase border transition-all duration-100 ${
                    ovState.style === 255 ? '' : 'border-white/8 bg-white/[0.03] hover:text-white/65'
                  }`}
                >
                  None
                </button>

                <SectionLabel>Style</SectionLabel>
                <NumberGrid
                  count={activeOv.maxStyles}
                  active={ovState.style}
                  onSelect={i => updateOverlay(activeOverlay, {
                    style: i,
                    opacity: ovState.opacity > 0 ? ovState.opacity : 0.99,
                  })}
                />

                {ovState.style !== 255 && (
                  <MixSlider
                    label="Opacity"
                    value={ovState.opacity}
                    leftLabel="0" rightLabel="0.99"
                    max="0.99"
                    onChange={v => updateOverlay(activeOverlay, { opacity: v })}
                  />
                )}

                {activeOv.hasColor && ovState.style !== 255 && (
                  <>
                    <SectionLabel>Color</SectionLabel>
                    <NumberGrid
                      count={64}
                      active={ovState.color}
                      onSelect={i => updateOverlay(activeOverlay, { color: i })}
                    />
                    <SectionLabel>Secondary Color</SectionLabel>
                    <NumberGrid
                      count={64}
                      active={ovState.secondColor}
                      onSelect={i => updateOverlay(activeOverlay, { secondColor: i })}
                    />
                  </>
                )}
              </div>
            )}
          </div>
        )
      }

      case 'outfits': {
        return (
          <div className="flex-1 flex flex-col overflow-hidden">
            {/* Save new outfit */}
            <div className="px-4 py-3 border-b border-white/8 flex-shrink-0">
              <SectionLabel>Save Current Outfit</SectionLabel>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={outfitName}
                  onChange={e => setOutfitName(e.target.value)}
                  placeholder="Outfit name..."
                  className="flex-1 bg-white/[0.06] border border-white/10 rounded px-2 py-1.5 text-[10px] outline-none focus:border-white/25"
                  style={{ color: 'rgba(255,255,255,0.80)' }}
                />
                <button
                  disabled={!outfitName.trim()}
                  onClick={() => {
                    if (!outfitName.trim()) return
                    const components = Object.entries(clothing).map(([id, dt]) => ({
                      component_id: parseInt(id), drawable: dt.drawable, texture: dt.texture,
                    }))
                    const props = Object.entries(pedProps).map(([id, dt]) => ({
                      prop_id: parseInt(id), drawable: dt.drawable, texture: dt.texture,
                    }))
                    nuiFetch('saveOutfit', { name: outfitName, components, props })
                    setOutfitName('')
                  }}
                  className={`px-3 py-1.5 rounded text-[9px] tracking-wide border transition-all duration-100 ${
                    outfitName.trim()
                      ? 'bg-white/15 border-white/30 hover:bg-white/20 cursor-pointer'
                      : 'bg-white/[0.04] border-white/8 cursor-not-allowed'
                  }`}
                  style={{ color: outfitName.trim() ? '#ffffff' : 'rgba(255,255,255,0.25)' }}
                >
                  Save
                </button>
              </div>
            </div>

            {/* Outfit list */}
            <div className="flex-1 overflow-y-auto px-4 py-3">
              {outfits.length === 0 ? (
                <p className="text-[9px] text-center mt-6"
                   style={{ color: 'rgba(255,255,255,0.25)' }}>
                  No saved outfits
                </p>
              ) : (
                <div className="flex flex-col gap-2">
                  {outfits.map(outfit => (
                    <div
                      key={outfit.id}
                      className="rounded border border-white/10 bg-white/[0.04] px-3 py-2.5"
                    >
                      <p className="text-[10px] font-medium mb-2"
                         style={{ color: 'rgba(255,255,255,0.80)' }}>
                        {outfit.outfitname}
                      </p>
                      {deleteConfirm === outfit.id ? (
                        <div className="flex gap-1.5 items-center">
                          <span className="flex-1 text-[9px]"
                                style={{ color: 'rgba(255,255,255,0.40)' }}>
                            Delete?
                          </span>
                          <button
                            onClick={() => {
                              nuiFetch('deleteOutfit', { id: outfit.id })
                              setDeleteConfirm(null)
                              setOutfits(prev => prev.filter(o => o.id !== outfit.id))
                            }}
                            className="px-2 py-1 rounded text-[8px] border border-red-400/40 bg-red-500/10 hover:bg-red-500/20 cursor-pointer transition-all"
                            style={{ color: 'rgba(255,100,100,0.80)' }}
                          >
                            Confirm
                          </button>
                          <button
                            onClick={() => setDeleteConfirm(null)}
                            className="px-2 py-1 rounded text-[8px] border border-white/12 bg-white/[0.04] hover:bg-white/[0.09] cursor-pointer transition-all"
                            style={{ color: 'rgba(255,255,255,0.50)' }}
                          >
                            Cancel
                          </button>
                        </div>
                      ) : (
                        <div className="flex gap-1.5">
                          <button
                            onClick={() => {
                              type CompEntry = { component_id: number; drawable: number; texture: number }
                              type PropEntry = { prop_id: number; drawable: number; texture: number }
                              const comps    = JSON.parse(outfit.components) as CompEntry[]
                              const propsArr = JSON.parse(outfit.props)      as PropEntry[]
                              const newClothing = { ...clothing }
                              for (const c of comps) newClothing[c.component_id] = { drawable: c.drawable, texture: c.texture }
                              setClothing(newClothing)
                              const newProps = { ...pedProps }
                              for (const p of propsArr) newProps[p.prop_id] = { drawable: p.drawable, texture: p.texture }
                              setPedProps(newProps)
                              nuiFetch('loadOutfit', { components: comps, props: propsArr })
                            }}
                            className="flex-1 py-1 rounded text-[9px] border border-white/15 bg-white/[0.06] hover:bg-white/[0.12] cursor-pointer transition-all"
                            style={{ color: 'rgba(255,255,255,0.70)' }}
                          >
                            Load
                          </button>
                          <button
                            onClick={() => setDeleteConfirm(outfit.id)}
                            className="px-2.5 py-1 rounded text-[9px] border border-white/8 bg-white/[0.03] hover:bg-white/[0.08] cursor-pointer transition-all"
                            style={{ color: 'rgba(255,255,255,0.35)' }}
                          >
                            ✕
                          </button>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )
      }

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

        {/* Category icons — 4 columns to fit 8 categories in 2 rows */}
        <div className="px-4 py-4 border-b border-white/8 flex-shrink-0">
          <div className="grid grid-cols-4 gap-1">
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
            disabled={!appearanceReady || saving}
            onClick={() => { setSaving(true); nuiFetch('saveAppearance', {}) }}
            className={`w-full py-2.5 rounded text-xs font-semibold tracking-wide transition-all duration-150 ${
              appearanceReady && !saving
                ? 'bg-white/15 border border-white/30 hover:bg-white/20 cursor-pointer'
                : 'bg-white/[0.06] cursor-not-allowed'
            }`}
            style={{ color: appearanceReady && !saving ? '#ffffff' : 'rgba(255,255,255,0.30)' }}
          >
            {saving ? 'Saving...' : 'Save & Continue'}
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
