import { useEffect, useState } from 'react'

// ── Types ─────────────────────────────────────────────────────────────────────

type Character = {
  citizenid: string
  firstName: string
  middleName: string
  lastName: string
  suffix: string
}

type SpawnLocation = {
  id: string
  label: string
  type: 'default' | 'job' | 'property'
  coords: { x: number; y: number; z: number; w: number }
  propertyId?: number   // only present for type === 'property'
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function charFullName(c: Character) {
  return [c.firstName, c.middleName, c.lastName, c.suffix].filter(Boolean).join(' ')
}

function nuiFetch<T = unknown>(endpoint: string, data: object): Promise<T | null> {
  return fetch(`https://nt_spawn/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
    .then(r => r.json() as Promise<T>)
    .catch(() => null)
}

// ── Shared components ─────────────────────────────────────────────────────────

function Logo() {
  return (
    <div className="flex items-center gap-3">
      <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-white/8 border border-white/12 text-sm font-semibold tracking-tight">
        NL
      </div>
      <span className="text-sm text-white/60 tracking-wide">NiteLife Roleplay</span>
    </div>
  )
}

function BackLink({ label = '← Back to menu', onClick }: { label?: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="text-xs text-white/30 hover:text-white/60 transition-colors duration-150 cursor-pointer"
    >
      {label}
    </button>
  )
}

// ── Spawn screen ──────────────────────────────────────────────────────────────

const TYPE_BADGE: Record<SpawnLocation['type'], string | null> = {
  default:  null,
  job:      'JOB',
  property: 'HOME',
}

function SpawnLocationCard({ loc, selected, onSelect }: {
  loc: SpawnLocation; selected: boolean; onSelect: () => void
}) {
  const badge = TYPE_BADGE[loc.type] ?? null
  return (
    <button
      onClick={onSelect}
      className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl border text-left transition-all duration-150 cursor-pointer
        ${selected
          ? 'border-white/40 bg-white/10 shadow-[0_0_20px_rgba(255,255,255,0.03)]'
          : 'border-white/10 bg-white/[0.03] hover:border-white/22 hover:bg-white/[0.06]'}`}
    >
      <div className={`w-1.5 h-1.5 rounded-full flex-shrink-0 transition-colors duration-150 ${selected ? 'bg-white' : 'bg-white/25'}`} />
      <span className="flex-1 text-sm text-white/80">{loc.label}</span>
      {badge && (
        <span className="text-[9px] tracking-[0.10em] uppercase text-white/30 border border-white/12 rounded px-1.5 py-0.5 flex-shrink-0">
          {badge}
        </span>
      )}
    </button>
  )
}

function SpawnScreen({ character, locations, onBack }: {
  character: Character
  locations: SpawnLocation[]
  onBack: () => void
}) {
  const [selectedLoc, setSelectedLoc] = useState<SpawnLocation | null>(null)

  function handleSelect(loc: SpawnLocation) {
    console.log('[nt_spawn] previewSpawn fetch →', loc.id, loc.coords)
    setSelectedLoc(loc)
    nuiFetch('previewSpawn', { coords: loc.coords })
  }

  // Auto-preview the first location as soon as locations arrive
  useEffect(() => {
    if (locations.length > 0 && selectedLoc === null) {
      handleSelect(locations[0])
    }
  }, [locations])

  function handleSpawn() {
    if (!selectedLoc) return
    nuiFetch('confirmSpawn', {
      citizenid: character.citizenid,
      coords: selectedLoc.coords,
      propertyId: selectedLoc.propertyId ?? null,
    })
  }

  function handleBack() {
    nuiFetch('cancelSpawn', {})
    onBack()
  }

  return (
    // Transparent overlay — game world renders behind this
    <div className="fixed inset-0 select-none text-white pointer-events-none">

      {/* Left sidebar: semi-transparent, full height */}
      <div
        className="absolute inset-y-0 left-0 w-[300px] flex flex-col pointer-events-auto"
        style={{ background: 'rgba(11, 17, 32, 0.85)' }}
      >
        {/* Header */}
        <div className="px-7 pt-8 pb-6 border-b border-white/8">
          <Logo />
          <div className="mt-5">
            <p className="text-[10px] text-white/30 tracking-wide uppercase">Spawning as</p>
            <p className="text-sm font-medium text-white/85 mt-0.5">{charFullName(character)}</p>
          </div>
        </div>

        {/* Location cards */}
        <div className="flex-1 px-7 py-6 flex flex-col gap-2 overflow-y-auto">
          <p className="text-[10px] font-semibold tracking-[0.18em] uppercase text-white/28 mb-1">
            Choose Spawn Location
          </p>
          {locations.length === 0 ? (
            <div className="flex-1 flex items-center justify-center">
              <span className="text-xs text-white/20">Loading locations...</span>
            </div>
          ) : (
            locations.map(loc => (
              <SpawnLocationCard
                key={loc.id}
                loc={loc}
                selected={selectedLoc?.id === loc.id}
                onSelect={() => handleSelect(loc)}
              />
            ))
          )}
        </div>

        {/* Back link */}
        <div className="px-7 py-5 border-t border-white/8">
          <BackLink label="← Back to characters" onClick={handleBack} />
        </div>
      </div>

      {/* Bottom-right: Spawn Here button — gradient fade, game world visible above */}
      <div
        className="absolute bottom-0 left-[300px] right-0 px-10 py-7 flex justify-end pointer-events-auto"
        style={{ background: 'linear-gradient(to top, rgba(11,17,32,0.75) 0%, transparent 100%)' }}
      >
        <button
          disabled={!selectedLoc}
          onClick={handleSpawn}
          className={`py-2.5 px-8 rounded text-xs font-semibold tracking-wide transition-all duration-150
            ${selectedLoc
              ? 'bg-white text-[#0b1120] hover:bg-white/90 active:scale-95 cursor-pointer'
              : 'bg-white/8 text-white/20 cursor-not-allowed'}`}
        >
          Spawn Here
        </button>
      </div>

    </div>
  )
}

