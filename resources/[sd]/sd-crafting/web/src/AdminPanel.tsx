import { useState, useEffect, useCallback, useRef, memo } from 'react';
import { Search, X, Users, Clock, MapPin, BookOpen, RefreshCw, Trash2, Play, XCircle, ChevronDown, ChevronUp, ChevronLeft, ChevronRight, Edit3, RotateCcw, Check, AlertTriangle, Wifi, WifiOff, Layers, Plus, Minus, Package, GitBranch, Settings, SlidersHorizontal } from 'lucide-react';
import { useTranslation } from './locales/i18n';

interface AdminPanelProps {
  fetchNui: <T = any>(eventName: string, data?: any) => Promise<T>;
  showToast: (message: string, type: 'error' | 'success' | 'info') => void;
}

interface AdminPlayer {
  identifier: string;
  xp: number;
  level: number;
  tech_points: number;
  workbench_levels: Record<string, { xp: number; level: number }>;
  workbench_tech?: Record<string, { tech_points: number; unlocked_nodes: string[] | Record<string, boolean> }>;
  unlocked_nodes: Record<string, boolean>;
  online: boolean;
  playerName?: string;
  charName?: string;
  serverId?: number;
  hasQueue?: boolean;
  lastSeen?: string;
}

interface AccessibleStationTech {
  workbenchId: number;
  stationKey: string;
  type: string;
  tech_points: number;
  unlocked_nodes: string[] | Record<string, boolean>;
  isOwner: boolean;
  label: string;
}

interface AdminPlayerDetail extends AdminPlayer {
  queue?: {
    queue: AdminQueueItem[];
    stationId: string;
    workbenchType: string;
  };
  accessible_station_tech?: AccessibleStationTech[];
  ownedStations?: number;
}

interface LevelConfig {
  levels: Record<number, number>;
  maxLevel: number;
}

interface AdminQueueIngredient {
  item: string;
  label: string;
  amount: number;
}

interface AdminQueueItem {
  type?: string;
  identifier: string;
  ownerName?: string;
  id: string;
  recipeId: string;
  recipeName: string;
  recipeLabel?: string;
  outputAmount?: number;
  ingredients?: AdminQueueIngredient[];
  quantity: number;
  startTime: number;
  totalTime: number;
  remainingTime: number;
  stationId: string;
  workbenchType?: string;
  craftToken?: string;
}

interface AdminStation {
  id: number | string;
  stationKey: string;
  isStatic?: boolean;
  isAdmin?: boolean;
  isPlaced?: boolean;
  owner: string;
  ownerName?: string;
  ownerOnline?: boolean;
  item: string;
  type: string;
  prop: string | { model: string; enabled: boolean; spawnRadius?: number } | null;
  coords: { x: number; y: number; z: number };
  heading: number;
  sharedQueueCount?: number;
  sharedCrafting?: boolean;
  sharedStaging?: boolean;
  sharedTech?: boolean;
  label?: string;
  radius?: number;
  recipes?: string[];
  techTrees?: string[];
  blip?: { enabled: boolean; sprite: number; color: number; scale: number; label: string };
  job?: Array<{ name: string; minGrade?: number }> | { name: string; minGrade?: number } | null;
  gang?: Array<{ name: string; minGrade?: number }> | string | null;
}

interface StationFormData {
  label: string;
  type: string;
  radius: string;
  propModel: string;
  propEnabled: boolean;
  propSpawnRadius: string;
  recipes: string[];
  techTrees: string[];
  owner: string;
  blipEnabled: boolean;
  blipSprite: string;
  blipColor: string;
  blipScale: string;
  blipLabel: string;
  sharedCrafting: boolean;
  sharedStaging: boolean;
  sharedTech: boolean;
  stationTechPoints: string;
  coords: { x: number; y: number; z: number } | null;
  heading: number;
  jobs: Array<{ name: string; minGrade: number }>;
  gangs: Array<{ name: string; minGrade: number }>;
}

interface AdminIngredient {
  item: string;
  label: string;
  amount: number;
}

interface AdminTool {
  item: string;
  label: string;
  amount: number;
  consumptionType?: string;
  durabilityLoss?: number;
  consumeChance?: number;
}

interface AdminRecipe {
  id: string;
  name: string;
  label: string;
  craftTime: number;
  ingredients: AdminIngredient[];
  tools?: AdminTool[];
  image?: string;
  category?: string;
  levelRequired?: number;
  xpReward?: number;
  techPointsReward?: number;
  outputAmount?: number;
  failChance?: number;
  blueprint?: string;
  blueprintDurabilityLoss?: number;
  cost?: number;
  enabled: boolean;
  metadata?: Record<string, any>;
  showMetadata?: Record<string, string>;
}

interface RecipeFormData {
  name: string;
  label: string;
  tableName: string;
  craftTime: string;
  levelRequired: string;
  xpReward: string;
  techPointsReward: string;
  outputAmount: string;
  failChance: string;
  blueprint: string;
  blueprintDurabilityLoss: string;
  cost: string;
  image: string;
  enabled: boolean;
  ingredients: { item: string; amount: string; label: string }[];
  tools: { item: string; amount: string; consumptionType: string; durabilityLoss: string; consumeChance: string }[];
  metadata: { key: string; value: string }[];
  showMetadata: { key: string; label: string }[];
}

interface StagedItem {
  item: string;
  label?: string;
  count: number;
  slot: number;
  durability?: number;
  metadata?: Record<string, any>;
}

interface StationInventory {
  stagingKey: string;
  isShared: boolean;
  items: StagedItem[];
  itemCount: number;
}

interface TechTreeNode {
  id: string;
  recipeId: string;
  cost: number;
  prerequisites: string[];
  position: { row: number; col: number };
}

interface AdminTechTree {
  label: string;
  icon: string;
  color: string;
  nodes: TechTreeNode[];
  source?: 'config' | 'admin';
}

interface TechTreeFormData {
  treeId: string;
  label: string;
  icon: string;
  color: string;
}

interface NodeFormData {
  id: string;
  recipeId: string;
  cost: string;
  prerequisites: string[];
  position: { row: string; col: string };
}

interface WorkbenchType {
  name: string;
  source: 'config' | 'admin';
  stations: { key: string; label: string }[];
}

type AdminTab = 'players' | 'queues' | 'stations' | 'recipes' | 'techtrees';

/**
 * Capitalize the first letter of a string.
 */
const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

/**
 * Get the image URL for an item, falling back to ox_inventory images.
 */
const getItemImage = (itemName: string): string => {
  return `nui://ox_inventory/web/images/${itemName}.png`;
};

/**
 * Item image with error fallback to a Package icon.
 */
const ItemImage = memo(({ src, alt, className = '' }: { src: string; alt: string; className?: string }) => {
  const [hasError, setHasError] = useState(false);

  useEffect(() => { setHasError(false); }, [src]);

  if (hasError) {
    return <Package className={className} style={{ opacity: 0.3 }} />;
  }

  return (
    <img
      src={src}
      alt={alt}
      className={className}
      onError={() => setHasError(true)}
      draggable={false}
    />
  );
});

/**
 * Build a RecipeFormData from an AdminRecipe for editing.
 */
const recipeToForm = (recipe: AdminRecipe, tableName: string): RecipeFormData => ({
  name: recipe.name,
  label: recipe.label,
  tableName,
  craftTime: String(recipe.craftTime),
  levelRequired: String(recipe.levelRequired || 0),
  xpReward: String(recipe.xpReward || 0),
  techPointsReward: String(recipe.techPointsReward || 0),
  outputAmount: String(recipe.outputAmount || 1),
  failChance: String(recipe.failChance || 0),
  blueprint: recipe.blueprint || '',
  blueprintDurabilityLoss: String(recipe.blueprintDurabilityLoss || 0),
  cost: String(recipe.cost || 0),
  image: recipe.image || '',
  enabled: recipe.enabled,
  ingredients: recipe.ingredients.map(i => ({ item: i.item, amount: String(i.amount), label: i.label })),
  tools: (recipe.tools || []).map(t => ({
    item: t.item,
    amount: String(t.amount),
    consumptionType: t.consumptionType || 'none',
    durabilityLoss: String(t.durabilityLoss || 0),
    consumeChance: String(t.consumeChance || 0),
  })),
  metadata: recipe.metadata ? Object.entries(recipe.metadata).map(([key, value]) => ({ key, value: String(value) })) : [],
  showMetadata: recipe.showMetadata ? Object.entries(recipe.showMetadata).map(([key, label]) => ({ key, label: String(label) })) : [],
});

/**
 * Build a blank RecipeFormData for creating a new recipe.
 */
const blankRecipeForm = (tableName: string): RecipeFormData => ({
  name: '',
  label: '',
  tableName,
  craftTime: '5',
  levelRequired: '0',
  xpReward: '0',
  techPointsReward: '0',
  outputAmount: '1',
  failChance: '0',
  blueprint: '',
  blueprintDurabilityLoss: '0',
  cost: '0',
  image: '',
  enabled: true,
  ingredients: [{ item: '', amount: '1', label: '' }],
  tools: [],
  metadata: [],
  showMetadata: [],
});

/**
 * Dual-layer noise overlay for the admin panel.
 * Layer 1: fractalNoise with soft-light blend for subtle tonal variation.
 * Layer 2: turbulence grain for visible dot texture.
 * Increased opacity vs main crafting UI to stay visible against solid background.
 */
const NoiseOverlay = memo(() => (
  <>
    <div className="absolute inset-0 pointer-events-none z-[1]"
      style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px',
        opacity: 0.06,
        mixBlendMode: 'soft-light' as const,
      }}
    />
    <div className="absolute inset-0 pointer-events-none z-[1]"
      style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='grain'%3E%3CfeTurbulence type='turbulence' baseFrequency='0.7' numOctaves='3' stitchTiles='stitch'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23grain)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '100px 100px',
        opacity: 0.08,
      }}
    />
  </>
));

/**
 * Confirmation dialog component for destructive actions.
 * Renders a centered modal overlay with cancel/confirm buttons.
 * Supports an optional quantity slider for partial removals.
 */
