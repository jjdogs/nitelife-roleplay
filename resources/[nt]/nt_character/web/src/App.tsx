import { useEffect, useState } from 'react'

// ── Types ─────────────────────────────────────────────────────────────────────

type Character = {
  citizenid: string
  firstName: string
  middleName: string
  lastName: string
  suffix: string
  dob: string
  nationality: string
  job: string
  properties: number
  playtime: number
  created: string
}

type SpawnLocation = {
  id: string
  label: string
  coords: { x: number; y: number; z: number; w: number }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const emptyForm = { firstName: '', middleName: '', lastName: '', suffix: '', dob: '', nationality: '' }

function charName(c: Character)     { return `${c.firstName} ${c.lastName}` }
function charFullName(c: Character) { return [c.firstName, c.middleName, c.lastName, c.suffix].filter(Boolean).join(' ') }
function charInitials(c: Character) { return `${c.firstName.charAt(0)}${c.lastName.charAt(0)}` }
function charPlaytime(c: Character) { return `${c.playtime}h` }

function nuiFetch<T = unknown>(endpoint: string, data: object): Promise<T | null> {
  return fetch(`https://nt_character/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
    .then(r => r.json() as Promise<T>)
    .catch(() => null)
}

const inputCls =
  'w-full bg-white/[0.06] border border-white/12 rounded px-2.5 py-1.5 text-xs text-white ' +
  'placeholder:text-white/20 focus:outline-none focus:border-white/28 transition-colors duration-150'

// ── Shared components ─────────────────────────────────────────────────────────

function MenuButton({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="w-[200px] py-2.5 px-4 bg-transparent border border-white/15 text-white text-sm tracking-wider rounded transition-all duration-150 hover:bg-white/8 hover:border-white/35 active:scale-95 active:bg-white/12 cursor-pointer"
    >
      {label}
    </button>
  )
}

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

function FormField({ label, required, error, children }: {
  label: string; required?: boolean; error?: string; children: React.ReactNode
}) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-[10px] text-white/35 tracking-wide uppercase">
        {label}{required && <span className="text-white/40 ml-0.5">*</span>}
      </label>
      {children}
      {error && <span className="text-[10px] text-red-400/75 mt-0.5">{error}</span>}
    </div>
  )
}

function EmptySlot() {
  return (
    <div className="flex items-center justify-center rounded-xl border border-white/6 bg-white/[0.012] cursor-default min-h-[148px]">
      <span className="text-xl text-white/12 font-thin">+</span>
    </div>
  )
}

// ── Play screen ───────────────────────────────────────────────────────────────

function CharacterCard({ char, selected, onSelect, onPlay, onBack }: {
  char: Character; selected: boolean; onSelect: () => void; onPlay: () => void; onBack: () => void
}) {
  return (
    <div
      onClick={!selected ? onSelect : undefined}
      className={`flex flex-col rounded-xl border transition-colors duration-200 overflow-hidden
        ${selected
          ? 'border-white/45 bg-white/10 cursor-default shadow-[0_0_28px_rgba(255,255,255,0.04)]'
          : 'border-white/10 bg-white/[0.03] hover:border-white/22 hover:bg-white/[0.06] cursor-pointer'}`}
    >
      <div className="flex flex-col items-center gap-3 p-5">
        <div className={`w-12 h-12 rounded-full flex items-center justify-center text-sm font-semibold transition-colors duration-200 ${selected ? 'bg-white/20' : 'bg-white/10'}`}>
          {charInitials(char)}
        </div>
        <div className="flex flex-col items-center gap-1 text-center">
          <span className="text-sm font-medium text-white/90">{charName(char)}</span>
          <span className="text-xs text-white/45">{char.job}</span>
          <span className="text-xs text-white/30">{charPlaytime(char)} played</span>
        </div>
      </div>

      <div className="grid transition-[grid-template-rows] duration-300 ease-in-out" style={{ gridTemplateRows: selected ? '1fr' : '0fr' }}>
        <div className="overflow-hidden">
          <div className="px-5 pb-5 flex flex-col gap-2.5">
            <div className="h-px bg-white/8 mb-1.5" />
            {[
              { label: 'Full name',     value: charFullName(char) },
              { label: 'Date of birth', value: char.dob },
              { label: 'Created',       value: char.created },
              { label: 'Job',           value: char.job },
              { label: 'Properties',    value: String(char.properties) },
              { label: 'Playtime',      value: charPlaytime(char) },
            ].map(({ label, value }) => (
              <div key={label} className="flex items-center justify-between">
                <span className="text-xs text-white/38">{label}</span>
                <span className="text-xs text-white/75 font-medium">{value}</span>
              </div>
            ))}
            <div className="flex flex-col gap-2 mt-2">
              <button
                onClick={e => { e.stopPropagation(); onPlay() }}
                className="w-full py-2 rounded bg-white text-[#0b1120] text-xs font-semibold tracking-wide transition-all duration-150 hover:bg-white/90 active:scale-95 cursor-pointer"
              >
                Play
              </button>
              <button
                onClick={e => { e.stopPropagation(); onBack() }}
                className="w-full py-2 rounded border border-white/15 text-white/60 text-xs tracking-wide transition-all duration-150 hover:bg-white/8 hover:border-white/28 hover:text-white active:scale-95 cursor-pointer"
              >
                Back
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// ── Delete screen ─────────────────────────────────────────────────────────────

function DeleteCard({ char, selected, onSelect, onDeleted, onBack }: {
  char: Character; selected: boolean; onSelect: () => void; onDeleted: () => void; onBack: () => void
}) {
  const [confirming, setConfirming] = useState(false)

  useEffect(() => { if (!selected) setConfirming(false) }, [selected])

  return (
    <div
      onClick={!selected ? onSelect : undefined}
      className={`flex flex-col rounded-xl border transition-colors duration-200 overflow-hidden
        ${selected
          ? 'border-white/45 bg-white/10 cursor-default shadow-[0_0_28px_rgba(255,255,255,0.04)]'
          : 'border-white/10 bg-white/[0.03] hover:border-white/22 hover:bg-white/[0.06] cursor-pointer'}`}
    >
      <div className="flex flex-col items-center gap-3 p-5">
        <div className={`w-12 h-12 rounded-full flex items-center justify-center text-sm font-semibold transition-colors duration-200 ${selected ? 'bg-white/20' : 'bg-white/10'}`}>
          {charInitials(char)}
        </div>
        <div className="flex flex-col items-center gap-1 text-center">
          <span className="text-sm font-medium text-white/90">{charName(char)}</span>
          <span className="text-xs text-white/45">{char.job}</span>
          <span className="text-xs text-white/30">{charPlaytime(char)} played</span>
        </div>
      </div>

      <div className="grid transition-[grid-template-rows] duration-300 ease-in-out" style={{ gridTemplateRows: selected ? '1fr' : '0fr' }}>
        <div className="overflow-hidden">
          <div className="px-5 pb-5 flex flex-col gap-2.5">
            <div className="h-px bg-white/8 mb-1.5" />
            {[
              { label: 'Full name',     value: charFullName(char) },
              { label: 'Date of birth', value: char.dob },
              { label: 'Job',           value: char.job },
              { label: 'Playtime',      value: charPlaytime(char) },
            ].map(({ label, value }) => (
              <div key={label} className="flex items-center justify-between">
                <span className="text-xs text-white/38">{label}</span>
                <span className="text-xs text-white/75 font-medium">{value}</span>
              </div>
            ))}

            {/* Normal actions */}
            <div className="grid transition-[grid-template-rows] duration-200 ease-in-out" style={{ gridTemplateRows: confirming ? '0fr' : '1fr' }}>
              <div className="overflow-hidden">
                <div className="flex flex-col gap-2 mt-2">
                  <button
                    onClick={e => { e.stopPropagation(); setConfirming(true) }}
                    className="w-full py-2 rounded bg-red-500/75 text-white text-xs font-semibold tracking-wide transition-all duration-150 hover:bg-red-500 active:scale-95 cursor-pointer"
                  >
                    Delete Character
                  </button>
                  <button
                    onClick={e => { e.stopPropagation(); onBack() }}
                    className="w-full py-2 rounded border border-white/15 text-white/60 text-xs tracking-wide transition-all duration-150 hover:bg-white/8 hover:border-white/28 hover:text-white active:scale-95 cursor-pointer"
                  >
                    Back
                  </button>
                </div>
              </div>
            </div>

            {/* Confirmation */}
            <div className="grid transition-[grid-template-rows] duration-200 ease-in-out" style={{ gridTemplateRows: confirming ? '1fr' : '0fr' }}>
              <div className="overflow-hidden">
                <div className="flex flex-col gap-2 mt-2">
                  <p className="text-xs text-white/45 text-center py-1.5 leading-relaxed">
                    Are you sure?<br />
                    <span className="text-white/30">This cannot be undone.</span>
                  </p>
                  <button
                    onClick={e => { e.stopPropagation(); nuiFetch('deleteCharacter', { citizenid: char.citizenid }); onDeleted() }}
                    className="w-full py-2 rounded bg-red-500/75 text-white text-xs font-semibold tracking-wide transition-all duration-150 hover:bg-red-500 active:scale-95 cursor-pointer"
                  >
                    Yes, delete
                  </button>
                  <button
                    onClick={e => { e.stopPropagation(); setConfirming(false) }}
                    className="w-full py-2 rounded border border-white/15 text-white/60 text-xs tracking-wide transition-all duration-150 hover:bg-white/8 hover:border-white/28 hover:text-white active:scale-95 cursor-pointer"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
  )
}

// ── Create screen ─────────────────────────────────────────────────────────────

function CreateSlotCard({ selected, form, errors, serverError, onSelect, onChange, onContinue, onBack }: {
  selected: boolean
  form: typeof emptyForm
  errors: Partial<Record<keyof typeof emptyForm, string>>
  serverError?: string
  onSelect: () => void
  onChange: (field: keyof typeof emptyForm, value: string) => void
  onContinue: () => void
  onBack: () => void
}) {
  return (
    <div
      onClick={!selected ? onSelect : undefined}
      className={`flex flex-col rounded-xl border border-dashed transition-colors duration-200 overflow-hidden
        ${selected
          ? 'border-white/20 bg-white/[0.04] cursor-default'
          : 'border-white/8 bg-white/[0.015] hover:border-white/16 hover:bg-white/[0.03] cursor-pointer'}`}
    >
      <div className="grid transition-[grid-template-rows] duration-300 ease-in-out" style={{ gridTemplateRows: selected ? '0fr' : '1fr' }}>
        <div className="overflow-hidden">
          <div className="flex items-center justify-center h-[96px]">
            <span className="text-2xl text-white/15 font-thin leading-none">+</span>
          </div>
        </div>
      </div>

      <div className="grid transition-[grid-template-rows] duration-300 ease-in-out" style={{ gridTemplateRows: selected ? '1fr' : '0fr' }}>
        <div className="overflow-hidden">
          <div className="px-4 pt-4 pb-4 flex flex-col gap-2.5">
            <FormField label="First name" required error={errors.firstName}>
              <input type="text" value={form.firstName} onChange={e => onChange('firstName', e.target.value)} placeholder="First name" className={inputCls} />
            </FormField>
            <FormField label="Middle name">
              <input type="text" value={form.middleName} onChange={e => onChange('middleName', e.target.value)} placeholder="Middle name" className={inputCls} />
            </FormField>
            <FormField label="Last name" required error={errors.lastName}>
              <input type="text" value={form.lastName} onChange={e => onChange('lastName', e.target.value)} placeholder="Last name" className={inputCls} />
            </FormField>
            <FormField label="Suffix">
              <input type="text" value={form.suffix} onChange={e => onChange('suffix', e.target.value)} placeholder="Jr., Sr., II, etc." className={inputCls} />
            </FormField>
            <FormField label="Date of birth">
              <input type="date" value={form.dob} onChange={e => onChange('dob', e.target.value)} className={inputCls} style={{ colorScheme: 'dark' }} />
            </FormField>
            <FormField label="Nationality">
              <input type="text" value={form.nationality} onChange={e => onChange('nationality', e.target.value)} placeholder="e.g. American" className={inputCls} />
            </FormField>
            <div className="flex flex-col gap-2 mt-1">
              <button
                onClick={e => { e.stopPropagation(); onContinue() }}
                className="w-full py-2 rounded bg-white text-[#0b1120] text-xs font-semibold tracking-wide transition-all duration-150 hover:bg-white/90 active:scale-95 cursor-pointer"
              >
                Continue to Appearance
              </button>
              <button
                onClick={e => { e.stopPropagation(); onBack() }}
                className="w-full py-2 rounded border border-white/15 text-white/60 text-xs tracking-wide transition-all duration-150 hover:bg-white/8 hover:border-white/28 hover:text-white active:scale-95 cursor-pointer"
              >
                Back
              </button>
              {serverError && (
                <p className="text-[10px] text-red-400/75 text-center pt-0.5">{serverError}</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// ── Spawn screen ──────────────────────────────────────────────────────────────

function SpawnLocationCard({ loc, selected, onSelect }: {
  loc: SpawnLocation; selected: boolean; onSelect: () => void
}) {
  return (
    <button
      onClick={onSelect}
      className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl border text-left transition-all duration-150 cursor-pointer
        ${selected
          ? 'border-white/40 bg-white/10 shadow-[0_0_20px_rgba(255,255,255,0.03)]'
          : 'border-white/10 bg-white/[0.03] hover:border-white/22 hover:bg-white/[0.06]'}`}
    >
      <div className={`w-1.5 h-1.5 rounded-full flex-shrink-0 transition-colors duration-150 ${selected ? 'bg-white' : 'bg-white/25'}`} />
      <span className="text-sm text-white/80">{loc.label}</span>
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
    console.log('[nt_character] previewSpawn fetch →', loc.id, loc.coords)
    setSelectedLoc(loc)
    nuiFetch('previewSpawn', { coords: loc.coords })
  }

  function handleSpawn() {
    if (!selectedLoc) return
    nuiFetch('confirmSpawn', { citizenid: character.citizenid, coords: selectedLoc.coords })
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

// ── Screens ───────────────────────────────────────────────────────────────────

function MainMenu({ characters, maxSlots, onPlay, onCreate, onDelete }: {
  characters: Character[]; maxSlots: number; onPlay: () => void; onCreate: () => void; onDelete: () => void
}) {
  const totalPlaytime = characters.reduce((s, c) => s + c.playtime, 0)
  const stats = [
    { label: 'Playtime',     value: `${totalPlaytime}h` },
    { label: 'Characters',   value: `${characters.length} / ${maxSlots}` },
    { label: 'Member since', value: 'Jan 2025' },
    { label: 'Last seen',    value: '2 days ago' },
  ]
  return (
    <div className="fixed inset-0 flex bg-[#0b1120] text-white select-none">
      <div className="flex flex-col w-[60%] h-full px-12 py-10">
        <Logo />
        <div className="flex flex-1 flex-col items-center justify-center gap-3">
          <MenuButton label="Play"             onClick={onPlay} />
          <MenuButton label="Create Character" onClick={onCreate} />
          <MenuButton label="Delete Character" onClick={onDelete} />
        </div>
      </div>
      <div className="flex w-[40%] h-full items-center justify-center pr-12">
        <div className="w-full max-w-xs rounded-xl border border-white/10 bg-white/4 px-6 py-7">
          <p className="text-[10px] font-semibold tracking-[0.2em] uppercase text-white/35 mb-5">Your Stats</p>
          <div className="flex flex-col gap-4">
            {stats.map(({ label, value }) => (
              <div key={label} className="flex items-center justify-between">
                <span className="text-sm text-white/45">{label}</span>
                <span className="text-sm text-white/80 font-medium">{value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function PlayScreen({ characters, maxSlots, onPlay, onBack }: {
  characters: Character[]; maxSlots: number; onPlay: (char: Character) => void; onBack: () => void
}) {
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const emptyCount = maxSlots - characters.length
  return (
    <div className="fixed inset-0 flex flex-col bg-[#0b1120] text-white select-none px-12 py-10">
      <div className="flex items-center justify-between mb-10">
        <Logo />
        <BackLink onClick={onBack} />
      </div>
      <div className="grid grid-cols-4 gap-4 items-start">
        {characters.map(char => (
          <CharacterCard
            key={char.citizenid}
            char={char}
            selected={selectedId === char.citizenid}
            onSelect={() => setSelectedId(char.citizenid)}
            onPlay={() => onPlay(char)}
            onBack={onBack}
          />
        ))}
        {Array.from({ length: emptyCount }, (_, i) => <EmptySlot key={i} />)}
      </div>
    </div>
  )
}

function CreateCharacterScreen({ characters, maxSlots, onBack }: {
  characters: Character[]; maxSlots: number; onBack: () => void
}) {
  const [selectedSlot, setSelectedSlot] = useState<number | null>(null)
  const [form, setForm]                 = useState(emptyForm)
  const [errors, setErrors]             = useState<Partial<Record<keyof typeof emptyForm, string>>>({})
  const [serverError, setServerError]   = useState<string | undefined>(undefined)

  const availableSlots = maxSlots - characters.length

  function handleSlotClick(slot: number) {
    if (selectedSlot === slot) return
    setSelectedSlot(slot)
    setForm(emptyForm)
    setErrors({})
    setServerError(undefined)
  }

  function handleChange(field: keyof typeof emptyForm, value: string) {
    setForm(prev => ({ ...prev, [field]: value }))
    if (errors[field]) setErrors(prev => ({ ...prev, [field]: undefined }))
  }

  async function handleContinue() {
    const next: typeof errors = {}
    if (!form.firstName.trim()) next.firstName = 'First name is required'
    if (!form.lastName.trim())  next.lastName  = 'Last name is required'
    if (Object.keys(next).length) { setErrors(next); return }
    setServerError(undefined)
    const result = await nuiFetch<{ success: boolean; error?: string }>('createCharacter', form)
    if (!result) return
    if (!result.success) {
      setServerError(result.error ?? 'Failed to create character')
      return
    }
    setSelectedSlot(null)
    setForm(emptyForm)
    setErrors({})
  }

  return (
    <div className="fixed inset-0 flex flex-col bg-[#0b1120] text-white select-none px-12 py-10">
      <div className="flex items-center justify-between mb-10">
        <Logo />
        <BackLink onClick={onBack} />
      </div>
      <div className="grid grid-cols-4 gap-4 items-start">
        {Array.from({ length: availableSlots }, (_, slot) => (
          <CreateSlotCard
            key={slot}
            selected={selectedSlot === slot}
            form={selectedSlot === slot ? form : emptyForm}
            errors={selectedSlot === slot ? errors : {}}
            serverError={selectedSlot === slot ? serverError : undefined}
            onSelect={() => handleSlotClick(slot)}
            onChange={handleChange}
            onContinue={handleContinue}
            onBack={onBack}
          />
        ))}
      </div>
    </div>
  )
}

function DeleteCharacterScreen({ characters, maxSlots, onBack }: {
  characters: Character[]; maxSlots: number; onBack: () => void
}) {
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const emptyCount = maxSlots - characters.length
  return (
    <div className="fixed inset-0 flex flex-col bg-[#0b1120] text-white select-none px-12 py-10">
      <div className="flex items-center justify-between mb-10">
        <Logo />
        <BackLink onClick={onBack} />
      </div>
      <div className="grid grid-cols-4 gap-4 items-start">
        {characters.map(char => (
          <DeleteCard
            key={char.citizenid}
            char={char}
            selected={selectedId === char.citizenid}
            onSelect={() => setSelectedId(char.citizenid)}
            onDeleted={() => setSelectedId(null)}
            onBack={onBack}
          />
        ))}
        {Array.from({ length: emptyCount }, (_, i) => <EmptySlot key={i} />)}
      </div>
    </div>
  )
}

// ── Root ──────────────────────────────────────────────────────────────────────

function App() {
  const [visible, setVisible]             = useState(false)
  const [screen, setScreen]               = useState<'menu' | 'play' | 'create' | 'delete' | 'spawn'>('menu')
  const [characters, setCharacters]       = useState<Character[]>([])
  const [maxSlots, setMaxSlots]           = useState(4)
  const [spawnCharacter, setSpawnCharacter] = useState<Character | null>(null)
  const [spawnLocations, setSpawnLocations] = useState<SpawnLocation[]>([])

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const data = event.data
      if (data.action === 'open') {
        setScreen(data.screen ?? 'menu')
        setVisible(true)
      } else if (data.action === 'setCharacters') {
        setCharacters(data.characters ?? [])
        setMaxSlots(data.maxSlots ?? 4)
      } else if (data.action === 'setSpawnLocations') {
        setSpawnLocations(data.locations ?? [])
      } else if (data.action === 'close') {
        setVisible(false)
        setSpawnCharacter(null)
        setSpawnLocations([])
      }
    }
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  if (!visible) return null

  function handlePlay(char: Character) {
    setSpawnCharacter(char)
    setSpawnLocations([])
    setScreen('spawn')
    nuiFetch('playCharacter', { citizenid: char.citizenid })
  }

  const screenProps = { characters, maxSlots, onBack: () => setScreen('menu') }

  return (
    <div className="fixed inset-0">
      {screen === 'menu'   && <MainMenu   {...screenProps} onPlay={() => setScreen('play')} onCreate={() => setScreen('create')} onDelete={() => setScreen('delete')} />}
      {screen === 'play'   && <PlayScreen {...screenProps} onPlay={handlePlay} />}
      {screen === 'create' && <CreateCharacterScreen {...screenProps} />}
      {screen === 'delete' && <DeleteCharacterScreen {...screenProps} />}
      {screen === 'spawn'  && spawnCharacter && (
        <SpawnScreen
          character={spawnCharacter}
          locations={spawnLocations}
          onBack={() => setScreen('play')}
        />
      )}

      {screen !== 'spawn' && (
        <button
          onClick={() => nuiFetch('closeUI', {})}
          className="fixed top-4 right-4 w-8 h-8 flex items-center justify-center rounded-lg bg-white/5 border border-white/10 text-white/35 hover:bg-white/10 hover:text-white/65 transition-all duration-150 cursor-pointer z-50 text-lg leading-none"
          title="Close"
        >
          ×
        </button>
      )}
    </div>
  )
}

export default App