// ── Creation loading overlay ──────────────────────────────────────────────────

const FALLBACK_MESSAGES = ['Setting up your character...']

function CreationLoadingOverlay({ messages }: { messages: string[] }) {
  const msgs = messages.length > 0 ? messages : FALLBACK_MESSAGES
  const [msgIndex, setMsgIndex] = useState(0)
  const [fade, setFade]         = useState(true)

  useEffect(() => {
    setMsgIndex(0)
    setFade(true)
  }, [messages])

  useEffect(() => {
    const interval = setInterval(() => {
      setFade(false)
      setTimeout(() => {
        setMsgIndex(i => (i + 1) % msgs.length)
        setFade(true)
      }, 300)
    }, 2000)
    return () => clearInterval(interval)
  }, [msgs])

  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-[#0b1120] select-none">
      <Logo />

      {/* Spinner */}
      <div className="mt-10 mb-6">
        <div className="w-8 h-8 rounded-full border-2 border-white/10 border-t-white/60 animate-spin" />
      </div>

      {/* Rotating message */}
      <p
        className="text-sm text-white/50 tracking-wide transition-opacity duration-300"
        style={{ opacity: fade ? 1 : 0 }}
      >
        {msgs[msgIndex]}
      </p>

      {/* Pulsing dots */}
      <div className="flex gap-1.5 mt-5">
        {[0, 1, 2].map(i => (
          <div
            key={i}
            className="w-1 h-1 rounded-full bg-white/25 animate-pulse"
            style={{ animationDelay: `${i * 200}ms` }}
          />
        ))}
      </div>
    </div>
  )
}

// ── Root ──────────────────────────────────────────────────────────────────────

function App() {
  const [visible, setVisible]                   = useState(false)
  const [character, setCharacter]               = useState<Character | null>(null)
  const [locations, setLocations]               = useState<SpawnLocation[]>([])
  const [creationLoading, setCreationLoading]   = useState(false)
  const [creationMessages, setCreationMessages] = useState<string[]>([])

  useEffect(() => {
    // Signal to Lua that the NUI page is loaded and the message listener is ready.
    nuiFetch('nuiReady', {})

    const handler = (event: MessageEvent) => {
      const data = event.data
      if (data.action === 'open') {
        setVisible(true)
        setCharacter(null)
        setLocations([])
      } else if (data.action === 'setSpawnData') {
        setCharacter(data.character ?? null)
        setLocations(data.locations ?? [])
      } else if (data.action === 'close') {
        setVisible(false)
        setCharacter(null)
        setLocations([])
        setCreationLoading(false)
      } else if (data.type === 'showCreationLoading') {
        if (data.messages && data.messages.length > 0) setCreationMessages(data.messages)
        setVisible(true)
        setCreationLoading(true)
      } else if (data.type === 'hideCreationLoading') {
        setCreationLoading(false)
      }
    }
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  // nt_spawn NUI only opens when needed — no opaque pre-load overlay required
  if (!visible) return null

  return (
    <div className="fixed inset-0">
      {character && (
        <SpawnScreen
          character={character}
          locations={locations}
          onBack={() => nuiFetch('cancelSpawn', {})}
        />
      )}
      {creationLoading && <CreationLoadingOverlay messages={creationMessages} />}
    </div>
  )
}

export default App