const ConfirmDialog = ({ message, onConfirm, onCancel, slider }: {
  message: string;
  onConfirm: (count?: number) => void;
  onCancel: () => void;
  slider?: { min: number; max: number; label: string };
}) => {
  const { t } = useTranslation();
  const [sliderValue, setSliderValue] = useState(slider?.max ?? 1);
  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center" style={{ backgroundColor: 'rgba(0,0,0,0.6)' }}>
      <div className="relative rounded-xl p-6 max-w-sm w-full mx-4 border overflow-hidden" style={{ backgroundColor: '#0c0c0e', borderColor: 'rgba(255,255,255,0.08)' }}>
        <NoiseOverlay />
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-4">
            <AlertTriangle className="w-5 h-5 text-yellow-400 flex-shrink-0" />
            <p className="text-white text-sm">{message}</p>
          </div>
          {slider && slider.max > 1 && (
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-gray-400 text-[11px]">{slider.label}</span>
                <div className="flex items-center gap-1.5">
                  <button
                    onClick={() => setSliderValue(v => Math.max(slider.min, v - 1))}
                    className="w-5 h-5 rounded flex items-center justify-center text-gray-400 hover:text-white transition-colors"
                    style={{ backgroundColor: '#252528' }}
                  >
                    <Minus className="w-3 h-3" />
                  </button>
                  <span className="text-white text-xs font-medium w-8 text-center">{sliderValue}</span>
                  <button
                    onClick={() => setSliderValue(v => Math.min(slider.max, v + 1))}
                    className="w-5 h-5 rounded flex items-center justify-center text-gray-400 hover:text-white transition-colors"
                    style={{ backgroundColor: '#252528' }}
                  >
                    <Plus className="w-3 h-3" />
                  </button>
                </div>
              </div>
              <input
                type="range"
                min={slider.min}
                max={slider.max}
                value={sliderValue}
                onChange={e => setSliderValue(Number(e.target.value))}
                className="w-full h-1 rounded-full appearance-none cursor-pointer"
                style={{
                  background: `linear-gradient(to right, rgba(239,68,68,0.8) 0%, rgba(239,68,68,0.8) ${((sliderValue - slider.min) / (slider.max - slider.min)) * 100}%, #252528 ${((sliderValue - slider.min) / (slider.max - slider.min)) * 100}%, #252528 100%)`,
                }}
              />
              <div className="flex justify-between mt-1">
                <span className="text-gray-600 text-[9px]">{slider.min}</span>
                <span className="text-gray-600 text-[9px]">{slider.max}</span>
              </div>
            </div>
          )}
          <div className="flex gap-3 justify-end">
            <button onClick={onCancel} className="px-4 py-1.5 text-xs rounded-lg text-gray-400 hover:text-white transition-colors" style={{ backgroundColor: '#252528' }}>
              {t('admin.common.cancel')}
            </button>
            <button onClick={() => onConfirm(slider ? sliderValue : undefined)} className="px-4 py-1.5 text-xs rounded-lg text-white transition-colors hover:brightness-110" style={{ backgroundColor: 'rgba(239,68,68,0.8)' }}>
              {slider && slider.max > 1 ? t('admin.common.removeCount', { count: sliderValue }) : t('admin.common.confirm')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

/**
 * Styled text input for the recipe editor form.
 */
const FormInput = ({ label, value, onChange, placeholder }: {
  label: string; value: string; onChange: (v: string) => void; placeholder?: string;
}) => (
  <div>
    <div className="text-gray-500 text-[10px] font-medium mb-1">{label}</div>
    <input
      type="text"
      value={value}
      onChange={e => onChange(e.target.value)}
      placeholder={placeholder}
      className="w-full rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
      style={{ backgroundColor: '#252528' }}
    />
  </div>
);

/**
 * Numeric input with inline stepper arrows (up/down chevrons on the right).
 * Supports min, max, step. Value is stored/returned as string for form consistency.
 */
const NumberInput = ({ label, value, onChange, min, max, step = 1, placeholder, className: extraClass }: {
  label?: string; value: string; onChange: (v: string) => void;
  min?: number; max?: number; step?: number; placeholder?: string; className?: string;
}) => {
  const clamp = (n: number) => {
    if (min != null && n < min) return min;
    if (max != null && n > max) return max;
    return n;
  };
  const increment = () => {
    const current = parseFloat(value) || 0;
    onChange(String(clamp(+(current + step).toFixed(4))));
  };
  const decrement = () => {
    const current = parseFloat(value) || 0;
    onChange(String(clamp(+(current - step).toFixed(4))));
  };
  const input = (
    <div className={`flex rounded-md overflow-hidden border border-transparent focus-within:border-white/10 ${extraClass || ''}`} style={{ backgroundColor: '#252528' }}>
      <input
        type="text"
        inputMode="decimal"
        value={value}
        onChange={e => {
          const v = e.target.value;
          if (v === '' || v === '-' || /^-?\d*\.?\d*$/.test(v)) onChange(v);
        }}
        onBlur={() => {
          const n = parseFloat(value);
          if (!isNaN(n)) onChange(String(clamp(n)));
        }}
        placeholder={placeholder}
        className="flex-1 min-w-0 bg-transparent px-2.5 py-1.5 text-white text-xs focus:outline-none"
      />
      <div className="flex flex-col border-l" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
        <button
          type="button"
          onClick={increment}
          className="px-1.5 flex items-center justify-center text-gray-600 hover:text-white transition-colors"
          style={{ height: '50%' }}
          tabIndex={-1}
        >
          <ChevronUp className="w-3 h-3" />
        </button>
        <button
          type="button"
          onClick={decrement}
          className="px-1.5 flex items-center justify-center text-gray-600 hover:text-white transition-colors border-t"
          style={{ height: '50%', borderColor: 'rgba(255,255,255,0.06)' }}
          tabIndex={-1}
        >
          <ChevronDown className="w-3 h-3" />
        </button>
      </div>
    </div>
  );
  if (!label) return input;
  return (
    <div>
      <div className="text-gray-500 text-[10px] font-medium mb-1">{label}</div>
      {input}
    </div>
  );
};

/**
 * Multi-select dropdown with checkboxes for picking from a list of options.
 * Selected items are shown as removable tags.
 */
const MultiSelectDropdown = ({ label, options, selected, onChange, placeholder }: {
  label: string; options: string[]; selected: string[]; onChange: (v: string[]) => void; placeholder?: string;
}) => {
  const { t } = useTranslation();
  const [isOpen, setIsOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const toggle = (option: string) => {
    if (selected.includes(option)) {
      onChange(selected.filter(s => s !== option));
    } else {
      onChange([...selected, option]);
    }
  };

  return (
    <div ref={ref} className="relative">
      <div className="text-gray-500 text-[10px] font-medium mb-1">{label}</div>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="w-full rounded-md px-2.5 py-1.5 text-left text-xs border border-transparent focus:border-white/10 focus:outline-none flex items-center justify-between gap-1"
        style={{ backgroundColor: '#252528' }}
      >
        <span className={selected.length > 0 ? 'text-white' : 'text-gray-500'}>
          {selected.length > 0 ? selected.join(', ') : (placeholder || t('admin.common.select'))}
        </span>
        <ChevronDown className={`w-3.5 h-3.5 text-gray-600 transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
      </button>
      <div className="flex flex-wrap gap-1.5 mt-1.5">
        {selected.length > 0 ? (
          selected.map(s => (
            <span
              key={s}
              className="flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] text-[#4ADE80] cursor-pointer hover:brightness-125"
              style={{ backgroundColor: 'rgba(74,222,128,0.1)' }}
              onClick={() => toggle(s)}
            >
              {s} <X className="w-2.5 h-2.5" />
            </span>
          ))
        ) : (
          <span className="px-2 py-0.5 rounded-md text-[10px] text-gray-500" style={{ backgroundColor: 'rgba(255,255,255,0.04)' }}>{t('admin.common.none')}</span>
        )}
      </div>
      {isOpen && (
        <div
          className="absolute z-50 mt-1 w-full rounded-lg border overflow-hidden shadow-lg max-h-48 overflow-y-auto"
          style={{ backgroundColor: '#0c0c0e', borderColor: 'rgba(255,255,255,0.08)' }}
        >
          {options.length === 0 ? (
            <div className="px-3 py-2.5 text-gray-500 text-[11px]">{t('admin.common.noOptionsAvailable')}</div>
          ) : (
            options.map(option => (
              <button
                key={option}
                type="button"
                onClick={() => toggle(option)}
                className="w-full flex items-center gap-2.5 px-3 py-2 text-left text-xs hover:bg-white/5 transition-colors"
              >
                <div
                  className={`w-4 h-4 rounded border flex items-center justify-center flex-shrink-0 ${selected.includes(option) ? 'border-[#4ADE80]' : 'border-gray-600'}`}
                  style={selected.includes(option) ? { backgroundColor: 'rgba(74,222,128,0.2)' } : {}}
                >
                  {selected.includes(option) && <Check className="w-3 h-3 text-[#4ADE80]" />}
                </div>
                <span className={selected.includes(option) ? 'text-white' : 'text-gray-400'}>{option}</span>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  );
};

/**
 * Single-select dropdown matching the MultiSelectDropdown style.
 * Replaces native <select> elements for consistent UI.
 */
const SelectDropdown = memo(({ label, options, value, onChange, placeholder, className }: {
  label?: string;
  options: { value: string; label: string }[];
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  className?: string;
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const selectedOption = options.find(o => o.value === value);

  return (
    <div ref={ref} className={`relative ${className || ''}`}>
      {label && <div className="text-gray-500 text-[10px] font-medium mb-1">{label}</div>}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="w-full rounded-md px-2.5 py-1.5 text-left text-xs border border-transparent focus:border-white/10 focus:outline-none flex items-center justify-between gap-1 cursor-pointer"
        style={{ backgroundColor: '#252528' }}
      >
        <span className={selectedOption ? 'text-white' : 'text-gray-500'}>
          {selectedOption ? selectedOption.label : (placeholder || 'Select...')}
        </span>
        <ChevronDown className={`w-3.5 h-3.5 text-gray-600 transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
      </button>
      {isOpen && (
        <div
          className="absolute z-50 mt-1 w-full rounded-lg border overflow-hidden shadow-lg max-h-48 overflow-y-auto"
          style={{ backgroundColor: '#0c0c0e', borderColor: 'rgba(255,255,255,0.08)' }}
        >
          {options.length === 0 ? (
            <div className="px-3 py-2.5 text-gray-500 text-[11px]">No options</div>
          ) : (
            options.map(option => (
              <button
                key={option.value}
                type="button"
                onClick={() => { onChange(option.value); setIsOpen(false); }}
                className={`w-full flex items-center gap-2.5 px-3 py-2 text-left text-xs transition-colors ${
                  option.value === value ? 'bg-white/5' : 'hover:bg-white/5'
                }`}
              >
                <div
                  className={`w-3 h-3 rounded-full border flex-shrink-0 ${option.value === value ? 'border-[#4ADE80]' : 'border-gray-600'}`}
                  style={option.value === value ? { backgroundColor: 'rgba(74,222,128,0.4)' } : {}}
                />
                <span className={option.value === value ? 'text-white' : 'text-gray-400'}>{option.label}</span>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  );
});

/**
 * Searchable single-select dropdown for picking a recipe.
 * Shows recipe label, ID, and table name. Typing filters the list.
 * Recipes already assigned to a tech node appear greyed out with usage info.
 * @param label - Field label text
 * @param options - Array of recipe option objects
 * @param value - Currently selected recipe ID
 * @param onChange - Callback when selection changes
 * @param placeholder - Placeholder text when nothing is selected
 * @param usedBy - Map of recipe IDs to their current tech tree assignment
 * @param currentRecipeId - The recipe ID currently assigned to the node being edited (excluded from "in use" check)
 * @param onLocate - Callback when the user clicks "show" on an in-use recipe
 */
const SearchableRecipeDropdown = ({ label, options, value, onChange, placeholder, usedBy, currentRecipeId, onLocate }: {
  label: string;
  options: { id: string; label: string; table: string }[];
  value: string;
  onChange: (id: string) => void;
  placeholder?: string;
  usedBy?: Record<string, { treeId: string; treeName: string; nodeId: string }>;
  currentRecipeId?: string;
  onLocate?: (treeId: string, nodeId: string) => void;
}) => {
  const { t } = useTranslation();
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const ref = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setIsOpen(false);
        setSearch('');
      }
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const filtered = options.filter(opt =>
    (opt.id || '').toLowerCase().includes(search.toLowerCase()) ||
    (opt.label || '').toLowerCase().includes(search.toLowerCase()) ||
    (opt.table || '').toLowerCase().includes(search.toLowerCase())
  );

  const selectedOpt = options.find(o => o.id === value);

  return (
    <div ref={ref} className="relative">
      <div className="text-gray-400 text-[10px] font-medium mb-1">{label}</div>
      <button
        type="button"
        onClick={() => {
          setIsOpen(!isOpen);
          setSearch('');
          setTimeout(() => inputRef.current?.focus(), 0);
        }}
        className="w-full rounded-md px-2.5 py-1.5 text-left text-xs border border-transparent focus:border-white/10 focus:outline-none flex items-center justify-between gap-1"
        style={{ backgroundColor: '#252528' }}
      >
        <span className={value ? 'text-white' : 'text-gray-500'}>
          {selectedOpt ? `${selectedOpt.label} (${selectedOpt.id})` : (placeholder || t('admin.common.selectRecipe'))}
        </span>
        <ChevronDown className={`w-3 h-3 text-gray-600 transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
      </button>
      {isOpen && (
        <div
          className="absolute z-50 mt-1 w-full rounded-lg border overflow-hidden shadow-lg"
          style={{ backgroundColor: '#0c0c0e', borderColor: 'rgba(255,255,255,0.08)' }}
        >
          <div className="px-2.5 py-2 border-b" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
            <input
              ref={inputRef}
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full bg-transparent text-white text-xs outline-none placeholder-gray-600"
              placeholder={t('admin.common.filterPlaceholder')}
              autoFocus
            />
          </div>
          <div className="max-h-48 overflow-y-auto">
            {filtered.length === 0 ? (
              <div className="px-3 py-2 text-gray-500 text-[10px]">{t('admin.common.noRecipesFound')}</div>
            ) : (
              filtered.map(opt => {
                const usage = usedBy?.[opt.id];
                const isInUse = usage && opt.id !== currentRecipeId;

                return (
                  <div
                    key={opt.id}
                    className={`w-full flex items-center px-3 py-2 text-left transition-colors ${isInUse ? 'opacity-50' : 'hover:bg-white/5'} ${opt.id === value ? 'bg-white/5' : ''}`}
                  >
                    <button
                      type="button"
                      disabled={!!isInUse}
                      onClick={() => {
                        if (!isInUse) {
                          onChange(opt.id);
                          setIsOpen(false);
                          setSearch('');
                        }
                      }}
                      className="flex-1 flex flex-col text-left min-w-0"
                    >
                      <div className="flex items-center gap-2">
                        <span className={`text-xs truncate ${isInUse ? 'text-gray-600' : opt.id === value ? 'text-[#4ADE80]' : 'text-white'}`}>{opt.label}</span>
                        <span className="text-[10px] text-gray-600 flex-shrink-0">{opt.table}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] text-gray-500 truncate">{opt.id}</span>
                        {isInUse && (
                          <span className="text-[9px] text-amber-500/80 flex-shrink-0">{t('admin.common.inUse', { treeName: usage.treeName, nodeId: usage.nodeId })}</span>
                        )}
                      </div>
                    </button>
                    {isInUse && onLocate && (
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setIsOpen(false);
                          setSearch('');
                          onLocate(usage.treeId, usage.nodeId);
                        }}
                        className="ml-2 px-2 py-0.5 rounded text-[9px] text-amber-400 flex-shrink-0 hover:bg-amber-400/10 transition-colors"
                        title={t('admin.common.goTo', { treeName: usage.treeName, nodeId: usage.nodeId })}
                      >
                        {t('admin.common.show')}
                      </button>
                    )}
                  </div>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
};

/**
 * Reusable modal overlay for forms (Create/Edit Recipe, Create/Edit Station).
 * Renders a centered card over a dimmed backdrop with close-on-backdrop-click.
 * @param title - Header text displayed in the modal
 * @param onClose - Callback when the modal is dismissed
 * @param children - Form content rendered inside the modal body
 * @param accentColor - Optional accent color for the title (defaults to #4ADE80)
 */
const FormModal = ({ title, onClose, children, accentColor = '#4ADE80' }: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
  accentColor?: string;
}) => (
  <div
    className="fixed inset-0 z-50 flex items-center justify-center"
    style={{ backgroundColor: 'rgba(0,0,0,0.6)' }}
    onMouseDown={e => { if (e.target === e.currentTarget) onClose(); }}
  >
    <div className="relative rounded-xl p-6 w-full mx-4 border overflow-hidden max-h-[85vh] overflow-y-auto" style={{ backgroundColor: '#0c0c0e', borderColor: 'rgba(255,255,255,0.08)', maxWidth: '860px' }}>
      <NoiseOverlay />
      <div className="relative z-10 space-y-4">
        <div className="flex items-center justify-between mb-1">
          <div className="text-sm font-semibold" style={{ color: accentColor }}>{title}</div>
          <button onClick={onClose} className="text-gray-600 hover:text-white transition-colors p-1 rounded hover:bg-white/10">
            <X className="w-4 h-4" />
          </button>
        </div>
        {children}
      </div>
    </div>
  </div>
);

/**
 * Section wrapper for grouping related form fields.
 * Renders a subtle bordered container with an optional section label.
 */
const FormSection = ({ label, children, className }: {
  label?: string;
  children: React.ReactNode;
  className?: string;
}) => (
  <div className={`rounded-lg border p-3.5 space-y-3 ${className || ''}`} style={{ borderColor: 'rgba(255,255,255,0.06)', backgroundColor: 'rgba(255,255,255,0.015)' }}>
    {label && <div className="text-[10px] font-medium uppercase tracking-wider text-gray-500 -mt-0.5 mb-0.5">{label}</div>}
    {children}
  </div>
);

/**
 * Full admin panel overlay for managing crafting system data.
 * Provides tabs for Players, Queues, Stations, and Recipes management.
 */
const ADMIN_TAB_KEY = 'sd-crafting:adminTab';
const validTabs: AdminTab[] = ['players', 'queues', 'stations', 'recipes', 'techtrees'];

const AdminPanel = ({ fetchNui, showToast }: AdminPanelProps) => {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<AdminTab>(() => {
    const saved = localStorage.getItem(ADMIN_TAB_KEY) as AdminTab | null;
    return saved && validTabs.includes(saved) ? saved : 'players';
  });
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(false);
  const [confirm, setConfirm] = useState<{ message: string; onConfirm: (count?: number) => void; slider?: { min: number; max: number; label: string } } | null>(null);

  // Players state
  const [players, setPlayers] = useState<AdminPlayer[]>([]);
  const [playersPage, setPlayersPage] = useState(1);
  const [playersTotalPages, setPlayersTotalPages] = useState(1);
  const [playersTotal, setPlayersTotal] = useState(0);
  const [playersSearch, setPlayersSearch] = useState('');
  const PLAYERS_PER_PAGE = 50;
  const [selectedPlayer, setSelectedPlayer] = useState<AdminPlayerDetail | null>(null);
  const [editingPlayer, setEditingPlayer] = useState<{
    workbench_levels: Record<string, { xp: string; level: string }>;
  } | null>(null);
  const [levelConfigs, setLevelConfigs] = useState<Record<string, LevelConfig>>({});
  const [levelConfigsFetched, setLevelConfigsFetched] = useState(false);

  // Queues state
  const [queues, setQueues] = useState<AdminQueueItem[]>([]);

  // Stations state
  const [stations, setStations] = useState<AdminStation[]>([]);
  const [stationInventoryMap, setStationInventoryMap] = useState<Record<string, StationInventory[]>>({});
  const [inventoryModalStation, setInventoryModalStation] = useState<AdminStation | null>(null);
  const [loadingInventoryModal, setLoadingInventoryModal] = useState(false);
  const [expandedInventories, setExpandedInventories] = useState<Set<string>>(new Set());
  const [addItemTarget, setAddItemTarget] = useState<string | null>(null);
  const [addItemName, setAddItemName] = useState('');
  const [addItemCount, setAddItemCount] = useState(1);
  const [addItemLoading, setAddItemLoading] = useState(false);
  const [stationPlayerTech, setStationPlayerTech] = useState<{ identifier: string; name: string; tech_points: number; isOwner: boolean }[]>([]);
  const [stationPlayerTechOpen, setStationPlayerTechOpen] = useState(false);
  const [stationPlayerTechEdits, setStationPlayerTechEdits] = useState<Record<string, string>>({});
  const [stationPlayerTechLoading, setStationPlayerTechLoading] = useState(false);
  const [jobInputName, setJobInputName] = useState('');
  const [jobInputGrade, setJobInputGrade] = useState('0');
  const [gangInputName, setGangInputName] = useState('');
  const [gangInputGrade, setGangInputGrade] = useState('0');

  // Recipes state
  const [recipes, setRecipes] = useState<Record<string, AdminRecipe[]>>({});
  const [tableSources, setTableSources] = useState<Record<string, 'config' | 'admin'>>({});
  const [selectedTable, setSelectedTable] = useState<string>('');
  const [expandedRecipe, setExpandedRecipe] = useState<string | null>(null);
  const [editingRecipe, setEditingRecipe] = useState<RecipeFormData | null>(null);
  const [editingRecipeId, setEditingRecipeId] = useState<string | null>(null);
  const [isCreatingRecipe, setIsCreatingRecipe] = useState(false);
  const [showManageTables, setShowManageTables] = useState(false);
  const [newTableName, setNewTableName] = useState('');

  // Tech trees state
  const [techTrees, setTechTrees] = useState<Record<string, AdminTechTree>>({});
  const [selectedTree, setSelectedTree] = useState<string | null>(null);
  const [editingTree, setEditingTree] = useState<TechTreeFormData | null>(null);
  const [isCreatingTree, setIsCreatingTree] = useState(false);
  const [editingNode, setEditingNode] = useState<NodeFormData | null>(null);
  const [editingNodeId, setEditingNodeId] = useState<string | null>(null);
  const [isCreatingNode, setIsCreatingNode] = useState(false);

  // Tech tree grid pan/zoom state
  const [treePan, setTreePan] = useState({ x: 0, y: 0 });
  const [treeZoom, setTreeZoom] = useState(0.85);
  const [isPanningTree, setIsPanningTree] = useState(false);
  const [treePanStart, setTreePanStart] = useState({ x: 0, y: 0 });
  const treeContainerRef = useRef<HTMLDivElement | null>(null);
  const treeWheelCleanup = useRef<(() => void) | null>(null);

  const treeRefCallback = useCallback((node: HTMLDivElement | null) => {
    if (treeWheelCleanup.current) {
      treeWheelCleanup.current();
      treeWheelCleanup.current = null;
    }
    treeContainerRef.current = node;
    if (node) {
      const onWheel = (e: WheelEvent) => {
        e.preventDefault();
        const delta = e.deltaY > 0 ? -0.1 : 0.1;
        setTreeZoom(z => Math.max(0.4, Math.min(1.5, z + delta)));
      };
      node.addEventListener('wheel', onWheel, { passive: false });
      treeWheelCleanup.current = () => node.removeEventListener('wheel', onWheel);
    }
  }, []);

  // Station creation state
  const [stationFilter, setStationFilter] = useState<'all' | 'static' | 'placed' | 'admin'>('all');
  const [_isCreatingStation, setIsCreatingStation] = useState(false);
  const [editingStationKey, setEditingStationKey] = useState<string | null>(null);
  const [workbenchTypes, setWorkbenchTypes] = useState<WorkbenchType[]>([{ name: 'basic', source: 'config', stations: [] }]);
  const [workbenchTypesFetched, setWorkbenchTypesFetched] = useState(false);
  const [showManageTypes, setShowManageTypes] = useState(false);
  const [newTypeName, setNewTypeName] = useState('');
  const [renamingType, setRenamingType] = useState<string | null>(null);
  const [renameTypeName, setRenameTypeName] = useState('');
  const [editingTypeLevels, setEditingTypeLevels] = useState<string | null>(null);
  const [typeLevelConfig, setTypeLevelConfig] = useState<{ maxLevel: string; levels: string[] }>({ maxLevel: '10', levels: ['0'] });
  const [stationForm, setStationForm] = useState<StationFormData | null>(null);
  const [isPlacingStation, setIsPlacingStation] = useState(false);

  const searchRef = useRef<HTMLInputElement>(null);
  const playersSearchTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const selectedTableRef = useRef(selectedTable);
  selectedTableRef.current = selectedTable;

  /** Parse recipe response from server (supports both old flat format and new {source, recipes} format) */
  const parseRecipeResponse = useCallback((data: any): { recipes: Record<string, AdminRecipe[]>; sources: Record<string, 'config' | 'admin'> } | null => {
    if (!data || typeof data !== 'object' || Array.isArray(data)) return null;
    const recipes: Record<string, AdminRecipe[]> = {};
    const sources: Record<string, 'config' | 'admin'> = {};
    for (const [tableName, value] of Object.entries(data)) {
      if (Array.isArray(value)) {
        // Old flat format: tableName -> AdminRecipe[]
        recipes[tableName] = value as AdminRecipe[];
        sources[tableName] = 'config';
      } else if (value && typeof value === 'object' && 'recipes' in (value as any)) {
        // New format: tableName -> { source, recipes }
        const v = value as { source?: string; recipes: AdminRecipe[] };
        recipes[tableName] = v.recipes;
        sources[tableName] = (v.source === 'admin' ? 'admin' : 'config');
      }
    }
    return { recipes, sources };
  }, []);

  /** Fetch a single page of players from the server (with optional search) */
  const loadPlayersPage = useCallback(async (page: number, search: string) => {
    setLoading(true);
    try {
      const data = await fetchNui<{ players: AdminPlayer[]; total: number; page: number; totalPages: number }>(
        'admin:getPlayers', { page, limit: PLAYERS_PER_PAGE, search }
      );
      if (data && Array.isArray(data.players)) {
        setPlayers(data.players);
        setPlayersPage(data.page);
        setPlayersTotalPages(data.totalPages);
        setPlayersTotal(data.total);
      }
    } finally {
      setLoading(false);
    }
  }, [fetchNui]);

  /** Load data when tab changes */
  const loadTabData = useCallback(async (tab: AdminTab) => {
    setLoading(true);
    setSearchQuery('');
    try {
      switch (tab) {
        case 'players': {
          setPlayersSearch('');
          await loadPlayersPage(1, '');
          setSelectedPlayer(null);
          setEditingPlayer(null);
          break;
        }
        case 'queues': {
          const data = await fetchNui<AdminQueueItem[]>('admin:getQueues');
          setQueues(Array.isArray(data) ? data : []);
          break;
        }
        case 'stations': {
          const [stationData, treeData, typeData] = await Promise.all([
            fetchNui<AdminStation[]>('admin:getStations'),
            Object.keys(techTrees).length === 0 ? fetchNui<Record<string, AdminTechTree>>('admin:getTechTrees') : null,
            fetchNui<WorkbenchType[]>('admin:getWorkbenchTypes'),
          ]);
          setStations(Array.isArray(stationData) ? stationData : []);
          if (treeData && typeof treeData === 'object') setTechTrees(treeData);
          if (Array.isArray(typeData) && typeData.length > 0) { setWorkbenchTypes(typeData); setWorkbenchTypesFetched(true); }
          setStationInventoryMap({});
          setInventoryModalStation(null);
          setExpandedInventories(new Set());
          break;
        }
        case 'recipes': {
          const data = await fetchNui<any>('admin:getRecipes');
          const parsed = parseRecipeResponse(data);
          if (parsed) {
            setRecipes(parsed.recipes);
            setTableSources(parsed.sources);
            const tables = Object.keys(parsed.recipes);
            if (tables.length > 0 && !selectedTableRef.current) {
              setSelectedTable(tables[0]);
            }
          } else {
            setRecipes({});
            setTableSources({});
          }
          setExpandedRecipe(null);
          setEditingRecipe(null);
          setEditingRecipeId(null);
          setIsCreatingRecipe(false);
          break;
        }
        case 'techtrees': {
          const data = await fetchNui<Record<string, AdminTechTree>>('admin:getTechTrees');
          setTechTrees(data && typeof data === 'object' ? data : {});
          setSelectedTree(null);
          setEditingTree(null);
          setIsCreatingTree(false);
          setEditingNode(null);
          setEditingNodeId(null);
          setIsCreatingNode(false);
          break;
        }
      }
    } catch {
      showToast(t('admin.common.failedToLoadData'), 'error');
    }
    setLoading(false);
  }, [fetchNui, showToast]);

  /** Prefetch all tab data on mount so count badges show immediately */
  const initialLoad = useRef(true);
  useEffect(() => {
    setLoading(true);
    const otherTabs: AdminTab[] = ['players', 'queues', 'stations', 'recipes', 'techtrees'];
    for (const tab of otherTabs) {
      if (tab === activeTab) continue;
      switch (tab) {
        case 'players':
          fetchNui<{ total: number }>('admin:getPlayers', { page: 1, limit: 1 }).then(d => {
            if (d && typeof d.total === 'number') setPlayersTotal(d.total);
          });
          break;
        case 'queues':
          fetchNui<AdminQueueItem[]>('admin:getQueues').then(d => setQueues(Array.isArray(d) ? d : []));
          break;
        case 'stations':
          fetchNui<AdminStation[]>('admin:getStations').then(d => setStations(Array.isArray(d) ? d : []));
          break;
        case 'recipes':
          fetchNui<any>('admin:getRecipes').then(d => {
            const parsed = parseRecipeResponse(d);
            if (parsed) {
              setRecipes(parsed.recipes);
              setTableSources(parsed.sources);
              const tables = Object.keys(parsed.recipes);
              if (tables.length > 0 && !selectedTableRef.current) setSelectedTable(tables[0]);
            }
          });
          break;
        case 'techtrees':
          fetchNui<Record<string, AdminTechTree>>('admin:getTechTrees').then(d => {
            if (d && typeof d === 'object') setTechTrees(d);
          });
          break;
      }
    }
    loadTabData(activeTab);
  }, []);

  useEffect(() => {
    if (initialLoad.current) {
      initialLoad.current = false;
      return;
    }
    loadTabData(activeTab);
  }, [activeTab]);

  /** Tick queue countdown timers every second so progress rings animate */
  useEffect(() => {
    if (activeTab !== 'queues' || queues.length === 0) return;
    const timer = setInterval(() => {
      setQueues(prev => {
        let changed = false;
        const next = prev.map(q => {
          if (q.remainingTime > 0) {
            changed = true;
            return { ...q, remainingTime: q.remainingTime - 1 };
          }
          return q;
        });
        return changed ? next : prev;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, [activeTab, queues.length]);

  /** Close admin panel */
  const handleClose = useCallback(() => {
    fetchNui('admin:close');
  }, [fetchNui]);

  /** Escape key handler */
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (confirm) {
          setConfirm(null);
        } else if (stationForm) {
          setStationForm(null);
          setIsCreatingStation(false);
          setEditingStationKey(null);
        } else if (editingRecipe) {
          setEditingRecipe(null);
          setEditingRecipeId(null);
          setIsCreatingRecipe(false);
        } else if (editingNode) {
          setEditingNode(null);
          setEditingNodeId(null);
          setIsCreatingNode(false);
        } else if (editingTree) {
          setEditingTree(null);
          setIsCreatingTree(false);
        } else if (selectedPlayer) {
          setSelectedPlayer(null);
          setEditingPlayer(null);
        } else {
          handleClose();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleClose, confirm, selectedPlayer, editingRecipe, stationForm, editingNode, editingTree]);

  /** NUI message listener for station placement events from client */
  useEffect(() => {
    const handleMessage = (e: MessageEvent) => {
      const data = e.data;
      if (data.action === 'adminStationPlaced') {
        setStationForm(prev => prev ? { ...prev, coords: data.coords, heading: data.heading } : prev);
        setIsPlacingStation(false);
      } else if (data.action === 'adminStationPlacementCancelled') {
        setIsPlacingStation(false);
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  // --- Players Tab ---

  /** Load detailed player data, fetching workbench types and level configs if not yet loaded */
  const loadPlayerDetail = useCallback(async (identifier: string) => {
    const promises: Promise<any>[] = [
      fetchNui<AdminPlayerDetail>('admin:getPlayerDetail', { identifier }),
    ];
    if (!workbenchTypesFetched) {
      promises.push(fetchNui<WorkbenchType[]>('admin:getWorkbenchTypes').then(data => {
        if (Array.isArray(data) && data.length > 0) { setWorkbenchTypes(data); setWorkbenchTypesFetched(true); }
      }));
    }
    if (!levelConfigsFetched) {
      promises.push(fetchNui<Record<string, LevelConfig>>('admin:getLevelConfig').then(data => {
        if (data && typeof data === 'object') { setLevelConfigs(data); setLevelConfigsFetched(true); }
      }));
    }
    const [data] = await Promise.all(promises);
    if (data && data.identifier) {
      setSelectedPlayer(data);
      setEditingPlayer(null);
    }
  }, [fetchNui, workbenchTypesFetched, levelConfigsFetched]);

  /** Compute level from XP using level config thresholds */
  const getLevelFromXP = useCallback((xp: number, wbType: string): number => {
    const config = levelConfigs[wbType];
    if (!config) return 1;
    let level = 1;
    for (const [idx, requiredXp] of Object.entries(config.levels)) {
      const lvlNum = parseInt(idx) + 1;
      if (xp >= requiredXp && lvlNum > level) level = lvlNum;
    }
    return Math.min(level, config.maxLevel);
  }, [levelConfigs]);

  /** Get XP threshold for a given level */
  const getXPForLevel = useCallback((level: number, wbType: string): number => {
    const config = levelConfigs[wbType];
    if (!config) return 0;
    return config.levels[level - 1] ?? 0;
  }, [levelConfigs]);

  /** Handle level change — auto-sync XP to match the level threshold */
  const handleLevelChange = useCallback((wb: string, newLevelStr: string) => {
    if (!editingPlayer) return;
    const maxLvl = levelConfigs[wb]?.maxLevel ?? 10;
    const newLevel = Math.min(Math.max(parseInt(newLevelStr) || 1, 1), maxLvl);
    const xpForLevel = getXPForLevel(newLevel, wb);
    setEditingPlayer({
      ...editingPlayer,
      workbench_levels: {
        ...editingPlayer.workbench_levels,
        [wb]: { level: String(newLevel), xp: String(xpForLevel) },
      },
    });
  }, [editingPlayer, getXPForLevel, levelConfigs]);

  /** Handle XP change — auto-sync level from XP */
  const handleXPChange = useCallback((wb: string, newXPStr: string) => {
    if (!editingPlayer) return;
    const newXP = parseInt(newXPStr) || 0;
    const computedLevel = getLevelFromXP(newXP, wb);
    setEditingPlayer({
      ...editingPlayer,
      workbench_levels: {
        ...editingPlayer.workbench_levels,
        [wb]: { xp: String(newXP), level: String(computedLevel) },
      },
    });
  }, [editingPlayer, getLevelFromXP]);

  /** Save player edits (tech points + per-workbench levels) */
  const savePlayerEdits = useCallback(async () => {
    if (!selectedPlayer || !editingPlayer) return;
    let allSuccess = true;

    // Save each workbench level individually
    for (const [wbType, data] of Object.entries(editingPlayer.workbench_levels)) {
      const result = await fetchNui<{ success: boolean }>('admin:updatePlayer', {
        identifier: selectedPlayer.identifier,
        workbenchType: wbType,
        xp: parseInt(data.xp) || 0,
        level: parseInt(data.level) || 1,
      });
      if (!result?.success) allSuccess = false;
    }

    if (allSuccess) {
      showToast(t('admin.players.playerUpdated'), 'success');
      loadPlayerDetail(selectedPlayer.identifier);
      loadPlayersPage(playersPage, playersSearch);
    } else {
      showToast(t('admin.players.playerUpdatePartial'), 'error');
    }
    setEditingPlayer(null);
  }, [selectedPlayer, editingPlayer, fetchNui, showToast, loadPlayerDetail, loadPlayersPage, playersPage, playersSearch]);

  /** Reset a player's data */
  const resetPlayer = useCallback(async (identifier: string) => {
    const result = await fetchNui<{ success: boolean }>('admin:resetPlayer', { identifier });
    if (result?.success) {
      showToast(t('admin.players.playerReset'), 'success');
      setSelectedPlayer(null);
      setEditingPlayer(null);
      loadPlayersPage(playersPage, playersSearch);
    } else {
      showToast(t('admin.players.playerResetFailed'), 'error');
    }
  }, [fetchNui, showToast, loadPlayersPage, playersPage, playersSearch]);

  /** Toggle a tech tree node */
  const toggleNode = useCallback(async (identifier: string, nodeId: string) => {
    const result = await fetchNui<{ success: boolean; isUnlocked: boolean }>('admin:toggleBlueprint', { identifier, nodeId });
    if (result?.success) {
      showToast(t('admin.players.nodeToggled', { state: result.isUnlocked ? 'unlocked' : 'locked' }), 'success');
      loadPlayerDetail(identifier);
    } else {
      showToast(t('admin.players.nodeToggleFailed'), 'error');
    }
  }, [fetchNui, showToast, loadPlayerDetail]);

  /** Reset all personal tech tree nodes for a player */
  const resetPersonalTechNodes = useCallback(async (identifier: string) => {
    const result = await fetchNui<{ success: boolean }>('admin:resetPersonalTechNodes', { identifier });
    if (result?.success) {
      showToast(t('admin.players.personalNodesReset'), 'success');
      loadPlayerDetail(identifier);
    } else {
      showToast(t('admin.players.personalNodesResetFailed'), 'error');
    }
  }, [fetchNui, showToast, loadPlayerDetail]);

  /** Reset shared tech tree nodes for a specific station */
  const resetStationTechNodes = useCallback(async (stationKey: string, identifier: string) => {
    const result = await fetchNui<{ success: boolean }>('admin:resetStationTechNodes', { stationKey });
    if (result?.success) {
      showToast(t('admin.players.stationNodesReset'), 'success');
      loadPlayerDetail(identifier);
    } else {
      showToast(t('admin.players.stationNodesResetFailed'), 'error');
    }
  }, [fetchNui, showToast, loadPlayerDetail]);

  /** Reset personal tech tree nodes for a specific workbench type */
  const resetPersonalTypeTechNodes = useCallback(async (identifier: string, workbenchType: string) => {
    const result = await fetchNui<{ success: boolean }>('admin:resetPersonalTypeTechNodes', { identifier, workbenchType });
    if (result?.success) {
      showToast(t('admin.players.typeNodesReset', { type: capitalize(workbenchType) }), 'success');
      loadPlayerDetail(identifier);
    } else {
      showToast(t('admin.players.typeNodesResetFailed'), 'error');
    }
  }, [fetchNui, showToast, loadPlayerDetail]);

  // --- Queues Tab ---

  const filteredQueues = queues.filter(q =>
    (q.recipeName || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (q.identifier || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (q.ownerName && q.ownerName.toLowerCase().includes(searchQuery.toLowerCase())) ||
    (q.stationId || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  /** Cancel a queue item (refund) */
  const cancelQueueItem = useCallback(async (item: AdminQueueItem) => {
    const result = await fetchNui<{ success: boolean }>('admin:cancelQueue', {
      identifier: item.identifier,
      itemId: item.id,
      type: item.type || 'personal',
      stationId: item.stationId,
    });
    if (result?.success) {
      showToast(t('admin.queues.cancelled'), 'success');
      loadTabData('queues');
    } else {
      showToast(t('admin.queues.cancelFailed'), 'error');
    }
  }, [fetchNui, showToast, loadTabData]);

  /** Force-complete a queue item */
  const forceCompleteQueueItem = useCallback(async (item: AdminQueueItem) => {
    const result = await fetchNui<{ success: boolean }>('admin:forceCompleteQueue', {
      identifier: item.identifier,
      itemId: item.id,
      type: item.type || 'personal',
      stationId: item.stationId,
    });
    if (result?.success) {
      showToast(t('admin.queues.forceCompleted'), 'success');
      loadTabData('queues');
    } else {
      showToast(t('admin.queues.forceCompleteFailed'), 'error');
    }
  }, [fetchNui, showToast, loadTabData]);

  /** Remove a queue item (no refund) */
  const removeQueueItem = useCallback(async (item: AdminQueueItem) => {
    const result = await fetchNui<{ success: boolean }>('admin:removeQueue', {
      identifier: item.identifier,
      itemId: item.id,
      type: item.type || 'personal',
      stationId: item.stationId,
    });
    if (result?.success) {
      showToast(t('admin.queues.removed'), 'success');
      loadTabData('queues');
    } else {
      showToast(t('admin.queues.removeFailed'), 'error');
    }
  }, [fetchNui, showToast, loadTabData]);

  // --- Stations Tab ---

  const filteredStations = stations.filter(s => {
    if (stationFilter === 'static' && !s.isStatic) return false;
    if (stationFilter === 'placed' && (s.isStatic || s.isAdmin)) return false;
    if (stationFilter === 'admin' && !s.isAdmin) return false;
    const q = searchQuery.toLowerCase();
    return (s.type || '').toLowerCase().includes(q) ||
      (s.owner || '').toLowerCase().includes(q) ||
      (s.ownerName && s.ownerName.toLowerCase().includes(q)) ||
      (s.label && s.label.toLowerCase().includes(q)) ||
      String(s.id).includes(searchQuery);
  });

  /** Teleport to a station */
  const teleportToStation = useCallback(async (station: AdminStation) => {
    await fetchNui('admin:teleportToStation', { id: station.id });
    showToast(t('admin.stations.teleported', { id: station.id }), 'info');
  }, [fetchNui, showToast]);

  /** Delete a station (placed or admin) */
  const deleteStation = useCallback(async (id: number | string) => {
    const result = await fetchNui<{ success: boolean }>('admin:deleteStation', { id });
    if (result?.success) {
      showToast(t('admin.stations.deleted'), 'success');
      loadTabData('stations');
    } else {
      showToast(t('admin.stations.deleteFailed'), 'error');
    }
  }, [fetchNui, showToast, loadTabData]);

  /** Create a blank station form, loading recipe tables and workbench types if needed */
  const startCreateStation = useCallback(async () => {
    const promises: Promise<any>[] = [];
    if (Object.keys(recipes).length === 0) {
      promises.push(fetchNui<any>('admin:getRecipes').then(data => {
        const parsed = parseRecipeResponse(data);
        if (parsed) { setRecipes(parsed.recipes); setTableSources(parsed.sources); }
      }));
    }
    if (!workbenchTypesFetched) {
      promises.push(fetchNui<WorkbenchType[]>('admin:getWorkbenchTypes').then(data => {
        if (Array.isArray(data) && data.length > 0) { setWorkbenchTypes(data); setWorkbenchTypesFetched(true); }
      }));
    }
    await Promise.all(promises);
    setStationForm({
      label: '', type: 'basic', radius: '2.0', propModel: 'prop_tool_bench02', propEnabled: true,
      propSpawnRadius: '50.0', recipes: ['all'], techTrees: [], owner: '', blipEnabled: true,
      blipSprite: '566', blipColor: '2', blipScale: '0.7', blipLabel: '',
      sharedCrafting: false, sharedStaging: false, sharedTech: false, stationTechPoints: '0', coords: null, heading: 0,
      jobs: [], gangs: [],
    });
    setIsCreatingStation(true);
    setEditingStationKey(null);
    setStationPlayerTechOpen(false);
    setStationPlayerTech([]);
    setStationPlayerTechEdits({});
  }, [recipes, fetchNui, workbenchTypesFetched]);

  /** Open station form pre-filled for editing any station type */
  const startEditStation = useCallback(async (station: AdminStation) => {
    const promises: Promise<any>[] = [];
    if (Object.keys(recipes).length === 0) {
      promises.push(fetchNui<any>('admin:getRecipes').then(data => {
        const parsed = parseRecipeResponse(data);
        if (parsed) { setRecipes(parsed.recipes); setTableSources(parsed.sources); }
      }));
    }
    if (!workbenchTypesFetched) {
      promises.push(fetchNui<WorkbenchType[]>('admin:getWorkbenchTypes').then(data => {
        if (Array.isArray(data) && data.length > 0) { setWorkbenchTypes(data); setWorkbenchTypesFetched(true); }
      }));
    }
    // Fetch station tech points if shared tech is enabled
    let stationTP = '0';
    if (station.sharedTech) {
      promises.push(fetchNui<{ tech_points: number }>('admin:getStationTech', { stationKey: station.stationKey }).then(data => {
        if (data) stationTP = String(data.tech_points ?? 0);
      }));
    }
    await Promise.all(promises);
    const propObj = typeof station.prop === 'object' && station.prop !== null ? station.prop : null;
    const propStr = typeof station.prop === 'string' ? station.prop : null;
    setStationForm({
      label: station.label || '', type: station.type || 'basic',
      radius: String(station.radius || 2.0),
      propModel: propObj?.model || propStr || 'prop_tool_bench02',
      propEnabled: propObj ? propObj.enabled : (propStr !== 'none' && propStr !== null),
      propSpawnRadius: String(propObj?.spawnRadius || 50.0),
      recipes: station.recipes || ['all'],
      techTrees: station.techTrees || [],
      owner: (station.owner === 'admin' || station.owner === 'config') ? '' : station.owner,
      blipEnabled: station.blip?.enabled ?? true,
      blipSprite: String(station.blip?.sprite ?? 566),
      blipColor: String(station.blip?.color ?? 2),
      blipScale: String(station.blip?.scale ?? 0.7),
      blipLabel: station.blip?.label || '',
      sharedCrafting: station.sharedCrafting ?? false,
      sharedStaging: station.sharedStaging ?? false,
      sharedTech: station.sharedTech ?? false,
      stationTechPoints: stationTP,
      coords: station.coords || null,
      heading: station.heading || 0,
      jobs: Array.isArray(station.job) ? station.job.map(j => ({ name: j.name, minGrade: j.minGrade ?? 0 }))
        : station.job && typeof station.job === 'object' && 'name' in station.job ? [{ name: station.job.name, minGrade: station.job.minGrade ?? 0 }]
        : [],
      gangs: Array.isArray(station.gang) ? station.gang.map(g => ({ name: g.name, minGrade: g.minGrade ?? 0 }))
        : typeof station.gang === 'string' && station.gang ? [{ name: station.gang, minGrade: 0 }]
        : station.gang && typeof station.gang === 'object' && 'name' in (station.gang as any) ? [{ name: (station.gang as any).name, minGrade: (station.gang as any).minGrade ?? 0 }]
        : [],
    });
    setEditingStationKey(station.stationKey);
    setIsCreatingStation(false);
  }, [recipes, fetchNui, workbenchTypesFetched]);

  /** Begin gizmo placement for station */
  const beginStationPlacement = useCallback(() => {
    if (!stationForm) return;
    setIsPlacingStation(true);
    fetchNui('admin:beginStationPlacement', {
      model: stationForm.propModel || 'prop_tool_bench02',
      propEnabled: stationForm.propEnabled,
      radius: parseFloat(stationForm.radius) || 2.0,
    });
  }, [stationForm, fetchNui]);

  /** Save (create) a new admin station */
  const saveNewStation = useCallback(async () => {
    if (!stationForm) return;
    if (!stationForm.label.trim()) { showToast(t('admin.stations.labelRequired'), 'error'); return; }
    if (!stationForm.coords) { showToast(t('admin.stations.locationRequired'), 'error'); return; }
    const recipeList = stationForm.recipes.filter(Boolean);
    const techList = stationForm.techTrees.filter(Boolean);
    const payload: Record<string, any> = {
      label: stationForm.label.trim(),
      type: stationForm.type || 'basic',
      coords: stationForm.coords,
      heading: stationForm.heading,
      radius: parseFloat(stationForm.radius) || 2.0,
      recipes: recipeList.length > 0 ? recipeList : ['all'],
      techTrees: techList,
      owner: stationForm.owner.trim(),
      sharedCrafting: stationForm.sharedCrafting,
      sharedStaging: stationForm.sharedStaging,
      sharedTech: stationForm.sharedTech,
      prop: {
        enabled: stationForm.propEnabled,
        model: stationForm.propModel || 'prop_tool_bench02',
        spawnRadius: parseFloat(stationForm.propSpawnRadius) || 50.0,
        offset: { x: 0, y: 0, z: 0 },
      },
      blip: {
        enabled: stationForm.blipEnabled,
        sprite: !isNaN(parseInt(stationForm.blipSprite)) ? parseInt(stationForm.blipSprite) : 566,
        color: !isNaN(parseInt(stationForm.blipColor)) ? parseInt(stationForm.blipColor) : 2,
        scale: !isNaN(parseFloat(stationForm.blipScale)) ? parseFloat(stationForm.blipScale) : 0.7,
        label: stationForm.blipLabel || stationForm.label.trim(),
      },
      job: stationForm.jobs,
      gang: stationForm.gangs,
    };
    const result = await fetchNui<{ success: boolean; stationKey?: string }>('admin:saveStation', payload);
    if (result?.success) {
      showToast(t('admin.stations.created'), 'success');
      setStationForm(null);
      setIsCreatingStation(false);
      loadTabData('stations');
    } else {
      showToast(t('admin.stations.createFailed'), 'error');
    }
  }, [stationForm, fetchNui, showToast, loadTabData]);

  /** Update an existing admin station */
  const updateExistingStation = useCallback(async () => {
    if (!stationForm || !editingStationKey) return;
    const recipeList = stationForm.recipes.filter(Boolean);
    const techList = stationForm.techTrees.filter(Boolean);
    const payload: Record<string, any> = {
      stationKey: editingStationKey,
      label: stationForm.label.trim(),
      type: stationForm.type || 'basic',
      coords: stationForm.coords || null,
      heading: stationForm.heading,
      radius: parseFloat(stationForm.radius) || 2.0,
      recipes: recipeList.length > 0 ? recipeList : ['all'],
      techTrees: techList,
      owner: stationForm.owner.trim(),
      sharedCrafting: stationForm.sharedCrafting,
      sharedStaging: stationForm.sharedStaging,
      sharedTech: stationForm.sharedTech,
      prop: {
        enabled: stationForm.propEnabled,
        model: stationForm.propModel || 'prop_tool_bench02',
        spawnRadius: parseFloat(stationForm.propSpawnRadius) || 50.0,
        offset: { x: 0, y: 0, z: 0 },
      },
      blip: {
        enabled: stationForm.blipEnabled,
        sprite: !isNaN(parseInt(stationForm.blipSprite)) ? parseInt(stationForm.blipSprite) : 566,
        color: !isNaN(parseInt(stationForm.blipColor)) ? parseInt(stationForm.blipColor) : 2,
        scale: !isNaN(parseFloat(stationForm.blipScale)) ? parseFloat(stationForm.blipScale) : 0.7,
        label: stationForm.blipLabel || stationForm.label.trim(),
      },
      job: stationForm.jobs,
      gang: stationForm.gangs,
    };
    // Also save shared tech points if shared tech is enabled
    if (stationForm.sharedTech && editingStationKey) {
      await fetchNui('admin:updateStationTech', {
        stationKey: editingStationKey,
        tech_points: parseInt(stationForm.stationTechPoints) || 0,
      });
    }
    const result = await fetchNui<{ success: boolean }>('admin:updateStation', payload);
    if (result?.success) {
      showToast(t('admin.stations.updated'), 'success');
      setStationForm(null);
      setEditingStationKey(null);
      loadTabData('stations');
    } else {
      showToast(t('admin.stations.updateFailed'), 'error');
    }
  }, [stationForm, editingStationKey, fetchNui, showToast, loadTabData]);

  /** Open the inventory modal for a station */
  const openInventoryModal = useCallback(async (station: AdminStation) => {
    setInventoryModalStation(station);
    setLoadingInventoryModal(true);
    setExpandedInventories(new Set());
    setAddItemTarget(null);
    setAddItemName('');
    setAddItemCount(1);
    try {
      const data = await fetchNui<StationInventory[]>('admin:getStationInventories', { stationKey: station.stationKey });
      setStationInventoryMap(prev => ({ ...prev, [String(station.id)]: Array.isArray(data) ? data : [] }));
    } catch {
      setStationInventoryMap(prev => ({ ...prev, [String(station.id)]: [] }));
    }
    setLoadingInventoryModal(false);
  }, [fetchNui]);

  /** Remove an item (or partial count) from a station's staged inventory */
  const removeStationItem = useCallback(async (station: AdminStation, stagingKey: string, item: StagedItem, count?: number) => {
    const result = await fetchNui<{ success: boolean }>('admin:removeStationInventoryItem', {
      stationKey: station.stationKey,
      stagingKey,
      itemName: item.item,
      count: count ?? item.count,
      slot: item.slot,
    });
    if (result?.success) {
      showToast(t('admin.stations.itemRemoved'), 'success');
      setLoadingInventoryModal(true);
      try {
        const data = await fetchNui<StationInventory[]>('admin:getStationInventories', { stationKey: station.stationKey });
        setStationInventoryMap(prev => ({ ...prev, [String(station.id)]: Array.isArray(data) ? data : [] }));
      } catch {
        setStationInventoryMap(prev => ({ ...prev, [String(station.id)]: [] }));
      }
      setLoadingInventoryModal(false);
    } else {
      showToast(t('admin.stations.itemRemoveFailed'), 'error');
    }
  }, [fetchNui, showToast]);

  /** Add an item to a station's staged inventory */
  const addStationItem = useCallback(async (station: AdminStation, stagingKey: string, itemName: string, count: number) => {
    setAddItemLoading(true);
    const result = await fetchNui<{ success: boolean; error?: string }>('admin:addStationInventoryItem', {
      stationKey: station.stationKey,
      stagingKey,
      itemName: itemName.trim(),
      count,
    });
    if (result?.success) {
      showToast(t('admin.stations.itemAdded', { count, item: itemName.trim() }), 'success');
      setAddItemTarget(null);
      setAddItemName('');
      setAddItemCount(1);
      setLoadingInventoryModal(true);
      try {
        const data = await fetchNui<StationInventory[]>('admin:getStationInventories', { stationKey: station.stationKey });
        setStationInventoryMap(prev => ({ ...prev, [String(station.id)]: Array.isArray(data) ? data : [] }));
      } catch {
        setStationInventoryMap(prev => ({ ...prev, [String(station.id)]: [] }));
      }
      setLoadingInventoryModal(false);
    } else {
      showToast(result?.error || t('admin.stations.itemAddFailed'), 'error');
    }
    setAddItemLoading(false);
  }, [fetchNui, showToast]);

  // --- Recipes Tab ---

  const recipeTables = Object.keys(recipes);
  const currentRecipes = recipes[selectedTable] || [];
  const filteredRecipes = currentRecipes.filter(r =>
    (r.label || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (r.name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (r.id || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  /** Save recipe edits (full form) */
  const saveRecipeEdits = useCallback(async () => {
    if (!editingRecipe || !editingRecipeId) return;
    const updates: Record<string, any> = {
      tableName: editingRecipe.tableName,
      recipeId: editingRecipeId,
      name: editingRecipe.name,
      label: editingRecipe.label.trim(),
      craftTime: parseInt(editingRecipe.craftTime) || 5,
      levelRequired: parseInt(editingRecipe.levelRequired) || 0,
      xpReward: parseInt(editingRecipe.xpReward) || 0,
      techPointsReward: parseInt(editingRecipe.techPointsReward) || 0,
      outputAmount: parseInt(editingRecipe.outputAmount) || 1,
      failChance: parseInt(editingRecipe.failChance) || 0,
      blueprint: editingRecipe.blueprint.trim(),
      blueprintDurabilityLoss: parseInt(editingRecipe.blueprintDurabilityLoss) || 0,
      cost: parseInt(editingRecipe.cost) || 0,
      image: editingRecipe.image.trim(),
      enabled: editingRecipe.enabled,
      ingredients: editingRecipe.ingredients
        .filter(i => i.item.trim())
        .map(i => ({ item: i.item.trim(), amount: parseInt(i.amount) || 1, label: i.label.trim() })),
      tools: editingRecipe.tools
        .filter(t => t.item.trim())
        .map(t => ({
          item: t.item.trim(),
          amount: parseInt(t.amount) || 1,
          consumptionType: t.consumptionType || 'none',
          ...(t.consumptionType === 'durability' ? { durabilityLoss: parseInt(t.durabilityLoss) || 5 } : {}),
          ...(t.consumptionType === 'chance' ? { consumeChance: parseInt(t.consumeChance) || 25 } : {}),
        })),
      metadata: editingRecipe.metadata.filter(m => m.key.trim()).reduce((acc, m) => { acc[m.key.trim()] = m.value; return acc; }, {} as Record<string, any>),
      showMetadata: editingRecipe.showMetadata.filter(sm => sm.key.trim() && sm.label.trim()).reduce((acc, sm) => { acc[sm.key.trim()] = sm.label.trim(); return acc; }, {} as Record<string, string>),
    };
    if (Object.keys(updates.metadata).length === 0) updates.metadata = null;
    if (Object.keys(updates.showMetadata).length === 0) updates.showMetadata = null;
    const result = await fetchNui<{ success: boolean }>('admin:updateRecipe', updates);
    if (result?.success) {
      showToast(t('admin.recipes.saved'), 'success');
      setEditingRecipe(null);
      setEditingRecipeId(null);
      loadTabData('recipes');
    } else {
      showToast(t('admin.recipes.saveFailed'), 'error');
    }
  }, [editingRecipe, editingRecipeId, fetchNui, showToast, loadTabData]);

  /** Create a new recipe */
  const createRecipe = useCallback(async () => {
    if (!editingRecipe) return;
    if (!editingRecipe.name.trim()) {
      showToast(t('admin.recipes.nameRequired'), 'error');
      return;
    }
    const recipe: Record<string, any> = {
      name: editingRecipe.name.trim(),
      label: editingRecipe.label.trim(),
      craftTime: parseInt(editingRecipe.craftTime) || 5,
      levelRequired: parseInt(editingRecipe.levelRequired) || 0,
      xpReward: parseInt(editingRecipe.xpReward) || 0,
      techPointsReward: parseInt(editingRecipe.techPointsReward) || 0,
      outputAmount: parseInt(editingRecipe.outputAmount) || 1,
      failChance: parseInt(editingRecipe.failChance) || 0,
      blueprint: editingRecipe.blueprint.trim(),
      blueprintDurabilityLoss: parseInt(editingRecipe.blueprintDurabilityLoss) || 0,
      cost: parseInt(editingRecipe.cost) || 0,
      image: editingRecipe.image.trim(),
      enabled: editingRecipe.enabled,
      ingredients: editingRecipe.ingredients
        .filter(i => i.item.trim())
        .map(i => ({ item: i.item.trim(), amount: parseInt(i.amount) || 1, label: i.label.trim() })),
      tools: editingRecipe.tools
        .filter(t => t.item.trim())
        .map(t => ({
          item: t.item.trim(),
          amount: parseInt(t.amount) || 1,
          consumptionType: t.consumptionType || 'none',
          ...(t.consumptionType === 'durability' ? { durabilityLoss: parseInt(t.durabilityLoss) || 5 } : {}),
          ...(t.consumptionType === 'chance' ? { consumeChance: parseInt(t.consumeChance) || 25 } : {}),
        })),
    };
    const metadataObj = editingRecipe.metadata.filter(m => m.key.trim()).reduce((acc, m) => { acc[m.key.trim()] = m.value; return acc; }, {} as Record<string, any>);
    const showMetadataObj = editingRecipe.showMetadata.filter(sm => sm.key.trim() && sm.label.trim()).reduce((acc, sm) => { acc[sm.key.trim()] = sm.label.trim(); return acc; }, {} as Record<string, string>);
    if (Object.keys(metadataObj).length > 0) recipe.metadata = metadataObj;
    if (Object.keys(showMetadataObj).length > 0) recipe.showMetadata = showMetadataObj;
    const result = await fetchNui<{ success: boolean; id?: string }>('admin:createRecipe', {
      tableName: editingRecipe.tableName,
      recipe,
    });
    if (result?.success) {
      showToast(t('admin.recipes.created'), 'success');
      setEditingRecipe(null);
      setIsCreatingRecipe(false);
      loadTabData('recipes');
    } else {
      showToast(t('admin.recipes.createFailed'), 'error');
    }
  }, [editingRecipe, fetchNui, showToast, loadTabData]);

  /** Delete a recipe */
  const deleteRecipe = useCallback(async (recipeId: string) => {
    const result = await fetchNui<{ success: boolean }>('admin:deleteRecipe', {
      tableName: selectedTable,
      recipeId,
    });
    if (result?.success) {
      showToast(t('admin.recipes.deleted'), 'success');
      setExpandedRecipe(null);
      loadTabData('recipes');
    } else {
      showToast(t('admin.recipes.deleteFailed'), 'error');
    }
  }, [selectedTable, fetchNui, showToast, loadTabData]);

  /** Toggle recipe enabled/disabled */
  const toggleRecipeEnabled = useCallback(async (recipe: AdminRecipe) => {
    const result = await fetchNui<{ success: boolean }>('admin:updateRecipe', {
      tableName: selectedTable,
      recipeId: recipe.id,
      enabled: !recipe.enabled,
    });
    if (result?.success) {
      showToast(t('admin.recipes.toggled', { state: recipe.enabled ? 'disabled' : 'enabled' }), 'success');
      loadTabData('recipes');
    } else {
      showToast(t('admin.recipes.toggleFailed'), 'error');
    }
  }, [selectedTable, fetchNui, showToast, loadTabData]);

  // --- Tech Trees Tab ---

  const treeIds = Object.keys(techTrees);
  const selectedTreeData = selectedTree ? techTrees[selectedTree] : null;
  const filteredTreeIds = treeIds.filter(id => {
    const tree = techTrees[id];
    const q = searchQuery.toLowerCase();
    return id.toLowerCase().includes(q) || (tree.label || '').toLowerCase().includes(q);
  });

  /** Re-fetch tech trees data without resetting the selected tree view */
  const refreshTechTrees = useCallback(async () => {
    const data = await fetchNui<Record<string, AdminTechTree>>('admin:getTechTrees');
    setTechTrees(data && typeof data === 'object' ? data : {});
  }, [fetchNui]);

  /** Save tech tree (create or update) */
  const saveTreeForm = useCallback(async () => {
    if (!editingTree) return;
    if (!editingTree.label.trim()) { showToast(t('admin.techTrees.labelRequired'), 'error'); return; }

    if (isCreatingTree) {
      if (!editingTree.treeId.trim()) { showToast(t('admin.techTrees.treeIdRequired'), 'error'); return; }
      const result = await fetchNui<{ success: boolean }>('admin:createTechTree', {
        treeId: editingTree.treeId.trim(),
        label: editingTree.label.trim(),
        icon: editingTree.icon.trim() || 'git-branch',
        color: editingTree.color.trim() || '#4ADE80',
      });
      if (result?.success) {
        showToast(t('admin.techTrees.treeCreated'), 'success');
        setSelectedTree(editingTree.treeId.trim());
        setEditingTree(null);
        setIsCreatingTree(false);
        refreshTechTrees();
      } else {
        showToast(t('admin.techTrees.treeCreateFailed'), 'error');
      }
    } else {
      const result = await fetchNui<{ success: boolean }>('admin:updateTechTree', {
        treeId: editingTree.treeId,
        label: editingTree.label.trim(),
        icon: editingTree.icon.trim() || 'git-branch',
        color: editingTree.color.trim() || '#4ADE80',
      });
      if (result?.success) {
        showToast(t('admin.techTrees.treeUpdated'), 'success');
        setEditingTree(null);
        refreshTechTrees();
      } else {
        showToast(t('admin.techTrees.treeUpdateFailed'), 'error');
      }
    }
  }, [editingTree, isCreatingTree, fetchNui, showToast, refreshTechTrees]);

  /** Save node (create or update) */
  const saveNodeForm = useCallback(async () => {
    if (!editingNode || !selectedTree) return;
    if (!editingNode.id.trim()) { showToast(t('admin.techTrees.nodeIdRequired'), 'error'); return; }
    if (!editingNode.recipeId.trim()) { showToast(t('admin.techTrees.recipeIdRequired'), 'error'); return; }

    if (isCreatingNode) {
      const result = await fetchNui<{ success: boolean }>('admin:createNode', {
        treeId: selectedTree,
        node: {
          id: editingNode.id.trim(),
          recipeId: editingNode.recipeId.trim(),
          cost: parseInt(editingNode.cost) || 1,
          prerequisites: editingNode.prerequisites,
          position: {
            row: parseInt(editingNode.position.row) || 1,
            col: parseInt(editingNode.position.col) || 1,
          },
        },
      });
      if (result?.success) {
        showToast(t('admin.techTrees.nodeCreated'), 'success');
        setEditingNode(null);
        setIsCreatingNode(false);
        refreshTechTrees();
      } else {
        showToast(t('admin.techTrees.nodeCreateFailed'), 'error');
      }
    } else {
      const result = await fetchNui<{ success: boolean }>('admin:updateNode', {
        treeId: selectedTree,
        nodeId: editingNodeId,
        fields: {
          recipeId: editingNode.recipeId.trim(),
          cost: parseInt(editingNode.cost) || 1,
          prerequisites: editingNode.prerequisites,
          position: {
            row: parseInt(editingNode.position.row) || 1,
            col: parseInt(editingNode.position.col) || 1,
          },
        },
      });
      if (result?.success) {
        showToast(t('admin.techTrees.nodeUpdated'), 'success');
        setEditingNode(null);
        setEditingNodeId(null);
        refreshTechTrees();
      } else {
        showToast(t('admin.techTrees.nodeUpdateFailed'), 'error');
      }
    }
  }, [editingNode, editingNodeId, isCreatingNode, selectedTree, fetchNui, showToast, refreshTechTrees]);

  /** Delete a tech tree */
  const deleteTechTree = useCallback(async (treeId: string) => {
    const result = await fetchNui<{ success: boolean }>('admin:deleteTechTree', { treeId });
    if (result?.success) {
      showToast(t('admin.techTrees.treeDeleted'), 'success');
      if (selectedTree === treeId) setSelectedTree(null);
      refreshTechTrees();
    } else {
      showToast(t('admin.techTrees.treeDeleteFailed'), 'error');
    }
  }, [fetchNui, showToast, selectedTree, refreshTechTrees]);

  /** Delete a node from a tech tree */
  const deleteNode = useCallback(async (treeId: string, nodeId: string) => {
    const result = await fetchNui<{ success: boolean }>('admin:deleteNode', { treeId, nodeId });
    if (result?.success) {
      showToast(t('admin.techTrees.nodeDeleted'), 'success');
      refreshTechTrees();
    } else {
      showToast(t('admin.techTrees.nodeDeleteFailed'), 'error');
    }
  }, [fetchNui, showToast, refreshTechTrees]);

  /** Build a flat list of all recipe IDs across all tables (for node recipe dropdown) */
  const allRecipeOptions = useCallback(() => {
    const opts: { id: string; label: string; table: string }[] = [];
    for (const [tableName, tableRecipes] of Object.entries(recipes)) {
      for (const recipe of tableRecipes) {
        opts.push({ id: recipe.id, label: recipe.label || capitalize(recipe.name), table: tableName });
      }
    }
    return opts;
  }, [recipes]);

  /** Format seconds to mm:ss */
  const formatTime = (seconds: number) => {
    if (seconds <= 0) return '0:00';
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  /** Get count for a tab */
  const getTabCount = (tab: AdminTab): number | null => {
    switch (tab) {
      case 'players': return playersTotal || null;
      case 'queues': return queues.length || null;
      case 'stations': return stations.length || null;
      case 'recipes': return currentRecipes.length || null;
      case 'techtrees': return Object.keys(techTrees).length || null;
    }
  };

  // Tab config
  const tabs: { id: AdminTab; label: string; icon: React.ReactNode }[] = [
    { id: 'players', label: t('admin.tabs.players'), icon: <Users className="w-3.5 h-3.5" /> },
    { id: 'queues', label: t('admin.tabs.queues'), icon: <Clock className="w-3.5 h-3.5" /> },
    { id: 'stations', label: t('admin.tabs.stations'), icon: <MapPin className="w-3.5 h-3.5" /> },
    { id: 'recipes', label: t('admin.tabs.recipes'), icon: <BookOpen className="w-3.5 h-3.5" /> },
    { id: 'techtrees', label: t('admin.tabs.techTrees'), icon: <GitBranch className="w-3.5 h-3.5" /> },
  ];

  /**
   * Render the recipe editor form (used for both create and edit).
   */
  const renderRecipeForm = () => {
    if (!editingRecipe) return null;

    const updateField = (field: keyof RecipeFormData, value: any) => {
      setEditingRecipe({ ...editingRecipe, [field]: value });
    };

    const updateIngredient = (idx: number, field: string, value: string) => {
      const updated = [...editingRecipe.ingredients];
      updated[idx] = { ...updated[idx], [field]: value };
      updateField('ingredients', updated);
    };

    const addIngredient = () => {
      updateField('ingredients', [...editingRecipe.ingredients, { item: '', amount: '1', label: '' }]);
    };

    const removeIngredient = (idx: number) => {
      updateField('ingredients', editingRecipe.ingredients.filter((_, i) => i !== idx));
    };

    const updateTool = (idx: number, field: string, value: string) => {
      const updated = [...editingRecipe.tools];
      updated[idx] = { ...updated[idx], [field]: value };
      updateField('tools', updated);
    };

    const addTool = () => {
      updateField('tools', [...editingRecipe.tools, { item: '', amount: '1', consumptionType: 'none', durabilityLoss: '0', consumeChance: '0' }]);
    };

    const removeTool = (idx: number) => {
      updateField('tools', editingRecipe.tools.filter((_, i) => i !== idx));
    };

    const updateMetadata = (idx: number, field: string, value: string) => {
      const updated = [...editingRecipe.metadata];
      updated[idx] = { ...updated[idx], [field]: value };
      updateField('metadata', updated);
    };

    const addMetadata = () => {
      updateField('metadata', [...editingRecipe.metadata, { key: '', value: '' }]);
    };

    const removeMetadata = (idx: number) => {
      updateField('metadata', editingRecipe.metadata.filter((_, i) => i !== idx));
    };

    const updateShowMetadata = (idx: number, field: string, value: string) => {
      const updated = [...editingRecipe.showMetadata];
      updated[idx] = { ...updated[idx], [field]: value };
      updateField('showMetadata', updated);
    };

    const addShowMetadata = () => {
      updateField('showMetadata', [...editingRecipe.showMetadata, { key: '', label: '' }]);
    };

    const removeShowMetadata = (idx: number) => {
      updateField('showMetadata', editingRecipe.showMetadata.filter((_, i) => i !== idx));
    };

    return (
      <FormModal
        title={isCreatingRecipe ? t('admin.recipes.createRecipe') : t('admin.recipes.editRecipe')}
        onClose={() => { setEditingRecipe(null); setEditingRecipeId(null); setIsCreatingRecipe(false); }}
      >
        {/* Basic Info */}
        <FormSection label={t('admin.recipes.basicInfo')}>
          <div className="grid grid-cols-3 gap-3">
            <FormInput label={t('admin.recipes.nameItem')} value={editingRecipe.name} onChange={v => updateField('name', v)} placeholder={t('admin.recipes.namePlaceholder')} />
            <FormInput label={t('admin.recipes.labelOptional')} value={editingRecipe.label} onChange={v => updateField('label', v)} placeholder={t('admin.recipes.labelPlaceholder')} />
            <SelectDropdown
              label={t('admin.recipes.recipeTable')}
              options={recipeTables.map(t => ({ value: t, label: t }))}
              value={editingRecipe.tableName}
              onChange={v => updateField('tableName', v)}
            />
          </div>
          <div>
            <FormInput label={t('admin.recipes.imageOptional')} value={editingRecipe.image} onChange={v => updateField('image', v)} placeholder={t('admin.recipes.imagePlaceholder')} />
            <div className="text-gray-600 text-[10px] mt-1 leading-relaxed">
              {t('admin.recipes.imageHelp')}
            </div>
          </div>
        </FormSection>

        {/* Crafting Settings */}
        <FormSection label={t('admin.recipes.craftingSettings')}>
          <div className="grid grid-cols-3 gap-3">
            <NumberInput label={t('admin.recipes.craftTime')} value={editingRecipe.craftTime} onChange={v => updateField('craftTime', v)} min={1} step={1} />
            <NumberInput label={t('admin.recipes.levelRequired')} value={editingRecipe.levelRequired} onChange={v => updateField('levelRequired', v)} min={0} step={1} />
            <NumberInput label={t('admin.recipes.xpReward')} value={editingRecipe.xpReward} onChange={v => updateField('xpReward', v)} min={0} step={1} />
          </div>
          <div className="grid grid-cols-3 gap-3">
            <NumberInput label={t('admin.recipes.tpReward')} value={editingRecipe.techPointsReward} onChange={v => updateField('techPointsReward', v)} min={0} step={1} />
            <NumberInput label={t('admin.recipes.outputAmount')} value={editingRecipe.outputAmount} onChange={v => updateField('outputAmount', v)} min={1} step={1} />
            <NumberInput label={t('admin.recipes.failChance')} value={editingRecipe.failChance} onChange={v => updateField('failChance', v)} min={0} max={100} step={1} />
          </div>
          <div className="grid grid-cols-3 gap-3">
            <FormInput label={t('admin.recipes.blueprintItem')} value={editingRecipe.blueprint} onChange={v => updateField('blueprint', v)} placeholder={t('admin.recipes.blueprintPlaceholder')} />
            <NumberInput label={t('admin.recipes.blueprintDurLoss')} value={editingRecipe.blueprintDurabilityLoss} onChange={v => updateField('blueprintDurabilityLoss', v)} min={0} step={1} />
            <NumberInput label={t('admin.recipes.cost')} value={editingRecipe.cost} onChange={v => updateField('cost', v)} min={0} step={1} />
          </div>
        </FormSection>

        {/* Ingredients */}
        <FormSection label={t('admin.recipes.ingredients')}>
          <div className="flex items-center justify-between -mt-1 mb-1">
            <span className="text-gray-600 text-[10px]">{t('admin.recipes.ingredientsCount', { count: editingRecipe.ingredients.length })}</span>
            <button onClick={addIngredient} className="text-[#4ADE80] hover:text-green-300 transition-colors p-1 rounded hover:bg-white/10">
              <Plus className="w-3.5 h-3.5" />
            </button>
          </div>
          {editingRecipe.ingredients.length > 0 && (
            <div className="flex items-center gap-2 -mb-1">
              <span className="flex-1 text-gray-500 text-[10px] font-medium">{t('admin.recipes.nameItem')}</span>
              <span className="w-24 text-gray-500 text-[10px] font-medium">{t('admin.recipes.amount')}</span>
              <span className="flex-1 text-gray-500 text-[10px] font-medium">{t('admin.recipes.labelOptional')}</span>
              <span className="w-[30px]" />
            </div>
          )}
          <div className="space-y-2">
            {editingRecipe.ingredients.map((ing, i) => (
              <div key={i} className="flex items-center gap-2">
                <input
                  type="text"
                  value={ing.item}
                  onChange={e => updateIngredient(i, 'item', e.target.value)}
                  placeholder={t('admin.recipes.ingredientNamePlaceholder')}
                  className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                  style={{ backgroundColor: '#252528' }}
                />
                <NumberInput value={ing.amount} onChange={v => updateIngredient(i, 'amount', v)} min={1} step={1} placeholder={t('admin.common.amt')} className="w-24" />
                <input
                  type="text"
                  value={ing.label}
                  onChange={e => updateIngredient(i, 'label', e.target.value)}
                  placeholder={t('admin.recipes.ingredientLabelPlaceholder')}
                  className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                  style={{ backgroundColor: '#252528' }}
                />
                <button onClick={() => removeIngredient(i)} className="text-gray-600 hover:text-red-400 transition-colors p-1 rounded hover:bg-white/10">
                  <Minus className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
        </FormSection>

        {/* Tools */}
        <FormSection label={t('admin.recipes.tools')}>
          <div className="flex items-center justify-between -mt-1 mb-1">
            <span className="text-gray-600 text-[10px]">{t('admin.recipes.toolsCount', { count: editingRecipe.tools.length })}</span>
            <button onClick={addTool} className="text-[#4ADE80] hover:text-green-300 transition-colors p-1 rounded hover:bg-white/10">
              <Plus className="w-3.5 h-3.5" />
            </button>
          </div>
          <div className="space-y-2">
            {editingRecipe.tools.map((tool, i) => (
              <div key={i} className="space-y-1.5">
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={tool.item}
                    onChange={e => updateTool(i, 'item', e.target.value)}
                    placeholder={t('admin.recipes.toolPlaceholder')}
                    className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                    style={{ backgroundColor: '#252528' }}
                  />
                  <NumberInput value={tool.amount} onChange={v => updateTool(i, 'amount', v)} min={1} step={1} placeholder={t('admin.common.amt')} className="w-24" />
                  <SelectDropdown
                    options={[
                      { value: 'none', label: t('admin.recipes.consumptionNone') },
                      { value: 'consume', label: t('admin.recipes.consumptionConsume') },
                      { value: 'durability', label: t('admin.recipes.consumptionDurability') },
                      { value: 'chance', label: t('admin.recipes.consumptionChance') },
                    ]}
                    value={tool.consumptionType}
                    onChange={v => updateTool(i, 'consumptionType', v)}
                  />
                  <button onClick={() => removeTool(i)} className="text-gray-600 hover:text-red-400 transition-colors p-1 rounded hover:bg-white/10">
                    <Minus className="w-3.5 h-3.5" />
                  </button>
                </div>
                {tool.consumptionType === 'durability' && (
                  <div className="ml-4">
                    <NumberInput label={t('admin.recipes.durabilityLoss')} value={tool.durabilityLoss} onChange={v => updateTool(i, 'durabilityLoss', v)} min={0} step={1} />
                  </div>
                )}
                {tool.consumptionType === 'chance' && (
                  <div className="ml-4">
                    <NumberInput label={t('admin.recipes.consumeChance')} value={tool.consumeChance} onChange={v => updateTool(i, 'consumeChance', v)} min={0} max={100} step={1} />
                  </div>
                )}
              </div>
            ))}
          </div>
        </FormSection>

        {/* Metadata */}
        <FormSection label={t('admin.recipes.metadata')}>
          <div className="flex items-center justify-between -mt-1 mb-1">
            <span className="text-gray-600 text-[10px]">{t('admin.recipes.metadataCount', { count: editingRecipe.metadata.length })}</span>
            <button onClick={addMetadata} className="text-[#4ADE80] hover:text-green-300 transition-colors p-1 rounded hover:bg-white/10">
              <Plus className="w-3.5 h-3.5" />
            </button>
          </div>
          {editingRecipe.metadata.length > 0 && (
            <div className="flex items-center gap-2 -mb-1">
              <span className="flex-1 text-gray-500 text-[10px] font-medium">{t('admin.recipes.metadataKey')}</span>
              <span className="flex-1 text-gray-500 text-[10px] font-medium">{t('admin.recipes.metadataValue')}</span>
              <span className="w-[30px]" />
            </div>
          )}
          <div className="space-y-2">
            {editingRecipe.metadata.map((meta, i) => (
              <div key={i} className="flex items-center gap-2">
                <input
                  type="text"
                  value={meta.key}
                  onChange={e => updateMetadata(i, 'key', e.target.value)}
                  placeholder={t('admin.recipes.metadataKeyPlaceholder')}
                  className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                  style={{ backgroundColor: '#252528' }}
                />
                <input
                  type="text"
                  value={meta.value}
                  onChange={e => updateMetadata(i, 'value', e.target.value)}
                  placeholder={t('admin.recipes.metadataValuePlaceholder')}
                  className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                  style={{ backgroundColor: '#252528' }}
                />
                <button onClick={() => removeMetadata(i)} className="text-gray-600 hover:text-red-400 transition-colors p-1 rounded hover:bg-white/10">
                  <Minus className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
          <div className="rounded-md px-3 py-2 mt-1 text-[10px] leading-normal text-gray-400" style={{ backgroundColor: 'rgba(255,255,255,0.03)', borderLeft: '2px solid rgba(168,85,247,0.4)' }}>
            <div className="mb-1">{t('admin.recipes.metadataHelp')}</div>
            <div className="text-gray-500"><span className="text-gray-300">image</span> = lockpick.png · <span className="text-gray-300">imageurl</span> = https://example.com/item.png · <span className="text-gray-300">description</span> = A finely crafted lockpick · <span className="text-gray-300">label</span> = Premium Lockpick · <span className="text-gray-300">weight</span> = 500</div>
          </div>
        </FormSection>

        {/* Show Metadata (ox_inventory tooltip display) */}
        <FormSection label={t('admin.recipes.showMetadata')}>
            <div className="flex items-center justify-between -mt-1 mb-1">
              <span className="text-gray-600 text-[10px]">{t('admin.recipes.showMetadataCount', { count: editingRecipe.showMetadata.length })}</span>
              <button onClick={addShowMetadata} className="text-[#4ADE80] hover:text-green-300 transition-colors p-1 rounded hover:bg-white/10">
                <Plus className="w-3.5 h-3.5" />
              </button>
            </div>
            {editingRecipe.showMetadata.length > 0 && (
              <div className="flex items-center gap-2 -mb-1">
                <span className="flex-1 text-gray-500 text-[10px] font-medium">{t('admin.recipes.showMetadataKey')}</span>
                <span className="flex-1 text-gray-500 text-[10px] font-medium">{t('admin.recipes.showMetadataLabel')}</span>
                <span className="w-[30px]" />
              </div>
            )}
            <div className="space-y-2">
              {editingRecipe.showMetadata.map((sm, i) => (
                <div key={i} className="flex items-center gap-2">
                  <SelectDropdown
                    options={[
                      { value: '', label: t('admin.recipes.showMetadataSelectKey') },
                      ...editingRecipe.metadata.filter(m => m.key.trim()).map(m => ({ value: m.key, label: m.key })),
                    ]}
                    value={sm.key}
                    onChange={v => updateShowMetadata(i, 'key', v)}
                    className="flex-1"
                  />
                  <input
                    type="text"
                    value={sm.label}
                    onChange={e => updateShowMetadata(i, 'label', e.target.value)}
                    placeholder={t('admin.recipes.showMetadataLabelPlaceholder')}
                    className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                    style={{ backgroundColor: '#252528' }}
                  />
                  <button onClick={() => removeShowMetadata(i)} className="text-gray-600 hover:text-red-400 transition-colors p-1 rounded hover:bg-white/10">
                    <Minus className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>
            <div className="text-gray-600 text-[10px] mt-1 leading-relaxed">
              {t('admin.recipes.showMetadataHelp')}
            </div>
          </FormSection>

        {/* Save/Cancel */}
        <div className="flex items-center justify-between pt-2">
          <div className="text-gray-600 text-[10px] italic">{t('admin.stations.changesNote')}</div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => { setEditingRecipe(null); setEditingRecipeId(null); setIsCreatingRecipe(false); }}
              className="px-5 py-2 text-xs rounded-lg text-gray-400 hover:text-white transition-colors"
              style={{ backgroundColor: '#252528' }}
            >
              {t('admin.common.cancel')}
            </button>
            <button
              onClick={isCreatingRecipe ? createRecipe : saveRecipeEdits}
              className="flex items-center gap-1.5 px-5 py-2 text-xs rounded-lg text-[#4ADE80] font-medium transition-colors hover:brightness-110"
              style={{ backgroundColor: 'rgba(74,222,128,0.15)' }}
            >
              <Check className="w-3 h-3" />
              {isCreatingRecipe ? t('admin.common.create') : t('admin.common.save')}
            </button>
          </div>
        </div>
      </FormModal>
    );
  };

  /**
   * Render the station creation/edit form as a modal overlay.
   */
  const renderStationForm = () => {
    if (!stationForm) return null;

    const closeForm = () => { setStationForm(null); setIsCreatingStation(false); setEditingStationKey(null); setStationPlayerTechOpen(false); setStationPlayerTech([]); setStationPlayerTechEdits({}); };

    return (
      <FormModal
        title={editingStationKey ? t('admin.stations.editStation') : t('admin.stations.createStation')}
        onClose={closeForm}
        accentColor="#C084FC"
      >
        {/* General Settings */}
        <FormSection label={t('admin.stations.general')}>
          <div className="grid grid-cols-3 gap-3">
            <FormInput label={t('admin.stations.label')} value={stationForm.label} onChange={v => setStationForm({ ...stationForm, label: v })} placeholder={t('admin.stations.labelPlaceholder')} />
            <SelectDropdown
              label={t('admin.common.type')}
              options={[
                ...workbenchTypes.map(t => ({ value: t.name, label: capitalize(t.name) })),
                ...(!workbenchTypes.some(t => t.name === stationForm.type) && stationForm.type
                  ? [{ value: stationForm.type, label: capitalize(stationForm.type) }]
                  : []),
              ]}
              value={stationForm.type}
              onChange={v => setStationForm({ ...stationForm, type: v })}
            />
            <NumberInput label={t('admin.stations.radius')} value={stationForm.radius} onChange={v => setStationForm({ ...stationForm, radius: v })} min={0.5} step={0.5} />
          </div>
          <div className="grid grid-cols-3 gap-3">
            <FormInput label={t('admin.stations.propModel')} value={stationForm.propModel} onChange={v => setStationForm({ ...stationForm, propModel: v })} placeholder="prop_tool_bench02" />
            <div>
              <div className="text-gray-500 text-[10px] font-medium mb-1">{t('admin.common.prop')}</div>
              <button
                onClick={() => setStationForm({ ...stationForm, propEnabled: !stationForm.propEnabled })}
                className={`w-full rounded-md px-2.5 py-1.5 text-xs border border-transparent ${stationForm.propEnabled ? 'text-[#4ADE80]' : 'text-gray-500'}`}
                style={{ backgroundColor: '#252528' }}
              >
                {stationForm.propEnabled ? t('admin.common.enabled') : t('admin.common.disabled')}
              </button>
            </div>
            <div>
              <FormInput label={t('admin.stations.ownerIdentifier')} value={stationForm.owner} onChange={v => setStationForm({ ...stationForm, owner: v })} placeholder={t('admin.stations.ownerHelp')} />
              <div className="text-gray-600 text-[10px] mt-0.5">{t('admin.stations.ownerHelp')}</div>
            </div>
          </div>
        </FormSection>

        {/* Access Control */}
        <FormSection label={t('admin.stations.accessControl')}>
          {/* Jobs */}
          <div>
            <div className="text-gray-500 text-[10px] font-medium mb-1.5">{t('admin.stations.jobs')}</div>
            <div className="flex gap-2 items-end">
              <div className="flex-1">
                <input
                  className="w-full rounded-md px-2.5 py-1.5 text-xs text-gray-300 border border-transparent outline-none"
                  style={{ backgroundColor: '#252528' }}
                  placeholder={t('admin.stations.jobNamePlaceholder')}
                  value={jobInputName}
                  onChange={e => setJobInputName(e.target.value)}
                  onKeyDown={e => {
                    if (e.key === 'Enter' && jobInputName.trim()) {
                      setStationForm({ ...stationForm, jobs: [...stationForm.jobs, { name: jobInputName.trim(), minGrade: parseInt(jobInputGrade) || 0 }] });
                      setJobInputName(''); setJobInputGrade('0');
                    }
                  }}
                />
              </div>
              <div className="w-20">
                <NumberInput label={t('admin.stations.minGrade')} value={jobInputGrade} onChange={v => setJobInputGrade(v)} min={0} step={1} />
              </div>
              <button
                onClick={() => {
                  if (!jobInputName.trim()) return;
                  setStationForm({ ...stationForm, jobs: [...stationForm.jobs, { name: jobInputName.trim(), minGrade: parseInt(jobInputGrade) || 0 }] });
                  setJobInputName(''); setJobInputGrade('0');
                }}
                className="rounded-md px-2 py-1.5 text-xs font-medium text-[#4ADE80] hover:text-[#86EFAC] transition-colors border border-transparent"
                style={{ backgroundColor: '#252528' }}
              >+</button>
            </div>
            {stationForm.jobs.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mt-2">
                {stationForm.jobs.map((job, i) => (
                  <span key={i} className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-[11px]" style={{ backgroundColor: '#252528' }}>
                    <span className="text-purple-300">{job.name}</span>
                    <span className="text-gray-500">{t('admin.stations.gradeLabel', { grade: job.minGrade })}</span>
                    <button onClick={() => setStationForm({ ...stationForm, jobs: stationForm.jobs.filter((_, j) => j !== i) })} className="text-gray-600 hover:text-red-400 transition-colors ml-0.5">&times;</button>
                  </span>
                ))}
              </div>
            )}
          </div>
          {/* Gangs */}
          <div>
            <div className="text-gray-500 text-[10px] font-medium mb-1.5">{t('admin.stations.gangs')}</div>
            <div className="flex gap-2 items-end">
              <div className="flex-1">
                <input
                  className="w-full rounded-md px-2.5 py-1.5 text-xs text-gray-300 border border-transparent outline-none"
                  style={{ backgroundColor: '#252528' }}
                  placeholder={t('admin.stations.gangNamePlaceholder')}
                  value={gangInputName}
                  onChange={e => setGangInputName(e.target.value)}
                  onKeyDown={e => {
                    if (e.key === 'Enter' && gangInputName.trim()) {
                      setStationForm({ ...stationForm, gangs: [...stationForm.gangs, { name: gangInputName.trim(), minGrade: parseInt(gangInputGrade) || 0 }] });
                      setGangInputName(''); setGangInputGrade('0');
                    }
                  }}
                />
              </div>
              <div className="w-20">
                <NumberInput label={t('admin.stations.minGrade')} value={gangInputGrade} onChange={v => setGangInputGrade(v)} min={0} step={1} />
              </div>
              <button
                onClick={() => {
                  if (!gangInputName.trim()) return;
                  setStationForm({ ...stationForm, gangs: [...stationForm.gangs, { name: gangInputName.trim(), minGrade: parseInt(gangInputGrade) || 0 }] });
                  setGangInputName(''); setGangInputGrade('0');
                }}
                className="rounded-md px-2 py-1.5 text-xs font-medium text-[#4ADE80] hover:text-[#86EFAC] transition-colors border border-transparent"
                style={{ backgroundColor: '#252528' }}
              >+</button>
            </div>
            {stationForm.gangs.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mt-2">
                {stationForm.gangs.map((gang, i) => (
                  <span key={i} className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-[11px]" style={{ backgroundColor: '#252528' }}>
                    <span className="text-cyan-300">{gang.name}</span>
                    <span className="text-gray-500">{t('admin.stations.gradeLabel', { grade: gang.minGrade })}</span>
                    <button onClick={() => setStationForm({ ...stationForm, gangs: stationForm.gangs.filter((_, j) => j !== i) })} className="text-gray-600 hover:text-red-400 transition-colors ml-0.5">&times;</button>
                  </span>
                ))}
              </div>
            )}
          </div>
          <div className="text-gray-600 text-[10px]">{t('admin.stations.accessControlHelp')}</div>
        </FormSection>

        {/* Recipes & Tech Trees */}
        <FormSection label={t('admin.stations.recipesAndTechTrees')}>
          <div className="grid grid-cols-2 gap-3">
            <MultiSelectDropdown label={t('admin.stations.recipeTables')} options={recipeTables} selected={stationForm.recipes} onChange={v => setStationForm({ ...stationForm, recipes: v })} placeholder={t('admin.stations.selectTables')} />
            <MultiSelectDropdown label={t('admin.stations.techTrees')} options={Object.keys(techTrees)} selected={stationForm.techTrees} onChange={v => setStationForm({ ...stationForm, techTrees: v })} placeholder={t('admin.stations.selectTechTrees')} />
          </div>
          {/* Warn if tech tree nodes reference recipes not in assigned tables */}
          {(() => {
            if (!stationForm.techTrees.length || !Object.keys(recipes).length) return null;
            const assignedRecipeIds = new Set<string>();
            const assignedTables = stationForm.recipes;
            for (const table of assignedTables) {
              for (const r of (recipes[table] || [])) {
                assignedRecipeIds.add(r.id);
              }
            }
            // Build a lookup: recipeId → { recipe, tableName } across ALL tables
            const recipeIndex: Record<string, { recipe: AdminRecipe; table: string }> = {};
            for (const [tableName, tableRecipes] of Object.entries(recipes)) {
              for (const r of tableRecipes) {
                recipeIndex[r.id] = { recipe: r, table: tableName };
              }
            }
            const warnings: { treeLabel: string; recipeName: string; recipeTable: string | null }[] = [];
            for (const treeId of stationForm.techTrees) {
              const tree = techTrees[treeId];
              if (!tree?.nodes) continue;
              for (const node of tree.nodes) {
                if (node.recipeId && !assignedRecipeIds.has(node.recipeId)) {
                  const found = recipeIndex[node.recipeId];
                  warnings.push({
                    treeLabel: tree.label,
                    recipeName: found ? (found.recipe.label || capitalize(found.recipe.name)) : node.recipeId,
                    recipeTable: found ? found.table : null,
                  });
                }
              }
            }
            if (!warnings.length) return null;
            const unique = warnings.filter((w, i, arr) => arr.findIndex(x => x.recipeName === w.recipeName && x.treeLabel === w.treeLabel) === i);
            // Group by table for cleaner display
            const byTable = new Map<string, { treeLabel: string; recipeName: string }[]>();
            for (const w of unique) {
              const key = w.recipeTable || 'unknown';
              if (!byTable.has(key)) byTable.set(key, []);
              byTable.get(key)!.push(w);
            }
            return (
              <div className="rounded-md px-3 py-2.5 text-[10px] leading-relaxed space-y-1.5" style={{ backgroundColor: 'rgba(251,191,36,0.08)', borderLeft: '2px solid rgba(251,191,36,0.4)' }}>
                <div className="text-amber-400 font-medium">{t('admin.stations.mismatchTitle')}</div>
                <div className="text-amber-300/60">{t('admin.stations.mismatchDescription')}</div>
                {[...byTable.entries()].map(([table, items]) => (
                  <div key={table} className="text-amber-300/70">
                    {items.map(w => <span key={w.recipeName} className="text-amber-400">{w.recipeName}</span>).reduce<React.ReactNode[]>((acc, el, i) => i === 0 ? [el] : [...acc, ', ', el], [])}
                    {table !== 'unknown'
                      ? <> — {t('admin.stations.mismatchExistsInTable', { table })}</>
                      : <> — {t('admin.stations.mismatchNotFound')}</>
                    }
                  </div>
                ))}
              </div>
            );
          })()}
        </FormSection>

        {/* Behavior */}
        <FormSection label={t('admin.stations.behavior')}>
          <div className="grid grid-cols-4 gap-3">
            <div>
              <div className="text-gray-500 text-[10px] font-medium mb-1">{t('admin.stations.craftingQueue')}</div>
              <button
                onClick={() => setStationForm({ ...stationForm, sharedCrafting: !stationForm.sharedCrafting })}
                className={`w-full rounded-md px-2.5 py-1.5 text-xs border border-transparent ${stationForm.sharedCrafting ? 'text-[#4ADE80]' : 'text-gray-500'}`}
                style={{ backgroundColor: '#252528' }}
              >
                {stationForm.sharedCrafting ? t('admin.common.shared') : t('admin.common.individual')}
              </button>
            </div>
            <div>
              <div className="text-gray-500 text-[10px] font-medium mb-1">{t('admin.stations.stagingInventory')}</div>
              <button
                onClick={() => setStationForm({ ...stationForm, sharedStaging: !stationForm.sharedStaging })}
                className={`w-full rounded-md px-2.5 py-1.5 text-xs border border-transparent ${stationForm.sharedStaging ? 'text-cyan-400' : 'text-gray-500'}`}
                style={{ backgroundColor: '#252528' }}
              >
                {stationForm.sharedStaging ? t('admin.common.shared') : t('admin.common.individual')}
              </button>
            </div>
            <div>
              <div className="text-gray-500 text-[10px] font-medium mb-1">{t('admin.stations.techTreeLabel')}</div>
              <button
                onClick={() => setStationForm({ ...stationForm, sharedTech: !stationForm.sharedTech })}
                className={`w-full rounded-md px-2.5 py-1.5 text-xs border border-transparent ${stationForm.sharedTech ? 'text-purple-400' : 'text-gray-500'}`}
                style={{ backgroundColor: '#252528' }}
              >
                {stationForm.sharedTech ? t('admin.common.shared') : t('admin.common.perPlayer')}
              </button>
            </div>
            {stationForm.sharedTech ? (
              <NumberInput label={t('admin.stations.stationTP')} value={stationForm.stationTechPoints} onChange={v => setStationForm({ ...stationForm, stationTechPoints: v })} min={0} step={1} />
            ) : editingStationKey && editingStationKey.startsWith('placed_') ? (
              <div>
                <div className="text-gray-500 text-[10px] font-medium mb-1">{t('admin.stations.playerTech')}</div>
                <button
                  onClick={async () => {
                    if (stationPlayerTechOpen) {
                      setStationPlayerTechOpen(false);
                      return;
                    }
                    setStationPlayerTechLoading(true);
                    try {
                      const data = await fetchNui<{ identifier: string; name: string; tech_points: number; isOwner: boolean }[]>('admin:getStationPlayersTech', { stationKey: editingStationKey });
                      setStationPlayerTech(data || []);
                      setStationPlayerTechEdits(Object.fromEntries((data || []).map(p => [p.identifier, String(p.tech_points)])));
                      setStationPlayerTechOpen(true);
                    } catch { setStationPlayerTech([]); }
                    setStationPlayerTechLoading(false);
                  }}
                  className="w-full rounded-md px-2.5 py-1.5 text-xs border border-transparent text-amber-400 hover:text-amber-300 transition-colors"
                  style={{ backgroundColor: '#252528' }}
                >
                  {stationPlayerTechLoading ? t('admin.common.loading') : stationPlayerTechOpen ? t('admin.common.hide') : t('admin.common.viewPlayers')}
                </button>
              </div>
            ) : (
              <div className="flex items-end">
                <span className="text-gray-600 text-[11px] pb-2">{t('admin.common.perPlayerTP')}</span>
              </div>
            )}
          </div>

          {/* Per-player tech points list */}
          {stationPlayerTechOpen && !stationForm.sharedTech && editingStationKey?.startsWith('placed_') && (
            <div className="rounded-lg border overflow-hidden" style={{ borderColor: 'rgba(251,191,36,0.15)', backgroundColor: 'rgba(26,26,31,0.4)' }}>
              <div className="flex items-center justify-between px-3.5 py-2.5" style={{ backgroundColor: 'rgba(251,191,36,0.06)' }}>
                <span className="text-amber-400 text-[11px] font-medium">{t('admin.stations.playerTechPoints', { type: stationForm.type })}</span>
                <button
                  onClick={async () => {
                    let allSuccess = true;
                    for (const player of stationPlayerTech) {
                      const newTP = parseInt(stationPlayerTechEdits[player.identifier] ?? String(player.tech_points)) || 0;
                      if (newTP !== player.tech_points) {
                        const result = await fetchNui<{ success: boolean }>('admin:updatePlayerTechPoints', {
                          identifier: player.identifier,
                          workbenchType: stationForm.type,
                          tech_points: newTP,
                        });
                        if (!result?.success) allSuccess = false;
                      }
                    }
                    if (allSuccess) {
                      showToast(t('admin.players.techPointsUpdated'), 'success');
                      const data = await fetchNui<{ identifier: string; name: string; tech_points: number; isOwner: boolean }[]>('admin:getStationPlayersTech', { stationKey: editingStationKey });
                      setStationPlayerTech(data || []);
                      setStationPlayerTechEdits(Object.fromEntries((data || []).map(p => [p.identifier, String(p.tech_points)])));
                    } else {
                      showToast(t('admin.players.techPointsUpdatePartial'), 'error');
                    }
                  }}
                  className="text-[#4ADE80] hover:text-green-300 text-[11px] px-2.5 py-1 rounded hover:bg-white/10 transition-colors"
                >
                  {t('admin.types.saveAll')}
                </button>
              </div>
              {stationPlayerTech.length === 0 ? (
                <div className="px-3.5 py-4 text-center text-gray-600 text-[11px]">{t('admin.types.noPlayersWithAccess')}</div>
              ) : (
                <div className="divide-y" style={{ borderColor: 'rgba(255,255,255,0.04)' }}>
                  {stationPlayerTech.map(player => (
                    <div key={player.identifier} className="flex items-center gap-3 px-3.5 py-2.5" style={{ borderColor: 'rgba(255,255,255,0.04)' }}>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="text-gray-300 text-xs font-medium truncate">{player.name}</span>
                          {player.isOwner && (
                            <span className="text-[9px] px-1.5 py-0.5 rounded text-amber-400 flex-shrink-0" style={{ backgroundColor: 'rgba(251,191,36,0.1)' }}>{t('admin.common.owner')}</span>
                          )}
                        </div>
                        <div className="text-gray-600 text-[10px] font-mono truncate mt-0.5">{player.identifier}</div>
                      </div>
                      <div className="flex-shrink-0 w-28">
                        <NumberInput
                          label={t('admin.common.tp')}
                          value={stationPlayerTechEdits[player.identifier] ?? String(player.tech_points)}
                          onChange={v => setStationPlayerTechEdits(prev => ({ ...prev, [player.identifier]: v }))}
                          min={0}
                          step={1}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </FormSection>

        {/* Blip Settings */}
        <FormSection label={t('admin.stations.blipSettings')}>
          <div className="grid grid-cols-5 gap-3">
            <div>
              <div className="text-gray-500 text-[10px] font-medium mb-1">{t('admin.stations.blip')}</div>
              <button
                onClick={() => setStationForm({ ...stationForm, blipEnabled: !stationForm.blipEnabled })}
                className={`w-full rounded-md px-2.5 py-1.5 text-xs border border-transparent ${stationForm.blipEnabled ? 'text-[#4ADE80]' : 'text-gray-500'}`}
                style={{ backgroundColor: '#252528' }}
              >
                {stationForm.blipEnabled ? t('admin.common.on') : t('admin.common.off')}
              </button>
            </div>
            <NumberInput label={t('admin.stations.sprite')} value={stationForm.blipSprite} onChange={v => setStationForm({ ...stationForm, blipSprite: v })} min={0} step={1} />
            <NumberInput label={t('admin.stations.color')} value={stationForm.blipColor} onChange={v => setStationForm({ ...stationForm, blipColor: v })} min={0} step={1} />
            <FormInput label={t('admin.stations.scale')} value={stationForm.blipScale} onChange={v => setStationForm({ ...stationForm, blipScale: v })} />
            <FormInput label={t('admin.stations.blipLabel')} value={stationForm.blipLabel} onChange={v => setStationForm({ ...stationForm, blipLabel: v })} placeholder={t('admin.stations.blipLabelPlaceholder')} />
          </div>
        </FormSection>

        {/* Location */}
        <FormSection label={t('admin.stations.location')}>
          <div className="grid grid-cols-5 gap-3">
            <NumberInput
              label="X"
              value={stationForm.coords ? String(stationForm.coords.x) : ''}
              onChange={v => {
                const n = parseFloat(v);
                setStationForm({ ...stationForm, coords: { x: isNaN(n) ? 0 : n, y: stationForm.coords?.y ?? 0, z: stationForm.coords?.z ?? 0 } });
              }}
              step={0.1}
              placeholder="0.0"
            />
            <NumberInput
              label="Y"
              value={stationForm.coords ? String(stationForm.coords.y) : ''}
              onChange={v => {
                const n = parseFloat(v);
                setStationForm({ ...stationForm, coords: { x: stationForm.coords?.x ?? 0, y: isNaN(n) ? 0 : n, z: stationForm.coords?.z ?? 0 } });
              }}
              step={0.1}
              placeholder="0.0"
            />
            <NumberInput
              label="Z"
              value={stationForm.coords ? String(stationForm.coords.z) : ''}
              onChange={v => {
                const n = parseFloat(v);
                setStationForm({ ...stationForm, coords: { x: stationForm.coords?.x ?? 0, y: stationForm.coords?.y ?? 0, z: isNaN(n) ? 0 : n } });
              }}
              step={0.1}
              placeholder="0.0"
            />
            <NumberInput
              label={t('admin.stations.heading')}
              value={String(stationForm.heading)}
              onChange={v => {
                const n = parseFloat(v);
                setStationForm({ ...stationForm, heading: isNaN(n) ? 0 : n });
              }}
              min={0}
              max={360}
              step={0.5}
            />
            <div>
              <div className="text-gray-500 text-[10px] font-medium mb-1">&nbsp;</div>
              <button
                onClick={beginStationPlacement}
                disabled={isPlacingStation}
                className="w-full flex items-center justify-center gap-1.5 px-2.5 py-1.5 rounded-md text-xs font-medium text-white transition-colors hover:brightness-110 disabled:opacity-50"
                style={{ backgroundColor: 'rgba(168,85,247,0.6)' }}
              >
                <MapPin className="w-3.5 h-3.5" />
                {isPlacingStation ? t('admin.common.placing') : t('admin.common.place')}
              </button>
            </div>
          </div>
        </FormSection>

        {/* Save / Cancel buttons */}
        <div className="flex justify-end gap-3 pt-2">
          <button
            onClick={closeForm}
            className="px-5 py-2 text-xs rounded-lg text-gray-400 hover:text-white transition-colors"
            style={{ backgroundColor: '#252528' }}
          >
            {t('admin.common.cancel')}
          </button>
          <button
            onClick={editingStationKey ? updateExistingStation : saveNewStation}
            className="px-5 py-2 text-xs rounded-lg text-white font-medium transition-colors hover:brightness-110"
            style={{ backgroundColor: 'rgba(168,85,247,0.6)' }}
          >
            {editingStationKey ? t('admin.common.update') : t('admin.common.save')}
          </button>
        </div>
      </FormModal>
    );
  };

  return (
    <div className="w-full h-full flex items-center justify-center" style={{ backgroundColor: 'rgba(0, 0, 0, 0.6)' }}>
      {confirm && <ConfirmDialog message={confirm.message} slider={confirm.slider} onConfirm={(count) => { confirm.onConfirm(count); setConfirm(null); }} onCancel={() => setConfirm(null)} />}
      {editingRecipe && renderRecipeForm()}
      {stationForm && renderStationForm()}

      {/* Manage Tables Modal */}
      {showManageTables && (
        <FormModal
          title={t('admin.types.manageRecipeTables')}
          onClose={() => { setShowManageTables(false); setNewTableName(''); }}
          accentColor="#4ADE80"
        >
          <div className="rounded-md px-3 py-2.5 text-[10px] leading-relaxed text-gray-400" style={{ backgroundColor: 'rgba(255,255,255,0.02)', borderLeft: '2px solid rgba(74,222,128,0.3)' }}>
            {t('admin.types.recipeTableDescription')}
          </div>

          <FormSection label={t('admin.tables.createNewTable')}>
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={newTableName}
                onChange={e => setNewTableName(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                placeholder={t('admin.tables.tableNamePlaceholder')}
                className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                style={{ backgroundColor: '#252528' }}
                onKeyDown={async e => {
                  if (e.key === 'Enter' && newTableName.trim()) {
                    const name = newTableName.trim();
                    if (recipeTables.includes(name)) { showToast(t('admin.tables.tableAlreadyExists'), 'error'); return; }
                    const result = await fetchNui<{ success: boolean }>('admin:createTable', { tableName: name });
                    if (result?.success) {
                      setRecipes(prev => ({ ...prev, [name]: [] }));
                      setTableSources(prev => ({ ...prev, [name]: 'admin' }));
                      setNewTableName('');
                      showToast(t('admin.tables.tableCreated', { name }), 'success');
                    } else {
                      showToast(t('admin.tables.tableCreateFailed'), 'error');
                    }
                  }
                }}
              />
              <button
                onClick={async () => {
                  const name = newTableName.trim();
                  if (!name) { showToast(t('admin.tables.enterTableName'), 'error'); return; }
                  if (recipeTables.includes(name)) { showToast(t('admin.tables.tableAlreadyExists'), 'error'); return; }
                  const result = await fetchNui<{ success: boolean }>('admin:createTable', { tableName: name });
                  if (result?.success) {
                    setRecipes(prev => ({ ...prev, [name]: [] }));
                    setTableSources(prev => ({ ...prev, [name]: 'admin' }));
                    setNewTableName('');
                    showToast(t('admin.tables.tableCreated', { name }), 'success');
                  } else {
                    showToast(t('admin.tables.tableCreateFailed'), 'error');
                  }
                }}
                className="flex items-center gap-1.5 px-3.5 py-1.5 text-[10px] rounded-lg text-[#4ADE80] transition-colors hover:brightness-110"
                style={{ backgroundColor: 'rgba(74,222,128,0.15)' }}
              >
                <Plus className="w-3 h-3" /> {t('admin.common.create')}
              </button>
            </div>
          </FormSection>

          <FormSection label={t('admin.tables.existingTables', { count: recipeTables.length })}>
            <div className="space-y-1.5 h-[320px] overflow-y-auto pr-1">
              {recipeTables.map(table => {
                const recipeCount = (recipes[table] || []).length;
                const source = tableSources[table] || 'config';
                const stationsUsingTable = stations.filter(s => s.recipes?.includes(table));
                return (
                  <div
                    key={table}
                    className="rounded-lg px-3 py-2.5 border"
                    style={{ backgroundColor: '#1a1a1f', borderColor: 'rgba(255,255,255,0.04)' }}
                  >
                    <div className="flex items-center gap-2">
                      <span className="text-white text-xs font-medium flex-1">{capitalize(table)}</span>
                      <span className="text-gray-500 text-[10px]">{recipeCount} {recipeCount !== 1 ? t('admin.types.recipes') : t('admin.types.recipe')}</span>
                      <span
                        className="text-[10px] px-2 py-0.5 rounded flex-shrink-0"
                        style={{
                          backgroundColor: source === 'config' ? 'rgba(96,165,250,0.1)' : 'rgba(168,85,247,0.1)',
                          color: source === 'config' ? '#60A5FA' : '#C084FC',
                        }}
                      >
                        {source === 'config' ? t('admin.common.config') : t('admin.common.admin')}
                      </span>
                      {source === 'admin' && (
                        <button
                          onClick={() => setConfirm({
                            message: recipeCount > 0
                              ? t('admin.tables.deleteTableRecipes', { count: recipeCount, name: table })
                              : t('admin.tables.deleteTableEmpty', { name: table }),
                            onConfirm: async () => {
                              const result = await fetchNui<{ success: boolean; error?: string }>('admin:deleteTable', { tableName: table });
                              if (result?.success) {
                                setRecipes(prev => {
                                  const next = { ...prev };
                                  delete next[table];
                                  return next;
                                });
                                setTableSources(prev => {
                                  const next = { ...prev };
                                  delete next[table];
                                  return next;
                                });
                                if (selectedTable === table) {
                                  const remaining = recipeTables.filter(t => t !== table);
                                  setSelectedTable(remaining[0] || '');
                                }
                                showToast(t('admin.tables.tableDeleted', { name: table }), 'success');
                              } else {
                                showToast(result?.error || t('admin.tables.tableDeleteFailed'), 'error');
                              }
                            },
                          })}
                          className="p-1 rounded text-gray-600 hover:text-red-400 transition-colors"
                          title={t('admin.types.deleteTable')}
                        >
                          <Trash2 className="w-3 h-3" />
                        </button>
                      )}
                    </div>
                    {stationsUsingTable.length > 0 && (
                      <div className="text-gray-600 text-[10px] mt-1">
                        {t('admin.types.usedBy', { stations: stationsUsingTable.map(s => s.label).join(', ') })}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </FormSection>
        </FormModal>
      )}

      {/* Manage Types Modal */}
      {showManageTypes && (
        <FormModal
          title={t('admin.types.manageWorkbenchTypes')}
          onClose={() => { setShowManageTypes(false); setRenamingType(null); setNewTypeName(''); setEditingTypeLevels(null); }}
          accentColor="#22D3EE"
        >
          <div className="rounded-md px-3 py-2.5 text-[10px] leading-relaxed text-gray-400" style={{ backgroundColor: 'rgba(255,255,255,0.02)', borderLeft: '2px solid rgba(34,211,238,0.3)' }}>
            {t('admin.types.typeDescription')}
          </div>

          <FormSection label={t('admin.types.createNewType')}>
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={newTypeName}
                onChange={e => setNewTypeName(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                placeholder={t('admin.types.typeNamePlaceholder')}
                className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                style={{ backgroundColor: '#252528' }}
                onKeyDown={async e => {
                  if (e.key === 'Enter' && newTypeName.trim()) {
                    const name = newTypeName.trim();
                    if (workbenchTypes.some(t => t.name === name)) { showToast(t('admin.types.typeAlreadyExists'), 'error'); return; }
                    const result = await fetchNui<{ success: boolean; error?: string }>('admin:createType', { typeName: name });
                    if (result?.success) {
                      setWorkbenchTypes(prev => [...prev, { name, source: 'admin' as const, stations: [] }].sort((a, b) => a.name.localeCompare(b.name)));
                      setNewTypeName('');
                      showToast(t('admin.types.typeCreated', { name }), 'success');
                    } else {
                      showToast(result?.error || t('admin.types.typeCreateFailed'), 'error');
                    }
                  }
                }}
              />
              <button
                onClick={async () => {
                  const name = newTypeName.trim();
                  if (!name) { showToast(t('admin.types.enterTypeName'), 'error'); return; }
                  if (workbenchTypes.some(t => t.name === name)) { showToast(t('admin.types.typeAlreadyExists'), 'error'); return; }
                  const result = await fetchNui<{ success: boolean; error?: string }>('admin:createType', { typeName: name });
                  if (result?.success) {
                    setWorkbenchTypes(prev => [...prev, { name, source: 'admin' as const, stations: [] }].sort((a, b) => a.name.localeCompare(b.name)));
                    setNewTypeName('');
                    showToast(t('admin.types.typeCreated', { name }), 'success');
                  } else {
                    showToast(result?.error || t('admin.types.typeCreateFailed'), 'error');
                  }
                }}
                className="flex items-center gap-1.5 px-3.5 py-1.5 text-[10px] rounded-lg text-cyan-400 transition-colors hover:brightness-110"
                style={{ backgroundColor: 'rgba(34,211,238,0.15)' }}
              >
                <Plus className="w-3 h-3" /> {t('admin.common.create')}
              </button>
            </div>
          </FormSection>

          <FormSection label={t('admin.types.existingTypes', { count: workbenchTypes.length })}>
            <div className="space-y-1.5 max-h-[420px] overflow-y-auto pr-1">
              {workbenchTypes.map(wt => (
                <div
                  key={wt.name}
                  className="rounded-lg px-3 py-2.5 border transition-colors"
                  style={{
                    backgroundColor: editingTypeLevels === wt.name ? '#1c1c22' : '#1a1a1f',
                    borderColor: editingTypeLevels === wt.name ? 'rgba(34,211,238,0.15)' : 'rgba(255,255,255,0.04)',
                  }}
                >
                  <div className="flex items-center gap-2">
                    {renamingType === wt.name ? (
                      <input
                        type="text"
                        value={renameTypeName}
                        onChange={e => setRenameTypeName(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                        className="flex-1 rounded-md px-2.5 py-1 text-white text-xs border border-cyan-500/30 focus:outline-none"
                        style={{ backgroundColor: '#252528' }}
                        autoFocus
                        onKeyDown={async e => {
                          if (e.key === 'Enter' && renameTypeName.trim()) {
                            if (renameTypeName.trim() === wt.name) { setRenamingType(null); return; }
                            const result = await fetchNui<{ success: boolean; error?: string }>('admin:updateType', { oldName: wt.name, newName: renameTypeName.trim() });
                            if (result?.success) {
                              const newName = renameTypeName.trim();
                              setWorkbenchTypes(prev => prev.map(t => t.name === wt.name ? { ...t, name: newName } : t).sort((a, b) => a.name.localeCompare(b.name)));
                              if (editingTypeLevels === wt.name) setEditingTypeLevels(newName);
                              if (levelConfigs[wt.name]) setLevelConfigs(prev => { const n = { ...prev, [newName]: prev[wt.name] }; delete n[wt.name]; return n; });
                              setRenamingType(null);
                              showToast(t('admin.types.typeRenamed'), 'success');
                            } else {
                              showToast(result?.error || t('admin.types.typeRenameFailed'), 'error');
                            }
                          } else if (e.key === 'Escape') {
                            setRenamingType(null);
                          }
                        }}
                      />
                    ) : (
                      <span className="text-white text-xs font-medium flex-1">{capitalize(wt.name)}</span>
                    )}
                    <span
                      className="text-[10px] px-2 py-0.5 rounded flex-shrink-0"
                      style={{
                        backgroundColor: wt.source === 'config' ? 'rgba(96,165,250,0.1)' : 'rgba(168,85,247,0.1)',
                        color: wt.source === 'config' ? '#60A5FA' : '#C084FC',
                      }}
                    >
                      {wt.source === 'config' ? t('admin.common.config') : t('admin.common.admin')}
                    </span>
                    {wt.source === 'admin' && renamingType !== wt.name && (
                      <>
                        <button
                          onClick={() => {
                            if (editingTypeLevels === wt.name) {
                              setEditingTypeLevels(null);
                            } else {
                              const existing = levelConfigs[wt.name];
                              if (existing) {
                                const lvls: string[] = [];
                                for (let i = 0; i < existing.maxLevel; i++) {
                                  lvls.push(String(existing.levels[i] ?? 0));
                                }
                                setTypeLevelConfig({ maxLevel: String(existing.maxLevel), levels: lvls });
                              } else {
                                const defaultMax = 10;
                                const lvls: string[] = [];
                                for (let i = 0; i < defaultMax; i++) {
                                  lvls.push(String(Math.round(i * 100 * Math.pow(1.5, i))));
                                }
                                lvls[0] = '0';
                                setTypeLevelConfig({ maxLevel: String(defaultMax), levels: lvls });
                              }
                              setEditingTypeLevels(wt.name);
                            }
                          }}
                          className={`p-1 rounded transition-colors ${editingTypeLevels === wt.name ? 'text-cyan-400' : 'text-gray-600 hover:text-cyan-400'}`}
                          title={t('admin.types.configureLevels')}
                        >
                          <SlidersHorizontal className="w-3 h-3" />
                        </button>
                        <button
                          onClick={() => { setRenamingType(wt.name); setRenameTypeName(wt.name); }}
                          className="p-1 rounded text-gray-600 hover:text-cyan-400 transition-colors"
                          title={t('admin.types.renameType')}
                        >
                          <Edit3 className="w-3 h-3" />
                        </button>
                        <button
                          onClick={() => setConfirm({
                            message: wt.stations.length > 0
                              ? t('admin.types.cannotDeleteInUse', { name: wt.name, count: wt.stations.length })
                              : t('admin.types.deleteTypeConfirm', { name: wt.name }),
                            onConfirm: async () => {
                              if (wt.stations.length > 0) return;
                              const result = await fetchNui<{ success: boolean; error?: string }>('admin:deleteType', { typeName: wt.name });
                              if (result?.success) {
                                setWorkbenchTypes(prev => prev.filter(t => t.name !== wt.name));
                                showToast(t('admin.types.typeDeleted'), 'success');
                              } else {
                                showToast(result?.error || t('admin.types.typeDeleteFailed'), 'error');
                              }
                            },
                          })}
                          className="p-1 rounded text-gray-600 hover:text-red-400 transition-colors"
                          title={t('admin.types.deleteType')}
                        >
                          <Trash2 className="w-3 h-3" />
                        </button>
                      </>
                    )}
                    {wt.source === 'config' && levelConfigs[wt.name] && (
                      <span className="text-[9px] px-1.5 py-0.5 rounded text-gray-500" style={{ backgroundColor: 'rgba(255,255,255,0.03)' }}>
                        {t('admin.types.levelRange', { max: levelConfigs[wt.name].maxLevel })}
                      </span>
                    )}
                    {renamingType === wt.name && (
                      <>
                        <button
                          onClick={async () => {
                            if (!renameTypeName.trim()) return;
                            if (renameTypeName.trim() === wt.name) { setRenamingType(null); return; }
                            const result = await fetchNui<{ success: boolean; error?: string }>('admin:updateType', { oldName: wt.name, newName: renameTypeName.trim() });
                            if (result?.success) {
                              const newName = renameTypeName.trim();
                              setWorkbenchTypes(prev => prev.map(t => t.name === wt.name ? { ...t, name: newName } : t).sort((a, b) => a.name.localeCompare(b.name)));
                              if (editingTypeLevels === wt.name) setEditingTypeLevels(newName);
                              if (levelConfigs[wt.name]) setLevelConfigs(prev => { const n = { ...prev, [newName]: prev[wt.name] }; delete n[wt.name]; return n; });
                              setRenamingType(null);
                              showToast(t('admin.types.typeRenamed'), 'success');
                            } else {
                              showToast(result?.error || t('admin.types.typeRenameFailed'), 'error');
                            }
                          }}
                          className="p-1 rounded text-gray-600 hover:text-[#4ADE80] transition-colors"
                          title={t('admin.common.save')}
                        >
                          <Check className="w-3 h-3" />
                        </button>
                        <button
                          onClick={() => setRenamingType(null)}
                          className="p-1 rounded text-gray-600 hover:text-white transition-colors"
                          title={t('admin.common.cancel')}
                        >
                          <X className="w-3 h-3" />
                        </button>
                      </>
                    )}
                  </div>
                  {/* Stations using this type */}
                  {wt.stations.length > 0 ? (
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      {wt.stations.map(s => (
                        <span
                          key={s.key}
                          className="text-[10px] px-2 py-0.5 rounded text-gray-400"
                          style={{ backgroundColor: 'rgba(255,255,255,0.04)' }}
                          title={s.key}
                        >
                          {s.label}
                        </span>
                      ))}
                    </div>
                  ) : (
                    <div className="text-gray-600 text-[10px] mt-1.5">{t('admin.stations.noStationsUsingType')}</div>
                  )}
                  {/* Inline level editor for admin types */}
                  {editingTypeLevels === wt.name && (
                    <div className="mt-3 pt-3 space-y-3" style={{ borderTop: '1px solid rgba(255,255,255,0.06)' }}>
                      {/* Header row: title + max level control */}
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <SlidersHorizontal className="w-3 h-3 text-cyan-400/60" />
                          <span className="text-[10px] font-medium text-cyan-400/80 uppercase tracking-wider">{t('admin.types.levelConfiguration')}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-[10px] text-gray-500">{t('admin.types.maxLevel')}</span>
                          <NumberInput
                            value={typeLevelConfig.maxLevel}
                            onChange={val => {
                              setTypeLevelConfig(prev => {
                                const newMax = Math.max(2, Math.min(50, parseInt(val) || 2));
                                const levels = [...prev.levels];
                                while (levels.length < newMax) {
                                  const last = parseInt(levels[levels.length - 1]) || 0;
                                  levels.push(String(last + 100));
                                }
                                while (levels.length > newMax) levels.pop();
                                levels[0] = '0';
                                return { maxLevel: val, levels };
                              });
                            }}
                            min={2}
                            max={50}
                            className="w-[72px]"
                          />
                        </div>
                      </div>

                      {/* XP threshold table */}
                      <div className="rounded-lg border overflow-hidden" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
                        {/* Table header */}
                        <div className="flex items-center px-3 py-1.5" style={{ backgroundColor: 'rgba(255,255,255,0.02)' }}>
                          <span className="text-[9px] font-medium uppercase tracking-wider text-gray-600 w-14">{t('admin.common.level')}</span>
                          <span className="text-[9px] font-medium uppercase tracking-wider text-gray-600 flex-1">{t('admin.common.xpRequired')}</span>
                        </div>
                        {/* Table rows */}
                        <div className="max-h-[220px] overflow-y-auto">
                          {typeLevelConfig.levels.map((xp, idx) => (
                            <div
                              key={idx}
                              className="flex items-center px-3 py-1.5 border-t"
                              style={{ borderColor: 'rgba(255,255,255,0.04)', backgroundColor: idx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.01)' }}
                            >
                              <div className="w-14 flex items-center gap-1.5">
                                <div
                                  className="w-5 h-5 rounded flex items-center justify-center text-[9px] font-bold border"
                                  style={{
                                    backgroundColor: idx === 0 ? 'rgba(74,222,128,0.08)' : '#252528',
                                    borderColor: idx === 0 ? 'rgba(74,222,128,0.2)' : 'rgba(255,255,255,0.06)',
                                    color: idx === 0 ? '#4ADE80' : '#9CA3AF',
                                  }}
                                >
                                  {idx + 1}
                                </div>
                              </div>
                              <div className="flex-1">
                                {idx === 0 ? (
                                  <span className="text-[10px] text-gray-600 italic">{t('admin.common.baseLevel')}</span>
                                ) : (
                                  <NumberInput
                                    value={xp}
                                    onChange={val => {
                                      setTypeLevelConfig(prev => {
                                        const levels = [...prev.levels];
                                        levels[idx] = val;
                                        return { ...prev, levels };
                                      });
                                    }}
                                    min={0}
                                    className="w-[120px]"
                                    placeholder="0"
                                  />
                                )}
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Action buttons */}
                      <div className="flex items-center gap-2">
                        <button
                          onClick={async () => {
                            const maxLevel = Math.max(2, Math.min(50, parseInt(typeLevelConfig.maxLevel) || 2));
                            const serverLevels: Record<number, number> = {};
                            const clientLevels: Record<number, number> = {};
                            for (let i = 0; i < typeLevelConfig.levels.length; i++) {
                              const xp = i === 0 ? 0 : Math.max(0, parseInt(typeLevelConfig.levels[i]) || 0);
                              serverLevels[i + 1] = xp;
                              clientLevels[i] = xp;
                            }
                            const result = await fetchNui<{ success: boolean; error?: string }>('admin:updateTypeLevelConfig', {
                              typeName: wt.name, levels: serverLevels, maxLevel,
                            });
                            if (result?.success) {
                              setLevelConfigs(prev => ({ ...prev, [wt.name]: { levels: clientLevels, maxLevel } }));
                              setEditingTypeLevels(null);
                              showToast(t('admin.levelConfig.saved'), 'success');
                            } else {
                              showToast(result?.error || t('admin.levelConfig.saveFailed'), 'error');
                            }
                          }}
                          className="flex items-center gap-1.5 px-3.5 py-1.5 text-[10px] rounded-lg text-[#4ADE80] transition-colors hover:brightness-110"
                          style={{ backgroundColor: 'rgba(74,222,128,0.15)' }}
                        >
                          <Check className="w-3 h-3" /> {t('admin.types.saveLevels')}
                        </button>
                        <button
                          onClick={() => setEditingTypeLevels(null)}
                          className="flex items-center gap-1.5 px-3.5 py-1.5 text-[10px] rounded-lg text-gray-400 transition-colors hover:text-white"
                          style={{ backgroundColor: 'rgba(255,255,255,0.05)' }}
                        >
                          {t('admin.common.cancel')}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </FormSection>

          <div className="text-gray-600 text-[10px] italic">{t('admin.types.configTypesNote')}</div>
        </FormModal>
      )}

      {/* Station Inventory Modal */}
      {inventoryModalStation && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center"
          style={{ backgroundColor: 'rgba(0,0,0,0.6)' }}
          onMouseDown={e => { if (e.target === e.currentTarget) setInventoryModalStation(null); }}
        >
          <div
            className="relative rounded-xl w-full mx-4 border overflow-hidden flex flex-col"
            style={{ backgroundColor: '#0c0c0e', borderColor: 'rgba(255,255,255,0.08)', maxWidth: '720px', height: '70vh' }}
          >
            <NoiseOverlay />
            {/* Fixed header */}
            <div className="relative z-10 flex items-center justify-between px-5 py-4 border-b flex-shrink-0" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
              <div className="text-xs font-medium text-[#4ADE80]">{t('admin.stations.stationInventory')}: {inventoryModalStation.label || inventoryModalStation.stationKey}</div>
              <button onClick={() => setInventoryModalStation(null)} className="text-gray-600 hover:text-white transition-colors p-0.5 rounded hover:bg-white/10">
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
            {/* Scrollable body */}
            <div className="relative z-10 flex-1 overflow-y-auto p-5">
              {loadingInventoryModal ? (
                <div className="flex items-center justify-center h-full gap-2">
                  <RefreshCw className="w-4 h-4 text-gray-500 animate-spin" />
                  <span className="text-gray-500 text-xs">{t('admin.stations.loadingInventories')}</span>
                </div>
              ) : (() => {
                const inventories = stationInventoryMap[String(inventoryModalStation.id)] || [];
                if (inventories.length === 0) {
                  return (
                    <div className="flex flex-col items-center justify-center h-full gap-3">
                      <Package className="w-6 h-6 text-gray-700" />
                      <span className="text-gray-500 text-xs">{t('admin.stations.noStagedItems')}</span>
                      {addItemTarget === '_new' ? (
                        <div className="flex items-end gap-2 p-2.5 rounded-lg border w-full max-w-sm" style={{ backgroundColor: 'rgba(74,222,128,0.04)', borderColor: 'rgba(74,222,128,0.15)' }}>
                          <div className="flex-1">
                            <label className="text-gray-400 text-[10px] font-medium mb-1 block">{t('admin.stations.itemName')}</label>
                            <input
                              type="text"
                              value={addItemName}
                              onChange={e => setAddItemName(e.target.value)}
                              placeholder={t('admin.common.itemPlaceholder')}
                              className="w-full px-2.5 py-1.5 rounded-md text-xs text-white placeholder-gray-600 outline-none border transition-colors focus:border-[#4ADE80]/40"
                              style={{ backgroundColor: 'rgba(0,0,0,0.3)', borderColor: 'rgba(255,255,255,0.08)' }}
                              onKeyDown={e => {
                                if (e.key === 'Enter' && addItemName.trim() && !addItemLoading) {
                                  addStationItem(inventoryModalStation!, 'shared', addItemName, addItemCount);
                                } else if (e.key === 'Escape') {
                                  setAddItemTarget(null);
                                }
                              }}
                              autoFocus
                            />
                          </div>
                          <div className="w-16">
                            <label className="text-gray-400 text-[10px] font-medium mb-1 block">{t('admin.confirm.quantity')}</label>
                            <input
                              type="number"
                              value={addItemCount}
                              onChange={e => setAddItemCount(Math.max(1, parseInt(e.target.value) || 1))}
                              min={1}
                              className="w-full px-2 py-1.5 rounded-md text-xs text-white text-center outline-none border transition-colors focus:border-[#4ADE80]/40"
                              style={{ backgroundColor: 'rgba(0,0,0,0.3)', borderColor: 'rgba(255,255,255,0.08)' }}
                              onKeyDown={e => {
                                if (e.key === 'Enter' && addItemName.trim() && !addItemLoading) {
                                  addStationItem(inventoryModalStation!, 'shared', addItemName, addItemCount);
                                }
                              }}
                            />
                          </div>
                          <button
                            onClick={() => addStationItem(inventoryModalStation!, 'shared', addItemName, addItemCount)}
                            disabled={!addItemName.trim() || addItemLoading}
                            className="px-3 py-1.5 rounded-md text-[10px] font-medium text-white transition-colors disabled:opacity-40"
                            style={{ backgroundColor: 'rgba(74,222,128,0.5)' }}
                          >
                            {addItemLoading ? t('admin.common.adding') : t('admin.common.add')}
                          </button>
                          <button
                            onClick={() => setAddItemTarget(null)}
                            className="p-1.5 rounded-md text-gray-500 hover:text-white transition-colors hover:bg-white/10"
                          >
                            <X className="w-3 h-3" />
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => { setAddItemTarget('_new'); setAddItemName(''); setAddItemCount(1); }}
                          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs text-gray-400 hover:text-[#4ADE80] border transition-colors hover:border-[#4ADE80]/30"
                          style={{ borderColor: 'rgba(255,255,255,0.08)' }}
                        >
                          <Plus className="w-3 h-3" />
                          {t('admin.common.addItem')}
                        </button>
                      )}
                    </div>
                  );
                }
                return (
                  <div className="space-y-2">
                    {inventories.map((inv) => {
                      const invKey = `${inventoryModalStation.stationKey}::${inv.stagingKey}`;
                      const isInvExpanded = expandedInventories.has(invKey);
                      return (
                        <div key={inv.stagingKey} className="rounded-lg border overflow-hidden" style={{ backgroundColor: 'rgba(18,18,22,0.6)', borderColor: 'rgba(255,255,255,0.06)' }}>
                          <div className="flex items-center">
                            <button
                              onClick={() => setExpandedInventories(prev => {
                                const next = new Set(prev);
                                if (next.has(invKey)) next.delete(invKey); else next.add(invKey);
                                return next;
                              })}
                              className="flex-1 flex items-center gap-2.5 px-4 py-2.5 text-left transition-colors hover:bg-white/[0.03]"
                            >
                              <ChevronDown className={`w-3 h-3 transition-transform ${isInvExpanded ? 'rotate-180 text-gray-400' : 'text-gray-600'}`} />
                              <div className="flex items-center gap-2 flex-1 min-w-0">
                                {inv.isShared ? (
                                  <Layers className="w-3.5 h-3.5 text-gray-500 flex-shrink-0" />
                                ) : (
                                  <Package className="w-3.5 h-3.5 text-gray-500 flex-shrink-0" />
                                )}
                                <span className="text-xs font-medium text-gray-300">
                                  {inv.isShared ? t('admin.common.sharedInventory') : inv.stagingKey}
                                </span>
                              </div>
                              <span className="text-[10px] px-2 py-0.5 rounded-full font-medium" style={{ backgroundColor: 'rgba(255,255,255,0.05)', color: 'rgba(255,255,255,0.35)' }}>
                                {t('admin.common.itemCount', { count: inv.itemCount })}
                              </span>
                            </button>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                if (!expandedInventories.has(invKey)) {
                                  setExpandedInventories(prev => new Set(prev).add(invKey));
                                }
                                setAddItemTarget(addItemTarget === inv.stagingKey ? null : inv.stagingKey);
                                setAddItemName('');
                                setAddItemCount(1);
                              }}
                              className="px-3 py-2.5 text-gray-600 hover:text-[#4ADE80] transition-colors hover:bg-white/[0.03]"
                              title={t('admin.stations.addItemToInventory')}
                            >
                              <Plus className="w-3.5 h-3.5" />
                            </button>
                          </div>
                          {isInvExpanded && (
                            <div className="px-4 pb-3 pt-1 border-t" style={{ borderColor: 'rgba(255,255,255,0.04)' }}>
                              {addItemTarget === inv.stagingKey && (
                                <div className="flex items-end gap-2 mb-3 p-2.5 rounded-lg border" style={{ backgroundColor: 'rgba(74,222,128,0.04)', borderColor: 'rgba(74,222,128,0.15)' }}>
                                  <div className="flex-1">
                                    <label className="text-gray-400 text-[10px] font-medium mb-1 block">{t('admin.stations.itemName')}</label>
                                    <input
                                      type="text"
                                      value={addItemName}
                                      onChange={e => setAddItemName(e.target.value)}
                                      placeholder={t('admin.common.itemPlaceholder')}
                                      className="w-full px-2.5 py-1.5 rounded-md text-xs text-white placeholder-gray-600 outline-none border transition-colors focus:border-[#4ADE80]/40"
                                      style={{ backgroundColor: 'rgba(0,0,0,0.3)', borderColor: 'rgba(255,255,255,0.08)' }}
                                      onKeyDown={e => {
                                        if (e.key === 'Enter' && addItemName.trim() && !addItemLoading) {
                                          addStationItem(inventoryModalStation!, inv.stagingKey, addItemName, addItemCount);
                                        } else if (e.key === 'Escape') {
                                          setAddItemTarget(null);
                                        }
                                      }}
                                      autoFocus
                                    />
                                  </div>
                                  <div className="w-16">
                                    <label className="text-gray-400 text-[10px] font-medium mb-1 block">{t('admin.confirm.quantity')}</label>
                                    <input
                                      type="number"
                                      value={addItemCount}
                                      onChange={e => setAddItemCount(Math.max(1, parseInt(e.target.value) || 1))}
                                      min={1}
                                      className="w-full px-2 py-1.5 rounded-md text-xs text-white text-center outline-none border transition-colors focus:border-[#4ADE80]/40"
                                      style={{ backgroundColor: 'rgba(0,0,0,0.3)', borderColor: 'rgba(255,255,255,0.08)' }}
                                      onKeyDown={e => {
                                        if (e.key === 'Enter' && addItemName.trim() && !addItemLoading) {
                                          addStationItem(inventoryModalStation!, inv.stagingKey, addItemName, addItemCount);
                                        }
                                      }}
                                    />
                                  </div>
                                  <button
                                    onClick={() => addStationItem(inventoryModalStation!, inv.stagingKey, addItemName, addItemCount)}
                                    disabled={!addItemName.trim() || addItemLoading}
                                    className="px-3 py-1.5 rounded-md text-[10px] font-medium text-white transition-colors disabled:opacity-40"
                                    style={{ backgroundColor: 'rgba(74,222,128,0.5)' }}
                                  >
                                    {addItemLoading ? t('admin.common.adding') : t('admin.common.add')}
                                  </button>
                                  <button
                                    onClick={() => setAddItemTarget(null)}
                                    className="p-1.5 rounded-md text-gray-500 hover:text-white transition-colors hover:bg-white/10"
                                  >
                                    <X className="w-3 h-3" />
                                  </button>
                                </div>
                              )}
                              <div className="grid gap-1.5" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(64px, 1fr))' }}>
                                {inv.items.map((item, idx) => {
                                  const durability = item.durability;
                                  const hasDurability = durability != null && durability < 100;
                                  const durabilityColor = durability != null
                                    ? durability > 70 ? '#4ADE80' : durability > 30 ? '#FACC15' : '#EF4444'
                                    : '#4ADE80';
                                  return (
                                    <div
                                      key={`${item.item}-${item.slot}-${idx}`}
                                      className="group relative rounded-lg border overflow-hidden transition-all hover:border-white/10"
                                      style={{ backgroundColor: '#1a1a1f', borderColor: 'rgba(255,255,255,0.04)', aspectRatio: '1' }}
                                    >
                                      <div className="absolute inset-0 flex items-center justify-center p-2">
                                        <ItemImage src={getItemImage(item.item)} alt={item.label || item.item} className="w-full h-full object-contain" />
                                      </div>
                                      <div className="absolute top-1 right-1 flex items-center justify-center px-1 rounded font-bold text-white z-10" style={{ backgroundColor: 'rgba(0,0,0,0.65)', fontSize: '10px', minWidth: '18px', height: '16px', lineHeight: '16px', backdropFilter: 'blur(4px)' }}>
                                        {item.count}
                                      </div>
                                      <div className="absolute top-1 left-1 flex items-center justify-center px-1 rounded z-10" style={{ backgroundColor: 'rgba(0,0,0,0.4)', fontSize: '8px', color: 'rgba(255,255,255,0.25)', height: '14px', lineHeight: '14px' }}>
                                        {item.slot}
                                      </div>
                                      <div className="absolute bottom-0 left-0 right-0 z-10 px-1 py-0.5 text-center truncate" style={{ fontSize: '8px', color: 'rgba(255,255,255,0.6)', background: 'linear-gradient(transparent, rgba(0,0,0,0.7))' }}>
                                        {item.label || item.item}
                                      </div>
                                      {hasDurability && (
                                        <div className="absolute bottom-[14px] left-1 right-1 z-10" style={{ height: '2px', backgroundColor: 'rgba(0,0,0,0.4)', borderRadius: '1px' }}>
                                          <div style={{ width: `${durability}%`, height: '100%', backgroundColor: durabilityColor, borderRadius: '1px', transition: 'width 0.3s' }} />
                                        </div>
                                      )}
                                      <button
                                        onClick={(e) => {
                                          e.stopPropagation();
                                          setConfirm({
                                            message: t('admin.stations.removeItemConfirm', { item: item.label || item.item }),
                                            slider: item.count > 1 ? { min: 1, max: item.count, label: t('admin.confirm.quantity') } : undefined,
                                            onConfirm: (count) => removeStationItem(inventoryModalStation, inv.stagingKey, item, count),
                                          });
                                        }}
                                        className="absolute top-0 right-0 z-20 p-1 opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                                        title={t('admin.common.removeItem', { item: item.label || item.item })}
                                      >
                                        <div className="w-4 h-4 rounded-bl-md flex items-center justify-center" style={{ backgroundColor: 'rgba(239,68,68,0.85)' }}>
                                          <X className="w-2.5 h-2.5 text-white" />
                                        </div>
                                      </button>
                                    </div>
                                  );
                                })}
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                );
              })()}
            </div>
          </div>
        </div>
      )}

      <div
        className="relative rounded-2xl overflow-hidden border"
        style={{
          backgroundColor: '#0c0c0e',
          borderColor: 'rgba(255,255,255,0.15)',
          width: '1100px',
          maxWidth: '92vw',
          height: '88vh',
          boxShadow: '0 25px 60px rgba(0,0,0,0.6), 0 0 1px rgba(255,255,255,0.1)',
        }}
      >
        <NoiseOverlay />

        {/* Header */}
        <div className="relative z-10 flex items-center justify-between px-6 py-4 border-b" style={{ borderColor: 'rgba(255,255,255,0.08)' }}>
          <div className="flex items-center gap-3">
            <div className="w-1.5 h-5 rounded-full" style={{ backgroundColor: '#4ADE80' }} />
            <h1 className="text-white text-sm font-semibold tracking-wide">{t('admin.common.craftingAdmin')}</h1>
          </div>
          <button onClick={handleClose} className="text-gray-500 hover:text-white transition-colors p-1.5 rounded-lg hover:bg-white/10">
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Tabs */}
        <div className="relative z-10 flex items-center gap-1 px-6 py-2 border-b" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
          {tabs.map(tab => (
            <button
              key={tab.id}
              onClick={() => { setActiveTab(tab.id); localStorage.setItem(ADMIN_TAB_KEY, tab.id); setSearchQuery(''); }}
              className={`relative flex items-center gap-2 px-4 py-2 text-xs font-medium rounded-lg transition-all ${
                activeTab === tab.id
                  ? 'text-[#4ADE80]'
                  : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
              }`}
              style={activeTab === tab.id ? { backgroundColor: 'rgba(74,222,128,0.1)' } : {}}
            >
              {tab.icon}
              {tab.label}
              {getTabCount(tab.id) != null && (
                <span className="text-gray-600 text-[10px]">{getTabCount(tab.id)}</span>
              )}
              {activeTab === tab.id && (
                <div className="absolute bottom-0 left-3 right-3 h-[2px] rounded-full" style={{ backgroundColor: 'rgba(74,222,128,0.5)' }} />
              )}
            </button>
          ))}

          <div className="flex-1" />

          {/* Refresh button */}
          <button
            onClick={() => activeTab === 'players' ? loadPlayersPage(playersPage, playersSearch) : loadTabData(activeTab)}
            className="text-gray-500 hover:text-white transition-colors p-1.5 rounded-lg hover:bg-white/10"
            title={t('admin.common.refresh')}
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>

        {/* Search bar */}
        <div className="relative z-10 px-6 py-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-600" />
            <input
              ref={searchRef}
              type="text"
              placeholder={t('admin.common.searchPlaceholder', { tab: activeTab })}
              value={activeTab === 'players' ? playersSearch : searchQuery}
              onChange={e => {
                if (activeTab === 'players') {
                  const val = e.target.value;
                  setPlayersSearch(val);
                  if (playersSearchTimer.current) clearTimeout(playersSearchTimer.current);
                  playersSearchTimer.current = setTimeout(() => {
                    loadPlayersPage(1, val);
                  }, 300);
                } else {
                  setSearchQuery(e.target.value);
                }
              }}
              className="w-full rounded-lg pl-9 pr-4 py-2 text-white text-xs placeholder-gray-600 focus:outline-none border border-transparent focus:border-white/10"
              style={{ backgroundColor: '#0c0c0e' }}
            />
            {(activeTab === 'players' ? playersSearch : searchQuery) && (
              <button onClick={() => {
                if (activeTab === 'players') {
                  setPlayersSearch('');
                  if (playersSearchTimer.current) clearTimeout(playersSearchTimer.current);
                  loadPlayersPage(1, '');
                } else {
                  setSearchQuery('');
                }
              }} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-600 hover:text-gray-400">
                <X className="w-3 h-3" />
              </button>
            )}
          </div>
        </div>

        {/* Content area */}
        <div className="relative z-10 px-6 pb-4 overflow-y-auto overflow-x-hidden" style={{ height: 'calc(100% - 165px)' }}>
          {loading ? (
            <div className="flex flex-col items-center justify-center h-40 gap-3">
              <RefreshCw className="w-5 h-5 text-gray-500 animate-spin" />
              <span className="text-gray-600 text-[11px]">{t('admin.common.loading')}</span>
            </div>
          ) : (
            <>
              {/* Players Tab */}
              {activeTab === 'players' && !selectedPlayer && (
                <div className="space-y-1">
                  {players.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-16 gap-2">
                      <Users className="w-8 h-8 text-gray-700" />
                      <span className="text-gray-500 text-xs">{t('admin.players.noPlayersFound')}</span>
                    </div>
                  ) : (
                    players.map(player => (
                      <button
                        key={player.identifier}
                        onClick={() => loadPlayerDetail(player.identifier)}
                        className="w-full flex items-center gap-4 px-4 py-3 rounded-lg text-left transition-colors hover:bg-white/5 group"
                      >
                        {/* Avatar circle with online indicator */}
                        <div className="relative flex-shrink-0">
                          <div className="w-8 h-8 rounded-full flex items-center justify-center text-[11px] font-bold text-gray-400 border" style={{ backgroundColor: '#252528', borderColor: 'rgba(255,255,255,0.06)' }}>
                            {(player.charName || player.playerName || player.identifier).slice(0, 2).toUpperCase()}
                          </div>
                          <div
                            className="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2"
                            style={{
                              backgroundColor: player.online ? '#4ADE80' : '#6B7280',
                              borderColor: '#0C0C0E',
                            }}
                            title={player.online ? t('admin.common.onlineWithId', { id: player.serverId }) : t('admin.common.offline')}
                          />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <span className="text-white text-xs font-medium truncate">
                              {player.charName || player.playerName || player.identifier}
                            </span>
                            {player.online && player.serverId && (
                              <span className="text-[10px] px-1.5 py-0.5 rounded text-[#4ADE80] flex-shrink-0" style={{ backgroundColor: 'rgba(74,222,128,0.1)' }}>
                                {t('admin.common.id')} {player.serverId}
                              </span>
                            )}
                            {player.hasQueue && (
                              <span className="text-[10px] px-1.5 py-0.5 rounded text-yellow-400 flex-shrink-0" style={{ backgroundColor: 'rgba(250,204,21,0.1)' }}>
                                {t('admin.players.crafting')}
                              </span>
                            )}
                          </div>
                          <div className="text-gray-500 text-[10px] mt-0.5 truncate">
                            {player.charName && player.playerName && (
                              <span>{player.playerName} &middot; </span>
                            )}
                            <span className="text-gray-600">{player.identifier}</span>
                          </div>
                          <div className="text-gray-600 text-[10px] mt-0.5">
                            {Object.keys(player.workbench_levels || {}).length > 0
                              ? Object.entries(player.workbench_levels).map(([wb, d]) => t('admin.players.levelSummary', { wb: capitalize(wb), level: d.level })).join(', ')
                              : t('admin.players.levelFallback', { level: player.level })
                            }
                            {player.lastSeen && !player.online && (
                              <span> &middot; {t('admin.players.lastSeenDate', { date: new Date(player.lastSeen).toLocaleDateString() })}</span>
                            )}
                          </div>
                        </div>
                        <ChevronRight className="w-3.5 h-3.5 text-gray-700 group-hover:text-gray-400 flex-shrink-0 transition-colors" />
                      </button>
                    ))
                  )}
                  {/* Pagination controls */}
                  {playersTotalPages > 0 && (
                    <div className="flex items-center justify-center gap-3 pt-3 pb-1">
                      <button
                        onClick={() => loadPlayersPage(playersPage - 1, playersSearch)}
                        disabled={playersPage <= 1 || loading}
                        className="p-1.5 rounded-lg transition-colors disabled:opacity-30 disabled:cursor-not-allowed text-gray-400 hover:text-white hover:bg-white/10"
                      >
                        <ChevronLeft className="w-3.5 h-3.5" />
                      </button>
                      <span className="text-gray-500 text-[11px]">
                        {t('admin.players.pageInfo', { page: playersPage, totalPages: playersTotalPages, total: playersTotal, playerWord: playersTotal === 1 ? t('admin.players.player') : t('admin.players.players') })}
                      </span>
                      <button
                        onClick={() => loadPlayersPage(playersPage + 1, playersSearch)}
                        disabled={playersPage >= playersTotalPages || loading}
                        className="p-1.5 rounded-lg transition-colors disabled:opacity-30 disabled:cursor-not-allowed text-gray-400 hover:text-white hover:bg-white/10"
                      >
                        <ChevronRight className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* Player Detail View */}
              {activeTab === 'players' && selectedPlayer && (
                <div className="space-y-3 animate-fadeIn">
                  {/* Profile Header */}
                  <div className="rounded-xl border overflow-hidden" style={{ backgroundColor: 'rgba(26,26,31,0.6)', borderColor: 'rgba(255,255,255,0.06)' }}>
                    <div className="p-4">
                      <div className="flex items-start gap-3">
                        <button onClick={() => { setSelectedPlayer(null); setEditingPlayer(null); }} className="text-gray-500 hover:text-white transition-colors p-1 rounded-lg hover:bg-white/10 mt-0.5 flex-shrink-0">
                          <ChevronRight className="w-4 h-4 rotate-180" />
                        </button>
                        <div className="relative flex-shrink-0">
                          <div
                            className="w-11 h-11 rounded-xl flex items-center justify-center text-sm font-bold border"
                            style={{
                              backgroundColor: '#252528',
                              borderColor: selectedPlayer.online ? 'rgba(74,222,128,0.3)' : 'rgba(255,255,255,0.06)',
                              color: selectedPlayer.online ? '#4ADE80' : '#6B7280',
                            }}
                          >
                            {(selectedPlayer.charName || selectedPlayer.playerName || selectedPlayer.identifier).slice(0, 2).toUpperCase()}
                          </div>
                          <div
                            className="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2"
                            style={{ backgroundColor: selectedPlayer.online ? '#4ADE80' : '#6B7280', borderColor: '#1A1A1F' }}
                          />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <h2 className="text-white text-sm font-semibold truncate">{selectedPlayer.charName || selectedPlayer.playerName || selectedPlayer.identifier}</h2>
                            {selectedPlayer.online ? (
                              <span className="flex items-center gap-1 text-[10px] px-1.5 py-0.5 rounded-md text-[#4ADE80] flex-shrink-0" style={{ backgroundColor: 'rgba(74,222,128,0.1)' }}>
                                <Wifi className="w-2.5 h-2.5" />
                                {t('admin.common.id')} {selectedPlayer.serverId}
                              </span>
                            ) : (
                              <span className="flex items-center gap-1 text-[10px] px-1.5 py-0.5 rounded-md text-gray-500 flex-shrink-0" style={{ backgroundColor: 'rgba(107,114,128,0.1)' }}>
                                <WifiOff className="w-2.5 h-2.5" />
                                {t('admin.common.offline')}
                              </span>
                            )}
                          </div>
                          <div className="text-gray-500 text-[10px] mt-1 truncate">
                            {selectedPlayer.charName && selectedPlayer.playerName && <span>{selectedPlayer.playerName} &middot; </span>}
                            <span className="text-gray-600">{selectedPlayer.identifier}</span>
                          </div>
                          {selectedPlayer.ownedStations != null && selectedPlayer.ownedStations > 0 && (
                            <div className="flex items-center gap-1 text-gray-600 text-[10px] mt-0.5">
                              <MapPin className="w-2.5 h-2.5" />
                              {t('admin.players.stationsOwned', { count: selectedPlayer.ownedStations })}
                            </div>
                          )}
                        </div>
                        <div className="flex items-center gap-1.5 flex-shrink-0">
                          <button
                            onClick={() => setConfirm({
                              message: t('admin.players.resetPlayerConfirm'),
                              onConfirm: () => resetPlayer(selectedPlayer.identifier),
                            })}
                            className="flex items-center gap-1.5 px-2.5 py-1.5 text-[10px] rounded-lg text-red-400 hover:text-red-300 transition-colors"
                            style={{ backgroundColor: 'rgba(239,68,68,0.1)' }}
                          >
                            <RotateCcw className="w-3 h-3" />
                            {t('admin.common.reset')}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Progression (Tech Points + Workbench Levels) */}
                  <div className="rounded-xl border overflow-hidden" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
                    <div className="flex items-center justify-between px-4 py-2.5" style={{ backgroundColor: 'rgba(26,26,31,0.6)' }}>
                      <div className="flex items-center gap-2">
                        <Layers className="w-3 h-3 text-gray-500" />
                        <span className="text-gray-400 text-xs font-medium">{t('admin.players.progression')}</span>
                      </div>
                      {!editingPlayer ? (
                        <button onClick={() => {
                          const allTypes = new Set([
                            ...Object.keys(selectedPlayer.workbench_levels),
                            ...workbenchTypes.map(t => t.name),
                          ]);
                          setEditingPlayer({
                            workbench_levels: Object.fromEntries(
                              Array.from(allTypes).sort().map(wb => {
                                const existing = selectedPlayer.workbench_levels[wb];
                                return [wb, { xp: String(existing?.xp ?? 0), level: String(existing?.level ?? 1) }];
                              })
                            ),
                          });
                        }} className="flex items-center gap-1.5 text-gray-500 hover:text-white transition-colors text-[10px] px-2 py-1 rounded-md hover:bg-white/10">
                          <Edit3 className="w-3 h-3" />
                          {t('admin.common.edit')}
                        </button>
                      ) : (
                        <div className="flex gap-1">
                          <button onClick={() => setEditingPlayer(null)} className="flex items-center gap-1 text-gray-500 hover:text-white transition-colors text-[10px] px-2 py-1 rounded-md hover:bg-white/10">
                            <X className="w-3 h-3" />
                            {t('admin.common.cancel')}
                          </button>
                          <button onClick={savePlayerEdits} className="flex items-center gap-1 text-[#4ADE80] hover:text-green-300 transition-colors text-[10px] px-2 py-1 rounded-md hover:bg-white/10">
                            <Check className="w-3 h-3" />
                            {t('admin.common.save')}
                          </button>
                        </div>
                      )}
                    </div>

                    {/* Workbench level grid (Level + XP only — TP is managed in station section) */}
                    {(() => {
                      const allTypeNames = Array.from(new Set([
                        ...Object.keys(selectedPlayer.workbench_levels),
                        ...workbenchTypes.map(t => t.name),
                      ])).sort();
                      return allTypeNames.length > 0 ? (
                        <div className="grid grid-cols-2" style={{ backgroundColor: 'rgba(26,26,31,0.3)' }}>
                          {allTypeNames.map((wb, idx) => {
                            const data = selectedPlayer.workbench_levels[wb];
                            const hasData = !!data;
                            const wbMaxLevel = levelConfigs[wb]?.maxLevel ?? 10;
                            return (
                              <div
                                key={wb}
                                className={`p-3 ${idx % 2 === 0 ? 'border-r' : ''} ${idx < allTypeNames.length - (allTypeNames.length % 2 === 0 ? 2 : 1) ? 'border-b' : ''}`}
                                style={{ borderColor: 'rgba(255,255,255,0.04)' }}
                              >
                                <div className="flex items-center gap-2 mb-2">
                                  <div
                                    className="w-6 h-6 rounded-md flex items-center justify-center text-[9px] font-bold border"
                                    style={{ backgroundColor: '#252528', borderColor: hasData ? 'rgba(74,222,128,0.15)' : 'rgba(255,255,255,0.06)', color: hasData ? '#4ADE80' : '#6B7280' }}
                                  >
                                    {wb.slice(0, 2).toUpperCase()}
                                  </div>
                                  <span className={`text-[11px] font-medium ${hasData ? 'text-gray-300' : 'text-gray-600'}`}>{capitalize(wb)}</span>
                                  <span className="text-[8px] text-gray-600 ml-auto">{t('admin.players.maxLevel', { level: wbMaxLevel })}</span>
                                  {!hasData && (
                                    <span className="text-[8px] text-gray-700 italic">{t('admin.common.new')}</span>
                                  )}
                                </div>
                                {editingPlayer && editingPlayer.workbench_levels[wb] ? (
                                  <div className="space-y-1.5">
                                    <div className="grid grid-cols-2 gap-1.5">
                                      <NumberInput label={t('admin.common.level')} value={editingPlayer.workbench_levels[wb].level} onChange={v => handleLevelChange(wb, v)} min={1} max={wbMaxLevel} step={1} />
                                      <NumberInput label={t('admin.common.xp')} value={editingPlayer.workbench_levels[wb].xp} onChange={v => handleXPChange(wb, v)} min={0} step={1} />
                                    </div>
                                  </div>
                                ) : (
                                  <div className="flex items-baseline gap-2">
                                    <span className={`text-sm font-bold ${hasData ? 'text-white' : 'text-gray-700'}`}>{t('admin.players.lvShort', { level: data?.level ?? 1 })}</span>
                                    <span className="text-gray-500 text-[10px]">{t('admin.players.xpShort', { xp: (data?.xp ?? 0).toLocaleString() })}</span>
                                  </div>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      ) : (
                        <div className="px-4 py-4 text-center" style={{ backgroundColor: 'rgba(26,26,31,0.3)' }}>
                          <span className="text-gray-600 text-[11px]">{t('admin.players.noWorkbenchTypes')}</span>
                        </div>
                      );
                    })()}
                  </div>

                  {/* Personal Unlocked Nodes */}
                  <div className="rounded-xl border overflow-hidden" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
                    <div className="flex items-center justify-between px-4 py-2.5" style={{ backgroundColor: 'rgba(26,26,31,0.6)' }}>
                      <div className="flex items-center gap-2">
                        <BookOpen className="w-3 h-3 text-gray-500" />
                        <span className="text-gray-400 text-xs font-medium">{t('admin.players.personalUnlockedNodes')}</span>
                        <span className="text-[10px] px-1.5 py-0.5 rounded-md text-gray-500" style={{ backgroundColor: 'rgba(255,255,255,0.05)' }}>
                          {Object.keys(selectedPlayer.unlocked_nodes).length}
                        </span>
                      </div>
                      {Object.keys(selectedPlayer.unlocked_nodes).length > 0 && (
                        <button
                          onClick={() => setConfirm({
                            message: t('admin.players.resetPersonalNodes'),
                            onConfirm: () => resetPersonalTechNodes(selectedPlayer.identifier),
                          })}
                          className="flex items-center gap-1 text-red-400/60 hover:text-red-400 transition-colors text-[10px] px-2 py-0.5 rounded hover:bg-white/10"
                        >
                          <RotateCcw className="w-2.5 h-2.5" />
                          {t('admin.common.reset')}
                        </button>
                      )}
                    </div>
                    <div className="px-4 py-1.5" style={{ backgroundColor: 'rgba(26,26,31,0.4)', borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                      <span className="text-gray-600 text-[9px] italic">{t('admin.players.personalNodesDescription')}</span>
                    </div>
                    <div className="p-3" style={{ backgroundColor: 'rgba(26,26,31,0.3)' }}>
                      {Object.keys(selectedPlayer.unlocked_nodes).length === 0 ? (
                        <div className="text-gray-600 text-[11px] text-center py-3">{t('admin.players.noNodesUnlocked')}</div>
                      ) : (
                        <div className="flex flex-wrap gap-1.5">
                          {Object.keys(selectedPlayer.unlocked_nodes).map(nodeId => (
                            <button
                              key={nodeId}
                              onClick={() => toggleNode(selectedPlayer.identifier, nodeId)}
                              className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-[10px] text-[#4ADE80] transition-all hover:brightness-125 active:scale-95"
                              style={{ backgroundColor: 'rgba(74,222,128,0.1)' }}
                              title={t('admin.players.clickToLock')}
                            >
                              <Check className="w-2.5 h-2.5" />
                              {nodeId}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Workbench Tech Trees — per-type unlocked nodes with per-type reset */}
                  {selectedPlayer.workbench_tech && Object.entries(selectedPlayer.workbench_tech).some(([, d]) => {
                    const nodes = d.unlocked_nodes;
                    return Array.isArray(nodes) ? nodes.length > 0 : nodes && Object.keys(nodes).length > 0;
                  }) && (
                    <div className="rounded-xl border overflow-hidden" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
                      <div className="flex items-center gap-2 px-4 py-2.5" style={{ backgroundColor: 'rgba(26,26,31,0.6)' }}>
                        <Layers className="w-3 h-3 text-gray-500" />
                        <span className="text-gray-400 text-xs font-medium">{t('admin.players.workbenchTechNodes')}</span>
                      </div>
                      <div className="p-3 space-y-3" style={{ backgroundColor: 'rgba(26,26,31,0.3)' }}>
                        {Object.entries(selectedPlayer.workbench_tech)
                          .filter(([, d]) => {
                            const nodes = d.unlocked_nodes;
                            return Array.isArray(nodes) ? nodes.length > 0 : nodes && Object.keys(nodes).length > 0;
                          })
                          .map(([wbType, d]) => {
                            const nodeIds = Array.isArray(d.unlocked_nodes) ? d.unlocked_nodes : Object.keys(d.unlocked_nodes);
                            return (
                              <div key={wbType}>
                                <div className="flex items-center justify-between mb-1.5">
                                  <span className="text-gray-500 text-[10px] font-medium">{capitalize(wbType)}</span>
                                  <button
                                    onClick={() => setConfirm({
                                      message: t('admin.players.resetWorkbenchTypeNodes', { type: capitalize(wbType) }),
                                      onConfirm: () => resetPersonalTypeTechNodes(selectedPlayer.identifier, wbType),
                                    })}
                                    className="flex items-center gap-1 text-red-400/60 hover:text-red-400 transition-colors text-[9px] px-1.5 py-0.5 rounded hover:bg-white/10"
                                  >
                                    <RotateCcw className="w-2.5 h-2.5" />
                                    {t('admin.common.reset')}
                                  </button>
                                </div>
                                <div className="flex flex-wrap gap-1.5">
                                  {nodeIds.map(nodeId => (
                                    <span key={nodeId} className="text-[10px] px-2 py-0.5 rounded-lg text-purple-400" style={{ backgroundColor: 'rgba(168,85,247,0.1)' }}>
                                      {nodeId}
                                    </span>
                                  ))}
                                </div>
                              </div>
                            );
                          })}
                      </div>
                    </div>
                  )}

                  {/* Shared Workbench Tech Nodes — always shown */}
                  <div className="rounded-xl border overflow-hidden" style={{ borderColor: 'rgba(251,191,36,0.12)' }}>
                    <div className="flex items-center gap-2 px-4 py-2.5" style={{ backgroundColor: 'rgba(26,26,31,0.6)' }}>
                      <GitBranch className="w-3 h-3 text-amber-500" />
                      <span className="text-amber-400 text-xs font-medium">{t('admin.players.sharedWorkbenchTechNodes')}</span>
                    </div>
                    <div className="px-4 py-1.5" style={{ backgroundColor: 'rgba(26,26,31,0.4)', borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                      <span className="text-gray-600 text-[9px] italic">{t('admin.players.sharedNodesDescription')}</span>
                    </div>
                    <div className="p-3 space-y-3" style={{ backgroundColor: 'rgba(26,26,31,0.3)' }}>
                      {(() => {
                        const stationsWithNodes = (selectedPlayer.accessible_station_tech || []).filter(s => {
                          const nodes = s.unlocked_nodes;
                          return Array.isArray(nodes) ? nodes.length > 0 : nodes && Object.keys(nodes).length > 0;
                        });
                        if (stationsWithNodes.length === 0) {
                          return <div className="text-gray-600 text-[11px] text-center py-3">{t('admin.players.noSharedTechData')}</div>;
                        }
                        return stationsWithNodes.map(station => {
                          const nodeIds = Array.isArray(station.unlocked_nodes) ? station.unlocked_nodes : Object.keys(station.unlocked_nodes);
                          return (
                            <div key={station.workbenchId}>
                              <div className="flex items-center justify-between mb-1.5">
                                <div className="flex items-center gap-2">
                                  <span className="text-amber-400 text-[10px] font-medium">{station.label}</span>
                                  <span className="text-gray-600 text-[9px] font-mono">{station.stationKey}</span>
                                  {station.isOwner ? (
                                    <span className="text-[8px] px-1 py-0.5 rounded text-amber-400" style={{ backgroundColor: 'rgba(251,191,36,0.1)' }}>{t('admin.common.owner')}</span>
                                  ) : (
                                    <span className="text-[8px] px-1 py-0.5 rounded text-blue-400" style={{ backgroundColor: 'rgba(96,165,250,0.1)' }}>{t('admin.common.permission')}</span>
                                  )}
                                  <span className="text-gray-600 text-[9px]">{capitalize(station.type)}</span>
                                </div>
                                <button
                                  onClick={() => setConfirm({
                                    message: t('admin.players.resetStationNodes', { label: station.label, key: station.stationKey }),
                                    onConfirm: () => resetStationTechNodes(station.stationKey, selectedPlayer.identifier),
                                  })}
                                  className="flex items-center gap-1 text-red-400/60 hover:text-red-400 transition-colors text-[9px] px-1.5 py-0.5 rounded hover:bg-white/10"
                                >
                                  <RotateCcw className="w-2.5 h-2.5" />
                                  {t('admin.common.reset')}
                                </button>
                              </div>
                              <div className="flex flex-wrap gap-1.5">
                                {nodeIds.map(nodeId => (
                                  <span key={nodeId} className="text-[10px] px-2 py-0.5 rounded-lg text-amber-400" style={{ backgroundColor: 'rgba(251,191,36,0.1)' }}>
                                    {nodeId}
                                  </span>
                                ))}
                              </div>
                            </div>
                          );
                        });
                      })()}
                    </div>
                  </div>

                  {/* Active Queue */}
                  {selectedPlayer.queue && selectedPlayer.queue.queue.length > 0 && (
                    <div className="rounded-xl border overflow-hidden" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
                      <div className="flex items-center gap-2 px-4 py-2.5" style={{ backgroundColor: 'rgba(26,26,31,0.6)' }}>
                        <Clock className="w-3 h-3 text-gray-500" />
                        <span className="text-gray-400 text-xs font-medium">{t('admin.players.activeQueue')}</span>
                        <span className="text-gray-600 text-[10px]">{t('admin.players.queueAt', { type: capitalize(selectedPlayer.queue.workbenchType || t('admin.common.unknown')), id: selectedPlayer.queue.stationId })}</span>
                      </div>
                      <div className="p-2" style={{ backgroundColor: 'rgba(26,26,31,0.3)' }}>
                        <div className="space-y-1">
                          {selectedPlayer.queue.queue.map(item => {
                            const progress = item.totalTime > 0 ? Math.max(0, Math.min(100, ((item.totalTime - item.remainingTime) / item.totalTime) * 100)) : 0;
                            return (
                              <div key={item.id} className="rounded-lg px-3 py-2 relative overflow-hidden" style={{ backgroundColor: 'rgba(37,37,40,0.5)' }}>
                                <div className="absolute inset-0 opacity-20" style={{ background: `linear-gradient(90deg, rgba(74,222,128,0.3) ${progress}%, transparent ${progress}%)` }} />
                                <div className="relative flex items-center justify-between">
                                  <div>
                                    <span className="text-white text-[11px] font-medium">{item.recipeName}</span>
                                    <span className="text-gray-500 text-[10px] ml-1.5">x{item.quantity}</span>
                                  </div>
                                  <div className="text-right">
                                    <span className="text-gray-300 text-[11px] font-mono">{formatTime(item.remainingTime)}</span>
                                    <span className="text-gray-600 text-[10px]"> / {formatTime(item.totalTime)}</span>
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Queues Tab */}
              {activeTab === 'queues' && (
                <div className="space-y-1">
                  {filteredQueues.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-16 gap-2">
                      <Clock className="w-8 h-8 text-gray-700" />
                      <span className="text-gray-500 text-xs">{t('admin.queues.noActiveQueues')}</span>
                    </div>
                  ) : (
                    filteredQueues.map(item => {
                      const progress = item.totalTime > 0 ? Math.max(0, Math.min(100, ((item.totalTime - item.remainingTime) / item.totalTime) * 100)) : 100;
                      const initials = (item.ownerName || item.identifier || '??').split(/[\s_]+/).map(w => w[0]).join('').slice(0, 2).toUpperCase();
                      return (
                        <div key={`${item.type}-${item.id}`} className="flex items-center gap-3 px-4 py-3 rounded-lg transition-colors hover:bg-white/5">
                          {/* Avatar with initial */}
                          <div className="relative flex-shrink-0">
                            <div
                              className="w-9 h-9 rounded-full flex items-center justify-center text-[11px] font-bold border"
                              style={{
                                backgroundColor: '#1a1a1f',
                                borderColor: item.type === 'shared' ? 'rgba(96,165,250,0.25)' : 'rgba(255,255,255,0.08)',
                                color: item.type === 'shared' ? '#60A5FA' : '#9CA3AF',
                              }}
                            >
                              {initials}
                            </div>
                            {/* Progress ring around avatar */}
                            <svg className="absolute inset-0 w-9 h-9 -rotate-90" viewBox="0 0 36 36">
                              <circle cx="18" cy="18" r="16" fill="none" stroke="rgba(255,255,255,0.04)" strokeWidth="2" pathLength="100" />
                              <circle
                                cx="18" cy="18" r="16" fill="none"
                                stroke={progress >= 100 ? '#4ADE80' : '#22D3EE'}
                                strokeWidth="2"
                                strokeDasharray={`${progress} 100`}
                                strokeLinecap="round"
                                pathLength={100}
                                style={{ transition: 'stroke-dasharray 0.3s ease' }}
                              />
                            </svg>
                          </div>
                          {/* Content */}
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-white text-xs font-medium truncate">{item.recipeLabel || item.recipeName}</span>
                              <span className="text-gray-600 text-[10px]">x{item.quantity}</span>
                              {item.type === 'shared' && (
                                <span className="text-[10px] px-1.5 py-0.5 rounded text-blue-400 flex-shrink-0" style={{ backgroundColor: 'rgba(96,165,250,0.1)' }}>{t('admin.common.shared')}</span>
                              )}
                            </div>
                            <div className="text-gray-500 text-[10px] mt-0.5 truncate">
                              {item.ownerName || item.identifier}
                              {' '}&middot; {item.stationId}
                              {item.workbenchType && <span> &middot; {capitalize(item.workbenchType)}</span>}
                            </div>
                            <div className="text-[10px] mt-0.5 truncate">
                              <span className="text-gray-600">{t('admin.queues.output')} </span>
                              <span className="text-[#4ADE80]">{(item.outputAmount || 1) * item.quantity}x {item.recipeLabel || item.recipeName}</span>
                              {item.ingredients && item.ingredients.length > 0 && (
                                <>
                                  <span className="text-gray-700"> | </span>
                                  <span className="text-gray-600">{t('admin.queues.used')} </span>
                                  {item.ingredients.map((ing, idx) => (
                                    <span key={ing.item} className="text-gray-500">
                                      {idx > 0 && ', '}
                                      {ing.amount * item.quantity}x {ing.label}
                                    </span>
                                  ))}
                                </>
                              )}
                            </div>
                          </div>
                          {/* Time display */}
                          <div className="text-right flex-shrink-0 mr-1">
                            <div className="text-gray-300 text-xs font-mono">{formatTime(item.remainingTime)}</div>
                            <div className="text-gray-600 text-[10px]">{t('admin.common.of')} {formatTime(item.totalTime)}</div>
                          </div>
                          {/* Action buttons with tooltips */}
                          <div className="flex items-center gap-0.5 flex-shrink-0">
                            <div className="relative group/tip">
                              <button
                                onClick={() => forceCompleteQueueItem(item)}
                                className="p-1.5 rounded-lg text-gray-600 hover:text-[#4ADE80] hover:bg-white/10 transition-colors"
                              >
                                <Play className="w-3.5 h-3.5" />
                              </button>
                              <div className="absolute top-full left-1/2 -translate-x-1/2 mt-1.5 px-2 py-1 bg-black/90 text-white text-[10px] rounded whitespace-nowrap opacity-0 group-hover/tip:opacity-100 transition-opacity pointer-events-none z-10">
                                {t('admin.queues.forceComplete')}
                                <div className="absolute bottom-full left-1/2 -translate-x-1/2 w-0 h-0 border-x-[4px] border-x-transparent border-b-[4px] border-b-black/90" />
                              </div>
                            </div>
                            <div className="relative group/tip">
                              <button
                                onClick={() => cancelQueueItem(item)}
                                className="p-1.5 rounded-lg text-gray-600 hover:text-yellow-400 hover:bg-white/10 transition-colors"
                              >
                                <RotateCcw className="w-3.5 h-3.5" />
                              </button>
                              <div className="absolute top-full left-1/2 -translate-x-1/2 mt-1.5 px-2 py-1 bg-black/90 text-white text-[10px] rounded whitespace-nowrap opacity-0 group-hover/tip:opacity-100 transition-opacity pointer-events-none z-10">
                                {t('admin.queues.cancelRefund')}
                                <div className="absolute bottom-full left-1/2 -translate-x-1/2 w-0 h-0 border-x-[4px] border-x-transparent border-b-[4px] border-b-black/90" />
                              </div>
                            </div>
                            <div className="relative group/tip">
                              <button
                                onClick={() => setConfirm({
                                  message: t('admin.queues.removeConfirm'),
                                  onConfirm: () => removeQueueItem(item),
                                })}
                                className="p-1.5 rounded-lg text-gray-600 hover:text-red-400 hover:bg-white/10 transition-colors"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </button>
                              <div className="absolute top-full left-1/2 -translate-x-1/2 mt-1.5 px-2 py-1 bg-black/90 text-white text-[10px] rounded whitespace-nowrap opacity-0 group-hover/tip:opacity-100 transition-opacity pointer-events-none z-10">
                                {t('admin.queues.removeNoRefund')}
                                <div className="absolute bottom-full left-1/2 -translate-x-1/2 w-0 h-0 border-x-[4px] border-x-transparent border-b-[4px] border-b-black/90" />
                              </div>
                            </div>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              )}

              {/* Stations Tab */}
              {activeTab === 'stations' && (
                <div className="space-y-1.5">
                  {/* Filter tabs + Create Station button */}
                  <div className="flex items-center gap-2 px-1 pb-1">
                    <div className="flex flex-wrap gap-1 flex-1">
                      {(['all', 'static', 'placed', 'admin'] as const).map(filter => (
                        <button
                          key={filter}
                          onClick={() => setStationFilter(filter)}
                          className={`px-3 py-1.5 text-[10px] font-medium rounded-lg transition-all ${
                            stationFilter === filter
                              ? 'text-[#4ADE80]'
                              : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
                          }`}
                          style={stationFilter === filter ? { backgroundColor: 'rgba(74,222,128,0.1)' } : {}}
                        >
                          {filter === 'all' ? t('admin.common.all') : filter === 'static' ? t('admin.common.static') : filter === 'placed' ? t('admin.common.placed') : t('admin.common.admin')}
                        </button>
                      ))}
                    </div>
                    <button
                      onClick={async () => {
                        const [typeData, lcData] = await Promise.all([
                          fetchNui<WorkbenchType[]>('admin:getWorkbenchTypes'),
                          fetchNui<Record<string, LevelConfig>>('admin:getLevelConfig'),
                        ]);
                        if (Array.isArray(typeData) && typeData.length > 0) { setWorkbenchTypes(typeData); setWorkbenchTypesFetched(true); }
                        if (lcData && typeof lcData === 'object') { setLevelConfigs(lcData); setLevelConfigsFetched(true); }
                        setShowManageTypes(true);
                        setNewTypeName('');
                        setRenamingType(null);
                      }}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[11px] font-medium text-cyan-400 transition-colors hover:brightness-125"
                      style={{ backgroundColor: 'rgba(34,211,238,0.1)' }}
                    >
                      <Settings className="w-3 h-3" /> {t('admin.stations.manageTypes')}
                    </button>
                    <button
                      onClick={startCreateStation}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[11px] font-medium text-purple-400 transition-colors hover:brightness-125"
                      style={{ backgroundColor: 'rgba(168,85,247,0.1)' }}
                    >
                      <Plus className="w-3 h-3" /> {t('admin.stations.createStation')}
                    </button>
                  </div>

                  {filteredStations.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-16 gap-2">
                      <MapPin className="w-8 h-8 text-gray-700" />
                      <span className="text-gray-500 text-xs">{t('admin.stations.noStationsFound')}</span>
                    </div>
                  ) : (
                    filteredStations.map(station => {
                      return (
                      <div
                        key={station.stationKey}
                        className="rounded-xl border overflow-hidden transition-colors hover:bg-white/[0.02]"
                        style={{
                          backgroundColor: 'transparent',
                          borderColor: 'transparent',
                        }}
                      >
                        {/* Station header row */}
                        <div className="flex items-center gap-3 px-4 py-3 rounded-lg group">
                          {/* Station ID badge */}
                          <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-[11px] font-bold border ${station.isStatic ? 'text-blue-400' : station.isAdmin ? 'text-purple-400' : station.isPlaced ? 'text-amber-400' : 'text-gray-400'}`} style={{ backgroundColor: '#252528', borderColor: station.isStatic ? 'rgba(96,165,250,0.2)' : station.isAdmin ? 'rgba(168,85,247,0.2)' : station.isPlaced ? 'rgba(251,191,36,0.2)' : 'rgba(255,255,255,0.06)' }}>
                            {station.isStatic ? 'S' : station.isAdmin ? 'A' : station.isPlaced ? 'P' : station.id}
                          </div>
                          <div className="flex-1 min-w-0 text-left">
                            <div className="flex items-center gap-2">
                              <span className="text-white text-xs font-medium">{station.label || capitalize(station.type)}</span>
                              {station.isStatic && (
                                <span className="text-[10px] px-1.5 py-0.5 rounded text-blue-400 flex-shrink-0" style={{ backgroundColor: 'rgba(96,165,250,0.1)' }}>{t('admin.common.static')}</span>
                              )}
                              {station.isAdmin && (
                                <span className="text-[10px] px-1.5 py-0.5 rounded text-purple-400 flex-shrink-0" style={{ backgroundColor: 'rgba(168,85,247,0.1)' }}>{t('admin.common.admin')}</span>
                              )}
                              {station.isPlaced && (
                                <span className="text-[10px] px-1.5 py-0.5 rounded text-amber-400 flex-shrink-0" style={{ backgroundColor: 'rgba(251,191,36,0.1)' }}>{t('admin.common.placed')}</span>
                              )}
                              {station.sharedQueueCount != null && station.sharedQueueCount > 0 && (
                                <span className="text-[10px] px-1.5 py-0.5 rounded text-yellow-400 flex-shrink-0" style={{ backgroundColor: 'rgba(250,204,21,0.1)' }}>
                                  {t('admin.queues.queued', { count: station.sharedQueueCount })}
                                </span>
                              )}
                            </div>
                            <div className="text-gray-500 text-[10px] mt-0.5">
                              <span className="text-gray-600 font-mono">{station.stationKey}</span>
                              {station.isPlaced && (station.ownerName || station.owner) && <span> &middot; {station.ownerName || station.owner}</span>}
                              {station.isPlaced && station.ownerOnline && <span className="text-[#4ADE80]"> {t('admin.stations.onlineStatus')}</span>}
                              {' '}&middot; {station.coords ? `${station.coords.x.toFixed(1)}, ${station.coords.y.toFixed(1)}, ${station.coords.z.toFixed(1)}` : t('admin.stations.coordsUnknown')}
                            </div>
                            <div className="text-gray-600 text-[10px] mt-0.5 truncate">
                              {station.isStatic || station.isAdmin ? capitalize(station.type) : station.item} &middot; {typeof station.prop === 'object' && station.prop !== null ? station.prop.model : (station.prop || t('admin.stations.propNone'))}
                            </div>
                            {station.techTrees && station.techTrees.length > 0 && (
                              <div className="flex flex-wrap gap-1 mt-1">
                                {station.techTrees.map(treeId => {
                                  const tree = techTrees[treeId];
                                  return (
                                    <span
                                      key={treeId}
                                      className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[9px]"
                                      style={{ backgroundColor: tree ? (tree.color || '#4ADE80') + '15' : 'rgba(255,255,255,0.05)', color: tree ? (tree.color || '#4ADE80') : '#6b7280' }}
                                    >
                                      <span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ backgroundColor: tree?.color || '#6b7280' }} />
                                      {tree?.label || treeId}
                                    </span>
                                  );
                                })}
                              </div>
                            )}
                          </div>
                          <div className="flex items-center gap-0.5 flex-shrink-0">
                            <button
                              onClick={() => openInventoryModal(station)}
                              className="p-1.5 rounded-lg text-gray-600 hover:text-blue-400 hover:bg-white/10 transition-colors"
                              title={t('admin.stations.viewInventory')}
                            >
                              <Package className="w-3 h-3" />
                            </button>
                            <button
                              onClick={() => teleportToStation(station)}
                              className="p-1.5 rounded-lg text-gray-600 hover:text-[#4ADE80] hover:bg-white/10 transition-colors"
                              title={t('admin.stations.teleport')}
                            >
                              <MapPin className="w-3 h-3" />
                            </button>
                            <button
                              onClick={() => startEditStation(station)}
                              className="p-1.5 rounded-lg text-gray-600 hover:text-purple-400 hover:bg-white/10 transition-colors"
                              title={t('admin.stations.editStation')}
                            >
                              <Edit3 className="w-3 h-3" />
                            </button>
                            {(station.isAdmin || !station.isStatic) && (
                              <button
                                onClick={() => setConfirm({
                                  message: t('admin.stations.deleteConfirm', { label: station.label || station.id }),
                                  onConfirm: () => deleteStation(station.isAdmin ? station.stationKey : station.id),
                                })}
                                className="p-1.5 rounded-lg text-gray-600 hover:text-red-400 hover:bg-white/10 transition-colors"
                                title={t('admin.stations.deleteStation')}
                              >
                                <Trash2 className="w-3 h-3" />
                              </button>
                            )}
                          </div>
                        </div>
                      </div>
                      );
                    })
                  )}
                </div>
              )}

              {/* Recipes Tab */}
              {activeTab === 'recipes' && (
                <div className="space-y-3">
                  {/* Table selector + Create buttons */}
                  <div className="flex items-center gap-2">
                    <div className="flex flex-wrap gap-1 flex-1">
                      {recipeTables.map(table => (
                        <button
                          key={table}
                          onClick={() => { setSelectedTable(table); setExpandedRecipe(null); setEditingRecipe(null); setEditingRecipeId(null); setIsCreatingRecipe(false); }}
                          className={`px-3 py-1.5 text-[10px] font-medium rounded-lg transition-all ${
                            selectedTable === table
                              ? 'text-[#4ADE80]'
                              : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
                          }`}
                          style={selectedTable === table ? { backgroundColor: 'rgba(74,222,128,0.1)' } : {}}
                        >
                          {capitalize(table)}
                        </button>
                      ))}
                    </div>
                    <button
                      onClick={() => { setShowManageTables(true); setNewTableName(''); }}
                      className="flex items-center gap-1.5 px-3 py-1.5 text-[10px] rounded-lg text-cyan-400 transition-colors hover:brightness-125 flex-shrink-0"
                      style={{ backgroundColor: 'rgba(34,211,238,0.1)' }}
                    >
                      <Settings className="w-3 h-3" /> {t('admin.recipes.manageTables')}
                    </button>
                    <button
                      onClick={() => {
                        setEditingRecipe(blankRecipeForm(selectedTable));
                        setEditingRecipeId(null);
                        setIsCreatingRecipe(true);
                        setExpandedRecipe(null);
                      }}
                      className="flex items-center gap-1.5 px-3 py-1.5 text-[10px] rounded-lg text-[#4ADE80] transition-colors hover:brightness-110 flex-shrink-0"
                      style={{ backgroundColor: 'rgba(74,222,128,0.1)' }}
                    >
                      <Plus className="w-3 h-3" />
                      {t('admin.recipes.createRecipe')}
                    </button>
                  </div>

                  {/* Recipe list */}
                  <div className="space-y-1">
                    {filteredRecipes.length === 0 && !isCreatingRecipe ? (
                      <div className="flex flex-col items-center justify-center py-16 gap-2">
                        <BookOpen className="w-8 h-8 text-gray-700" />
                        <span className="text-gray-500 text-xs">{t('admin.recipes.noRecipesFound')}</span>
                      </div>
                    ) : (
                      filteredRecipes.map(recipe => (
                        <div key={recipe.id}>
                          <button
                            onClick={() => {
                              if (isCreatingRecipe) return;
                              setExpandedRecipe(expandedRecipe === recipe.id ? null : recipe.id);
                              setEditingRecipe(null);
                              setEditingRecipeId(null);
                            }}
                            className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-left transition-colors hover:bg-white/5 group"
                          >
                            <div className="w-8 h-8 rounded-md flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#252528' }}>
                              <ItemImage src={getItemImage(recipe.name)} alt={recipe.label || capitalize(recipe.name)} className="w-6 h-6 object-contain" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2">
                                <span className={`text-xs font-medium ${recipe.enabled ? 'text-white' : 'text-gray-500 line-through'}`}>
                                  {recipe.label || capitalize(recipe.name)}
                                </span>
                                {!recipe.enabled && (
                                  <span className="text-[10px] px-1.5 py-0.5 rounded text-red-400" style={{ backgroundColor: 'rgba(239,68,68,0.1)' }}>{t('admin.recipes.disabled')}</span>
                                )}
                              </div>
                              <div className="text-gray-500 text-[10px] mt-0.5">
                                {t('admin.recipes.recipeSummary', { time: recipe.craftTime, level: recipe.levelRequired || 0, xp: recipe.xpReward || 0 })}
                                {recipe.techPointsReward ? t('admin.recipes.recipeSummaryTp', { tp: recipe.techPointsReward }) : ''}
                                {recipe.outputAmount && recipe.outputAmount > 1 && ` \u00b7 x${recipe.outputAmount}`}
                              </div>
                            </div>
                            <ChevronDown className={`w-3.5 h-3.5 text-gray-700 group-hover:text-gray-400 flex-shrink-0 transition-all ${expandedRecipe === recipe.id ? 'rotate-180' : ''}`} />
                          </button>

                          {/* Expanded recipe detail */}
                          {expandedRecipe === recipe.id && (
                            <div className="ml-4 mr-4 mb-2 p-4 rounded-xl border space-y-3" style={{ backgroundColor: 'rgba(26,26,31,0.6)', borderColor: 'rgba(255,255,255,0.06)' }}>
                              {/* Ingredients */}
                              <div>
                                <div className="text-gray-500 text-[10px] mb-1.5 font-medium">{t('admin.recipes.ingredients')}</div>
                                <div className="flex flex-wrap gap-1.5">
                                  {recipe.ingredients.map((ing, i) => (
                                    <span key={i} className="text-[11px] px-2.5 py-1 rounded-lg text-gray-300 border" style={{ backgroundColor: 'rgba(37,37,40,0.5)', borderColor: 'rgba(255,255,255,0.04)' }}>
                                      {ing.amount}x {ing.label || capitalize(ing.item)}
                                    </span>
                                  ))}
                                </div>
                              </div>

                              {/* Tools */}
                              {recipe.tools && recipe.tools.length > 0 && (
                                <div>
                                  <div className="text-gray-500 text-[10px] mb-1.5 font-medium">{t('admin.recipes.tools')}</div>
                                  <div className="flex flex-wrap gap-1.5">
                                    {recipe.tools.map((tool, i) => (
                                      <span key={i} className="text-[11px] px-2.5 py-1 rounded-lg text-gray-300 border" style={{ backgroundColor: 'rgba(37,37,40,0.5)', borderColor: 'rgba(255,255,255,0.04)' }}>
                                        {tool.amount}x {tool.label || capitalize(tool.item)}
                                        {tool.consumptionType && tool.consumptionType !== 'none' && (
                                          <span className="text-gray-500 ml-1">({tool.consumptionType})</span>
                                        )}
                                      </span>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* Extra info */}
                              <div className="flex flex-wrap gap-x-4 gap-y-1 text-[10px] text-gray-500">
                                <span>{t('admin.common.id')}: <span className="text-gray-400">{recipe.id}</span></span>
                                <span>{t('admin.common.item')}: <span className="text-gray-400">{recipe.name}</span></span>
                                {recipe.blueprint && <span>{t('admin.common.blueprint')}: <span className="text-gray-400">{recipe.blueprint}</span></span>}
                                {recipe.cost ? <span>{t('admin.common.cost')}: <span className="text-gray-400">${recipe.cost}</span></span> : null}
                                {recipe.failChance ? <span>{t('admin.common.fail')}: <span className="text-gray-400">{recipe.failChance}%</span></span> : null}
                                {recipe.image && <span>{t('admin.common.image')}: <span className="text-gray-400 truncate max-w-[120px] inline-block align-bottom">{recipe.image}</span></span>}
                                {recipe.metadata && Object.keys(recipe.metadata).length > 0 && (
                                  <span>{t('admin.recipes.metadata')}: <span className="text-gray-400">{Object.entries(recipe.metadata).map(([k, v]) => `${k}=${v}`).join(', ')}</span></span>
                                )}
                              </div>

                              {/* Action buttons */}
                              <div className="flex items-center gap-2 pt-2 border-t" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
                                <button
                                  onClick={() => {
                                    setEditingRecipe(recipeToForm(recipe, selectedTable));
                                    setEditingRecipeId(recipe.id);
                                    setIsCreatingRecipe(false);
                                  }}
                                  className="flex items-center gap-1.5 px-3 py-1.5 text-[10px] rounded-lg text-gray-400 hover:text-white transition-colors"
                                  style={{ backgroundColor: '#252528' }}
                                >
                                  <Edit3 className="w-2.5 h-2.5" />
                                  {t('admin.common.edit')}
                                </button>
                                <button
                                  onClick={() => toggleRecipeEnabled(recipe)}
                                  className={`flex items-center gap-1.5 px-3 py-1.5 text-[10px] rounded-lg transition-colors ${
                                    recipe.enabled ? 'text-red-400' : 'text-[#4ADE80]'
                                  }`}
                                  style={{ backgroundColor: recipe.enabled ? 'rgba(239,68,68,0.1)' : 'rgba(74,222,128,0.1)' }}
                                >
                                  {recipe.enabled ? <XCircle className="w-2.5 h-2.5" /> : <Check className="w-2.5 h-2.5" />}
                                  {recipe.enabled ? t('admin.common.disable') : t('admin.common.enable')}
                                </button>
                                <button
                                  onClick={() => setConfirm({
                                    message: t('admin.recipes.deleteConfirm', { name: recipe.label || capitalize(recipe.name) }),
                                    onConfirm: () => deleteRecipe(recipe.id),
                                  })}
                                  className="flex items-center gap-1.5 px-3 py-1.5 text-[10px] rounded-lg text-red-400 transition-colors hover:brightness-110"
                                  style={{ backgroundColor: 'rgba(239,68,68,0.1)' }}
                                >
                                  <Trash2 className="w-2.5 h-2.5" />
                                  {t('admin.common.delete')}
                                </button>
                              </div>

                              <div className="text-gray-600 text-[9px] italic">{t('admin.techTrees.changesNote')}</div>
                            </div>
                          )}

                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}

              {/* Tech Trees Tab */}
              {activeTab === 'techtrees' && (
                <div className="flex gap-4" style={{ height: 'calc(100% - 8px)' }}>
                  {/* Left: Tree list */}
                  <div className="w-64 flex-shrink-0 space-y-1 overflow-y-auto pr-1">
                    {filteredTreeIds.length === 0 ? (
                      <div className="flex flex-col items-center justify-center py-16 gap-2">
                        <GitBranch className="w-8 h-8 text-gray-700" />
                        <span className="text-gray-500 text-xs">{t('admin.techTrees.noTreesFound')}</span>
                      </div>
                    ) : (
                      filteredTreeIds.map(treeId => {
                        const tree = techTrees[treeId];
                        return (
                          <button
                            key={treeId}
                            onClick={() => {
                              setSelectedTree(selectedTree === treeId ? null : treeId);
                              setEditingNode(null);
                              setEditingNodeId(null);
                              setIsCreatingNode(false);
                              setTreePan({ x: 0, y: 0 });
                              setTreeZoom(0.85);
                            }}
                            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-left transition-colors ${
                              selectedTree === treeId
                                ? 'bg-white/10 text-white'
                                : 'hover:bg-white/5 text-gray-400'
                            }`}
                          >
                            <div className="w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: tree.color || '#4ADE80' }} />
                            <div className="flex-1 min-w-0">
                              <div className="text-xs font-medium truncate">{tree.label}</div>
                              <div className="text-gray-600 text-[10px]">
                                {t('admin.techTrees.nodes', { count: (tree.nodes || []).length })}
                              </div>
                            </div>
                            <span
                              className="text-[9px] px-1.5 py-0.5 rounded flex-shrink-0"
                              style={{
                                backgroundColor: tree.source === 'admin' ? 'rgba(59,130,246,0.1)' : 'rgba(255,255,255,0.05)',
                                color: tree.source === 'admin' ? '#3b82f6' : '#6B7280',
                              }}
                            >
                              {tree.source || t('admin.common.config')}
                            </span>
                          </button>
                        );
                      })
                    )}

                    <button
                      onClick={() => {
                        setEditingTree({ treeId: '', label: '', icon: 'git-branch', color: '#4ADE80' });
                        setIsCreatingTree(true);
                      }}
                      className="w-full flex items-center gap-2 justify-center px-3 py-2 text-[10px] rounded-lg text-[#4ADE80] transition-colors hover:brightness-110 mt-2"
                      style={{ backgroundColor: 'rgba(74,222,128,0.1)' }}
                    >
                      <Plus className="w-3 h-3" />
                      {t('admin.techTrees.createTree')}
                    </button>
                  </div>

                  {/* Right: Selected tree detail */}
                  <div className="flex-1 flex flex-col overflow-hidden">
                    {!selectedTreeData ? (
                      <div className="flex flex-col items-center justify-center h-full gap-2">
                        <GitBranch className="w-8 h-8 text-gray-700" />
                        <span className="text-gray-500 text-xs">{t('admin.techTrees.selectTree')}</span>
                      </div>
                    ) : (
                      <div className="flex flex-col h-full gap-2">
                        {/* Tree header */}
                        <div className="flex items-center justify-between px-4 py-3 rounded-xl border flex-shrink-0" style={{ backgroundColor: 'rgba(26,26,31,0.6)', borderColor: 'rgba(255,255,255,0.06)' }}>
                          <div className="flex items-center gap-3">
                            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: selectedTreeData.color || '#4ADE80' }} />
                            <div>
                              <div className="text-white text-xs font-medium">{selectedTreeData.label}</div>
                              <div className="text-gray-500 text-[10px]">
                                {t('admin.common.id')}: {selectedTree} &middot; {t('admin.common.icon')}: {selectedTreeData.icon} &middot; {(selectedTreeData.nodes || []).length} {t('admin.common.nodes')}
                              </div>
                            </div>
                          </div>
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => {
                                setEditingTree({
                                  treeId: selectedTree!,
                                  label: selectedTreeData.label,
                                  icon: selectedTreeData.icon || '',
                                  color: selectedTreeData.color || '#4ADE80',
                                });
                                setIsCreatingTree(false);
                              }}
                              className="flex items-center gap-1.5 px-3 py-1.5 text-[10px] rounded-lg text-gray-400 hover:text-white transition-colors"
                              style={{ backgroundColor: '#252528' }}
                            >
                              <Edit3 className="w-2.5 h-2.5" />
                              {t('admin.common.edit')}
                            </button>
                            <button
                              onClick={() => setConfirm({
                                message: t('admin.techTrees.deleteTreeConfirm', { label: selectedTreeData.label }),
                                onConfirm: () => deleteTechTree(selectedTree!),
                              })}
                              className="flex items-center gap-1.5 px-3 py-1.5 text-[10px] rounded-lg text-red-400 transition-colors hover:brightness-110"
                              style={{ backgroundColor: 'rgba(239,68,68,0.1)' }}
                            >
                              <Trash2 className="w-2.5 h-2.5" />
                              {t('admin.common.delete')}
                            </button>
                          </div>
                        </div>

                        {/* Visual Tech Tree Grid */}
                        {(() => {
                          const nodes = selectedTreeData.nodes || [];
                          const treeColor = selectedTreeData.color || '#4ADE80';

                          const recipeMap: Record<string, AdminRecipe> = {};
                          for (const tableRecipes of Object.values(recipes)) {
                            for (const r of tableRecipes) {
                              recipeMap[r.id] = r;
                            }
                          }

                          if (nodes.length === 0) {
                            return (
                              <div className="flex-1 flex flex-col items-center justify-center gap-3">
                                <button
                                  onClick={async () => {
                                    if (Object.keys(recipes).length === 0) {
                                      const data = await fetchNui<any>('admin:getRecipes');
                                      const parsed = parseRecipeResponse(data);
                                      if (parsed) { setRecipes(parsed.recipes); setTableSources(parsed.sources); }
                                    }
                                    setEditingNode({ id: '', recipeId: '', cost: '1', prerequisites: [], position: { row: '1', col: '1' } });
                                    setEditingNodeId(null);
                                    setIsCreatingNode(true);
                                  }}
                                  className="w-20 h-20 rounded-xl border-2 border-dashed flex items-center justify-center transition-all hover:scale-105"
                                  style={{ borderColor: treeColor + '60', color: treeColor }}
                                >
                                  <Plus className="w-8 h-8" />
                                </button>
                                <span className="text-gray-500 text-[11px]">{t('admin.techTrees.addFirstNode')}</span>
                              </div>
                            );
                          }

                          const nodeSize = 80;
                          const gapX = 120;
                          const gapY = 100;
                          const padding = 40;

                          let minRow = Infinity, maxRow = 0, minCol = Infinity, maxCol = 0;
                          nodes.forEach(n => {
                            minRow = Math.min(minRow, n.position?.row ?? 1);
                            maxRow = Math.max(maxRow, n.position?.row ?? 1);
                            minCol = Math.min(minCol, n.position?.col ?? 1);
                            maxCol = Math.max(maxCol, n.position?.col ?? 1);
                          });

                          const extMinRow = minRow - 1;
                          const extMaxRow = maxRow + 1;
                          const extMinCol = minCol - 1;
                          const extMaxCol = maxCol + 1;

                          const getNodeX = (col: number) => (col - extMinCol) * gapX;
                          const getNodeY = (row: number) => (row - extMinRow) * gapY;

                          const gridWidth = (extMaxCol - extMinCol) * gapX + nodeSize;
                          const gridHeight = (extMaxRow - extMinRow) * gapY + nodeSize;

                          const occupiedPositions = new Set(nodes.map(n => `${n.position?.row ?? 1},${n.position?.col ?? 1}`));

                          const emptyCells: { row: number; col: number }[] = [];
                          for (let r = extMinRow; r <= extMaxRow; r++) {
                            for (let c = extMinCol; c <= extMaxCol; c++) {
                              if (!occupiedPositions.has(`${r},${c}`)) {
                                emptyCells.push({ row: r, col: c });
                              }
                            }
                          }

                          return (
                            <div
                              ref={treeRefCallback}
                              className={`flex-1 overflow-hidden relative rounded-xl border ${isPanningTree ? 'cursor-grabbing' : 'cursor-grab'}`}
                              style={{ backgroundColor: 'rgba(12,12,14,0.6)', borderColor: 'rgba(255,255,255,0.04)' }}
                              onMouseDown={(e) => {
                                if (e.button === 0) {
                                  setIsPanningTree(true);
                                  setTreePanStart({ x: e.clientX - treePan.x, y: e.clientY - treePan.y });
                                }
                              }}
                              onMouseMove={(e) => {
                                if (isPanningTree && treeContainerRef.current) {
                                  const container = treeContainerRef.current;
                                  const rect = container.getBoundingClientRect();
                                  const contentWidth = gridWidth * treeZoom;
                                  const contentHeight = gridHeight * treeZoom;
                                  const maxPanX = Math.max(rect.width * 0.5, (contentWidth - rect.width) / 2 + rect.width * 0.3);
                                  const maxPanY = Math.max(rect.height * 0.5, (contentHeight - rect.height) / 2 + rect.height * 0.3);
                                  const newX = e.clientX - treePanStart.x;
                                  const newY = e.clientY - treePanStart.y;
                                  setTreePan({
                                    x: Math.max(-maxPanX, Math.min(maxPanX, newX)),
                                    y: Math.max(-maxPanY, Math.min(maxPanY, newY)),
                                  });
                                }
                              }}
                              onMouseUp={() => setIsPanningTree(false)}
                              onMouseLeave={() => setIsPanningTree(false)}
                            >
                              {/* Zoom indicator */}
                              <div className="absolute top-2 right-2 z-10 px-2 py-0.5 rounded text-[9px] font-medium text-gray-400" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
                                {Math.round(treeZoom * 100)}%
                              </div>
                              {/* Pan/zoom hint */}
                              <div className="absolute bottom-2 left-2 z-10 text-[9px] text-gray-600 select-none">
                                {t('admin.techTrees.dragToPan')} &middot; {t('admin.techTrees.scrollToZoom')}
                              </div>

                              <div
                                className="flex items-center justify-center min-h-full w-full"
                                style={{
                                  transform: `translate(${treePan.x}px, ${treePan.y}px) scale(${treeZoom})`,
                                  transition: isPanningTree ? 'none' : 'transform 0.15s ease-out',
                                }}
                              >
                                <div
                                  className="relative"
                                  style={{
                                    width: gridWidth + padding * 2,
                                    height: gridHeight + padding * 2,
                                    minWidth: 300,
                                  }}
                                >
                                  {/* SVG prerequisite lines */}
                                  <svg
                                    className="absolute pointer-events-none"
                                    style={{ left: padding, top: padding, width: gridWidth, height: gridHeight }}
                                  >
                                    {nodes.map(node =>
                                      (node.prerequisites || []).map(prereqId => {
                                        const prereq = nodes.find(n => n.id === prereqId);
                                        if (!prereq) return null;
                                        const x1 = getNodeX(prereq.position?.col ?? 1) + nodeSize / 2;
                                        const y1 = getNodeY(prereq.position?.row ?? 1) + nodeSize;
                                        const x2 = getNodeX(node.position?.col ?? 1) + nodeSize / 2;
                                        const y2 = getNodeY(node.position?.row ?? 1);
                                        const midY = (y1 + y2) / 2;
                                        return (
                                          <path
                                            key={`${prereqId}-${node.id}`}
                                            d={`M ${x1} ${y1} C ${x1} ${midY}, ${x2} ${midY}, ${x2} ${y2}`}
                                            stroke={treeColor}
                                            strokeWidth={2}
                                            fill="none"
                                            opacity={0.6}
                                          />
                                        );
                                      })
                                    )}
                                  </svg>

                                  {/* Node cards */}
                                  {nodes.map(node => (
                                    <div
                                      key={node.id}
                                      className="absolute rounded-lg border-l-[3px] flex flex-col items-center justify-center transition-all duration-150 hover:brightness-125 hover:scale-105 group"
                                      style={{
                                        left: getNodeX(node.position?.col ?? 1) + padding,
                                        top: getNodeY(node.position?.row ?? 1) + padding,
                                        width: nodeSize,
                                        height: nodeSize,
                                        backgroundColor: 'rgba(26,26,31,0.9)',
                                        borderColor: treeColor,
                                        borderTopColor: 'rgba(255,255,255,0.08)',
                                        borderRightColor: 'rgba(255,255,255,0.08)',
                                        borderBottomColor: 'rgba(255,255,255,0.08)',
                                        borderTopWidth: 1,
                                        borderRightWidth: 1,
                                        borderBottomWidth: 1,
                                        cursor: 'pointer',
                                        boxShadow: `0 0 12px ${treeColor}15`,
                                      }}
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        setEditingNode({
                                          id: node.id,
                                          recipeId: node.recipeId,
                                          cost: String(node.cost),
                                          prerequisites: [...(node.prerequisites || [])],
                                          position: { row: String(node.position?.row ?? 1), col: String(node.position?.col ?? 1) },
                                        });
                                        setEditingNodeId(node.id);
                                        setIsCreatingNode(false);
                                      }}
                                    >
                                      {(() => {
                                        const recipe = recipeMap[node.recipeId];
                                        return recipe ? (
                                          <>
                                            <ItemImage
                                              src={getItemImage(recipe.name)}
                                              alt={recipe.label || capitalize(recipe.name)}
                                              className="w-10 h-10 object-contain"
                                            />
                                            <span className="text-white text-[9px] leading-tight text-center px-1 truncate w-full mt-0.5">{recipe.label || capitalize(recipe.name)}</span>
                                          </>
                                        ) : (
                                          <>
                                            <Package className="w-8 h-8 text-gray-600" />
                                            <span className="text-gray-500 text-[9px] truncate w-full text-center px-1 mt-0.5">{node.recipeId}</span>
                                          </>
                                        );
                                      })()}
                                      <div
                                        className="absolute -bottom-2 px-1.5 py-0.5 rounded-full text-[8px] font-bold text-white"
                                        style={{ backgroundColor: treeColor }}
                                      >
                                        {node.cost} {t('admin.common.tp')}
                                      </div>
                                      {/* Delete button on hover */}
                                      <button
                                        className="absolute -top-1.5 -right-1.5 w-4 h-4 rounded-full bg-red-500 text-white items-center justify-center text-[8px] opacity-0 group-hover:opacity-100 transition-opacity hidden group-hover:flex"
                                        onClick={(e) => {
                                          e.stopPropagation();
                                          setConfirm({
                                            message: t('admin.techTrees.deleteNodeConfirm', { id: node.id }),
                                            onConfirm: () => deleteNode(selectedTree!, node.id),
                                          });
                                        }}
                                      >
                                        <X className="w-2.5 h-2.5" />
                                      </button>
                                    </div>
                                  ))}

                                  {/* Empty ghost cells for adding nodes */}
                                  {emptyCells.map(({ row, col }) => (
                                    <button
                                      key={`empty-${row}-${col}`}
                                      className="absolute rounded-lg border border-dashed flex items-center justify-center transition-all duration-150 hover:scale-105"
                                      style={{
                                        left: getNodeX(col) + padding,
                                        top: getNodeY(row) + padding,
                                        width: nodeSize,
                                        height: nodeSize,
                                        borderColor: 'rgba(255,255,255,0.08)',
                                        backgroundColor: 'transparent',
                                        cursor: 'pointer',
                                        color: 'rgba(255,255,255,0.15)',
                                      }}
                                      onMouseEnter={(e) => {
                                        (e.currentTarget as HTMLElement).style.borderColor = treeColor + '40';
                                        (e.currentTarget as HTMLElement).style.color = treeColor + '60';
                                        (e.currentTarget as HTMLElement).style.backgroundColor = treeColor + '08';
                                      }}
                                      onMouseLeave={(e) => {
                                        (e.currentTarget as HTMLElement).style.borderColor = 'rgba(255,255,255,0.08)';
                                        (e.currentTarget as HTMLElement).style.color = 'rgba(255,255,255,0.15)';
                                        (e.currentTarget as HTMLElement).style.backgroundColor = 'transparent';
                                      }}
                                      onClick={async (e) => {
                                        e.stopPropagation();
                                        if (Object.keys(recipes).length === 0) {
                                          const data = await fetchNui<any>('admin:getRecipes');
                                          const parsed = parseRecipeResponse(data);
                                          if (parsed) { setRecipes(parsed.recipes); setTableSources(parsed.sources); }
                                        }
                                        setEditingNode({ id: '', recipeId: '', cost: '1', prerequisites: [], position: { row: String(row), col: String(col) } });
                                        setEditingNodeId(null);
                                        setIsCreatingNode(true);
                                      }}
                                    >
                                      <Plus className="w-4 h-4" />
                                    </button>
                                  ))}
                                </div>
                              </div>
                            </div>
                          );
                        })()}

                        {/* Fallback Add Node button */}
                        <div className="flex items-center gap-2 flex-shrink-0 px-1">
                          <button
                            onClick={async () => {
                              if (Object.keys(recipes).length === 0) {
                                const data = await fetchNui<any>('admin:getRecipes');
                                const parsed = parseRecipeResponse(data);
                                if (parsed) { setRecipes(parsed.recipes); setTableSources(parsed.sources); }
                              }
                              setEditingNode({
                                id: '',
                                recipeId: '',
                                cost: '1',
                                prerequisites: [],
                                position: { row: '1', col: '1' },
                              });
                              setEditingNodeId(null);
                              setIsCreatingNode(true);
                            }}
                            className="flex items-center gap-1.5 px-3 py-1.5 text-[10px] rounded-lg text-[#4ADE80] transition-colors hover:brightness-110"
                            style={{ backgroundColor: 'rgba(74,222,128,0.1)' }}
                          >
                            <Plus className="w-3 h-3" />
                            {t('admin.techTrees.addNode')}
                          </button>
                          <span className="text-gray-600 text-[9px] italic">{t('admin.techTrees.changesNote')}</span>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Tree Create/Edit Modal */}
              {editingTree && (
                <FormModal
                  title={isCreatingTree ? t('admin.techTrees.createTechTree') : t('admin.techTrees.editTechTree', { id: editingTree.treeId })}
                  onClose={() => { setEditingTree(null); setIsCreatingTree(false); }}
                  accentColor={editingTree.color || '#4ADE80'}
                >
                  <FormSection label={t('admin.techTrees.treeDetails')}>
                    <div className="grid grid-cols-2 gap-3">
                      {isCreatingTree && (
                        <FormInput
                          label={t('admin.techTrees.treeIdLabel')}
                          value={editingTree.treeId}
                          onChange={v => setEditingTree(prev => prev ? { ...prev, treeId: v.toLowerCase().replace(/[^a-z0-9_]/g, '') } : prev)}
                          placeholder={t('admin.techTrees.treeIdPlaceholder')}
                        />
                      )}
                      <FormInput
                        label={t('admin.stations.label')}
                        value={editingTree.label}
                        onChange={v => setEditingTree(prev => prev ? { ...prev, label: v } : prev)}
                        placeholder={t('admin.techTrees.displayName')}
                      />
                      <FormInput
                        label={t('admin.techTrees.iconLabel')}
                        value={editingTree.icon}
                        onChange={v => setEditingTree(prev => prev ? { ...prev, icon: v } : prev)}
                        placeholder={t('admin.techTrees.iconPlaceholder')}
                      />
                      <div>
                        <div className="text-gray-400 text-[10px] font-medium mb-1">{t('admin.techTrees.color')}</div>
                        <div className="flex items-center gap-2">
                          <input
                            type="color"
                            value={editingTree.color || '#4ADE80'}
                            onChange={e => setEditingTree(prev => prev ? { ...prev, color: e.target.value } : prev)}
                            className="w-8 h-8 rounded cursor-pointer border-0 p-0"
                            style={{ backgroundColor: 'transparent' }}
                          />
                          <input
                            type="text"
                            value={editingTree.color}
                            onChange={e => setEditingTree(prev => prev ? { ...prev, color: e.target.value } : prev)}
                            className="flex-1 rounded-md px-2.5 py-1.5 text-white text-xs border border-transparent focus:border-white/10 focus:outline-none"
                            style={{ backgroundColor: '#252528' }}
                            placeholder="#4ADE80"
                          />
                        </div>
                      </div>
                    </div>
                  </FormSection>
                  <div className="flex justify-end gap-2 pt-2">
                    <button
                      onClick={() => { setEditingTree(null); setIsCreatingTree(false); }}
                      className="px-5 py-2 text-xs rounded-lg text-gray-400 hover:text-white transition-colors"
                      style={{ backgroundColor: '#252528' }}
                    >
                      {t('admin.common.cancel')}
                    </button>
                    <button
                      onClick={saveTreeForm}
                      className="px-5 py-2 text-xs rounded-lg text-white transition-colors hover:brightness-110"
                      style={{ backgroundColor: editingTree.color || '#4ADE80' }}
                    >
                      {isCreatingTree ? t('admin.common.create') : t('admin.common.save')}
                    </button>
                  </div>
                </FormModal>
              )}

              {/* Node Create/Edit Modal */}
              {editingNode && (
                <FormModal
                  title={isCreatingNode ? t('admin.techTrees.addNode') : t('admin.techTrees.editNodeTitle', { id: editingNodeId })}
                  onClose={() => { setEditingNode(null); setEditingNodeId(null); setIsCreatingNode(false); }}
                >
                  <FormSection label={t('admin.techTrees.nodeSettings')}>
                    <div className="grid grid-cols-2 gap-3">
                      {isCreatingNode && (
                        <FormInput
                          label={t('admin.techTrees.nodeIdLabel')}
                          value={editingNode.id}
                          onChange={v => setEditingNode(prev => prev ? { ...prev, id: v.replace(/\s/g, '_') } : prev)}
                          placeholder={t('admin.techTrees.nodeIdPlaceholder')}
                        />
                      )}
                      <SearchableRecipeDropdown
                        label={t('admin.techTrees.recipeId')}
                        options={allRecipeOptions()}
                        value={editingNode.recipeId}
                        onChange={v => setEditingNode(prev => prev ? { ...prev, recipeId: v } : prev)}
                        placeholder={t('admin.techTrees.selectRecipe')}
                        usedBy={(() => {
                          const map: Record<string, { treeId: string; treeName: string; nodeId: string }> = {};
                          for (const [tId, tree] of Object.entries(techTrees)) {
                            for (const node of (tree.nodes || [])) {
                              if (node.recipeId && !map[node.recipeId]) {
                                map[node.recipeId] = { treeId: tId, treeName: tree.label, nodeId: node.id };
                              }
                            }
                          }
                          return map;
                        })()}
                        currentRecipeId={editingNodeId ? (techTrees[selectedTree!]?.nodes || []).find(n => n.id === editingNodeId)?.recipeId : undefined}
                        onLocate={(treeId, nodeId) => {
                          setEditingNode(null);
                          setEditingNodeId(null);
                          setIsCreatingNode(false);
                          setSelectedTree(treeId);
                          setTreePan({ x: 0, y: 0 });
                          setTreeZoom(0.85);
                          setTimeout(() => {
                            const tree = techTrees[treeId];
                            if (!tree) return;
                            const node = (tree.nodes || []).find(n => n.id === nodeId);
                            if (!node) return;
                            setEditingNode({
                              id: node.id,
                              recipeId: node.recipeId,
                              cost: String(node.cost),
                              prerequisites: [...(node.prerequisites || [])],
                              position: { row: String(node.position?.row ?? 1), col: String(node.position?.col ?? 1) },
                            });
                            setEditingNodeId(node.id);
                            setIsCreatingNode(false);
                          }, 100);
                        }}
                      />
                      <NumberInput label={t('admin.techTrees.costTP')} value={editingNode.cost} onChange={v => setEditingNode(prev => prev ? { ...prev, cost: v } : prev)} min={0} />
                      <div className="grid grid-cols-2 gap-2">
                        <NumberInput label={t('admin.techTrees.row')} value={editingNode.position.row} onChange={v => setEditingNode(prev => prev ? { ...prev, position: { ...prev.position, row: v } } : prev)} min={1} />
                        <NumberInput label={t('admin.techTrees.col')} value={editingNode.position.col} onChange={v => setEditingNode(prev => prev ? { ...prev, position: { ...prev.position, col: v } } : prev)} min={1} />
                      </div>
                    </div>
                  </FormSection>
                  {selectedTreeData && (selectedTreeData.nodes || []).length > 0 && (
                    <FormSection label={t('admin.techTrees.dependencies')}>
                      <MultiSelectDropdown
                        label={t('admin.techTrees.prerequisites')}
                        options={(selectedTreeData.nodes || [])
                          .filter(n => n.id !== editingNodeId)
                          .map(n => n.id)
                        }
                        selected={editingNode.prerequisites}
                        onChange={v => setEditingNode(prev => prev ? { ...prev, prerequisites: v } : prev)}
                        placeholder={t('admin.techTrees.selectPrerequisites')}
                      />
                    </FormSection>
                  )}
                  <div className="flex justify-end gap-2 pt-2">
                    <button
                      onClick={() => { setEditingNode(null); setEditingNodeId(null); setIsCreatingNode(false); }}
                      className="px-5 py-2 text-xs rounded-lg text-gray-400 hover:text-white transition-colors"
                      style={{ backgroundColor: '#252528' }}
                    >
                      {t('admin.common.cancel')}
                    </button>
                    <button
                      onClick={saveNodeForm}
                      className="px-5 py-2 text-xs rounded-lg text-white transition-colors hover:brightness-110"
                      style={{ backgroundColor: '#4ADE80' }}
                    >
                      {isCreatingNode ? t('admin.common.create') : t('admin.common.save')}
                    </button>
                  </div>
                </FormModal>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default AdminPanel;
