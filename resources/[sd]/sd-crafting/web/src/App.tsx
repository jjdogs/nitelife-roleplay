import { useState, useEffect, useCallback, useRef, memo, useMemo } from 'react';
import { Search, Filter, X, Package, DollarSign, AlertCircle } from 'lucide-react';
import { TranslationProvider } from './locales/TranslationProvider';
import { useTranslation } from './locales/i18n';
import AdminPanel from './AdminPanel';

interface IngredientRequirement {
  item: string;
  label: string;
  amount: number;
  image?: string;
}

interface ToolRequirement {
  item: string;
  label: string;
  amount: number;
  image?: string;
  consumptionType: 'none' | 'durability' | 'chance' | 'consume';
  durabilityLoss?: number;
  consumeChance?: number;
}

interface Recipe {
  id: string;
  name: string;
  label: string;
  craftTime: number;
  ingredients: IngredientRequirement[];
  tools?: ToolRequirement[];
  image?: string;
  category?: string;
  blueprint?: string;
  blueprintDurabilityLoss?: number;
  blueprintMissing?: boolean; // True if recipe is included only for tech tree display (blueprint not attached)
  levelRequired?: number;
  xpReward?: number;
  techPointsReward?: number;
  cost?: number;
  outputAmount?: number;
  failChance?: number; // Percentage chance (0-100) that crafting will fail
  metadata?: Record<string, unknown>; // Metadata to apply to crafted items
}

interface PlayerInventoryItem {
  item: string;
  label: string;
  count: number;
  slot?: number;
  image?: string;
  durability?: number;
}

interface QueueItem {
  id: string;
  recipe: Recipe;
  quantity: number;
  startTime: number;
  totalTime: number;
  remainingTime: number;
  owner?: number;
  ownerName?: string;
  isOwnItem?: boolean;
}

interface PlayerBlueprint {
  item: string;
  label: string;
  count: number;
  recipeId: string;
  recipeLabel: string;
}

interface AttachedBlueprint {
  item: string;
  label: string;
  recipeId: string;
  recipeLabel: string;
}

interface PlayerLevel {
  xp: number;
  level: number;
  enabled: boolean;
  maxLevel?: number;
  xpForNextLevel?: number;
  xpForCurrentLevel?: number;
}

interface CraftingInventoryConfig {
  enabled: boolean;
  perWorkbench: boolean;
  maxSlots: number;
  maxWeight: number;
  returnOnClose: boolean;
  blueprintDurabilityEnabled?: boolean;
  defaultDurabilityLoss?: number;
  defaultDurability?: number;
  toolsEnabled?: boolean;
  toolsDurabilityEnabled?: boolean;
  toolsDefaultDurability?: number;
  toolsDefaultLoss?: number;
}

interface StagedItem {
  item: string;
  label: string;
  count: number;
  image?: string;
  slot?: number;
  weight?: number;
  durability?: number;
}

interface TechTreeNode {
  id: string;
  recipeId: string;
  cost: number;
  prerequisites: string[];
  position: { row: number; col: number };
}

interface TechTree {
  label: string;
  icon: string;
  color: string;
  nodes: TechTreeNode[];
}

interface TechTreeConfig {
  enabled: boolean;
  trees?: { [treeId: string]: TechTree };
}

interface TechPointsData {
  points: number;
  enabled: boolean;
}

interface NUIMessage {
  action: string;
  recipes?: Recipe[];
  inventory?: PlayerInventoryItem[];
  filteredInventory?: PlayerInventoryItem[];
  queue?: QueueItem[];
  attachedBlueprints?: string[];
  attachedWithLabels?: AttachedBlueprint[];
  playerBlueprints?: PlayerBlueprint[];
  validBlueprintItems?: string[];
  playerLevel?: PlayerLevel;
  inventoryPanelEnabled?: boolean;
  showAllItems?: boolean;
  craftingInventoryConfig?: CraftingInventoryConfig;
  stagedItems?: StagedItem[];
  stagedWeight?: number;
  inventoryWeight?: number;
  inventoryMaxWeight?: number;
  totalSlots?: number;
  supportsSlots?: boolean;
  techPoints?: TechPointsData;
  unlockedNodes?: { [key: string]: boolean };
  techTreeConfig?: TechTreeConfig;
  locale?: string;
  toastMessage?: string;
  toastType?: 'error' | 'success' | 'info';
  // Permission system
  isPlacedWorkbench?: boolean;
  isWorkbenchOwner?: boolean;
  permissionsEnabled?: boolean;
  placedWorkbenchId?: number;
  // History system
  historyEnabled?: boolean;
  historyOwnerOnlyDelete?: boolean;
  historyDateFormat?: 'DMY' | 'MDY';
  history?: HistoryEntry[];
  // Shared crafting
  sharedCrafting?: boolean;
  // Queue completion animation
  itemId?: string;
  status?: 'success' | 'partial' | 'failure';
}

interface DragItem {
  type: 'inventory' | 'blueprint' | 'attached' | 'staged';
  item: string;
  data: PlayerInventoryItem | PlayerBlueprint | StagedItem | string;
  amount?: number;
  sourceSlot?: number;
}

interface ToastNotification {
  id: number;
  message: string;
  type: 'error' | 'success' | 'info';
  exiting?: boolean;
}

const getItemImage = (itemName: string, customImage?: string): string => {
  if (customImage) {
    // Plain filename (e.g. "lockpick.png") → resolve via inventory images path
    if (!customImage.includes('/') && !customImage.includes('\\') && !customImage.includes('://')) {
      return `nui://ox_inventory/web/images/${customImage}`;
    }
    return customImage;
  }
  return `nui://ox_inventory/web/images/${itemName}.png`;
};

interface ItemImageProps {
  src: string;
  alt: string;
  className?: string;
  fallbackClassName?: string;
  fallbackSvg?: string;
}

/**
 * Image component that handles loading errors gracefully with proper React state management.
 * Resets error state when src changes to ensure images reload correctly when switching recipes.
 */
const ItemImage = memo(({ src, alt, className = '', fallbackClassName = '', fallbackSvg }: ItemImageProps) => {
  const [hasError, setHasError] = useState(false);

  // Reset error state when src changes
  useEffect(() => {
    setHasError(false);
  }, [src]);

  if (hasError) {
    if (fallbackSvg) {
      return <img src={fallbackSvg} alt={alt} className={className} />;
    }
    return <Package className={fallbackClassName || className} />;
  }

  return (
    <img
      src={src}
      alt={alt}
      className={className}
      onError={() => setHasError(true)}
    />
  );
});

const isEnvBrowser = (): boolean => !(window as any).invokeNative;

const fetchNui = async <T = any>(eventName: string, data?: any): Promise<T> => {
  if (isEnvBrowser()) {
    return new Promise((resolve) => {
      setTimeout(() => resolve({} as T), 100);
    });
  }

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : 'sd-crafting';

  const resp = await fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });

  return resp.json();
};

type TabType = 'crafting' | 'blueprints' | 'techtree' | 'permissions' | 'history';

interface PermissionEntry {
  identifier: string;
  name: string;
}

interface HistoryIngredient {
  item: string;
  label: string;
  amount: number;
  image?: string;
}

interface HistoryEntry {
  identifier: string;
  player_name: string;
  recipe_id: string;
  recipe_name: string;
  quantity: number;
  output_item: string;
  output_label: string;
  output_amount: number;
  output_image?: string;
  ingredients: HistoryIngredient[];
  crafted_at: string;
}

const NoiseOverlay = memo(() => (
  <>
    <div className="absolute inset-0 pointer-events-none z-10"
      style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px',
        opacity: 0.08,
        mixBlendMode: 'soft-light'
      }}
    />
    <div className="absolute inset-0 pointer-events-none z-10"
      style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='grain'%3E%3CfeTurbulence type='turbulence' baseFrequency='0.7' numOctaves='3' stitchTiles='stitch'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23grain)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '100px 100px',
        opacity: 0.12
      }}
    />
  </>
));

const ItemSlotNoise = memo(() => (
  <div className="absolute inset-0 pointer-events-none rounded-lg overflow-hidden"
    style={{
      backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 128 128' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
      backgroundRepeat: 'repeat',
      backgroundSize: '64px 64px',
      opacity: 0.06,
      mixBlendMode: 'overlay'
    }}
  />
));

interface EmptySlotProps {
  slotIndex?: number;
  isDropTarget?: boolean;
  onSlotRef?: (index: number, el: HTMLDivElement | null) => void;
}

const EmptySlot = memo(({ slotIndex, isDropTarget, onSlotRef }: EmptySlotProps) => (
  <div
    ref={slotIndex !== undefined && onSlotRef ? (el) => onSlotRef(slotIndex, el) : undefined}
    data-slot={slotIndex}
    className={`relative rounded-lg overflow-hidden flex items-center justify-center transition-all duration-200 ${isDropTarget ? 'scale-105' : ''}`}
    style={{
      height: 'calc((4.167vw + 7.407vh) / 2)',
      backgroundColor: isDropTarget ? 'rgba(74, 222, 128, 0.15)' : 'rgba(26, 26, 31, 0.4)',
      border: isDropTarget ? '1px dashed rgba(74, 222, 128, 0.4)' : '1px dashed rgba(255, 255, 255, 0.08)',
    }}
  >
    <div
      className="w-8 h-8 rounded-md flex items-center justify-center transition-colors"
      style={{ backgroundColor: isDropTarget ? 'rgba(74, 222, 128, 0.1)' : 'rgba(255, 255, 255, 0.03)' }}
    >
      <svg className={`w-4 h-4 transition-colors ${isDropTarget ? 'text-green-400/40' : 'text-white/10'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 4v16m8-8H4" />
      </svg>
    </div>
  </div>
));

const formatWeight = (weight: number): string => {
  if (weight >= 1000) {
    return `${(weight / 1000).toFixed(1)}kg`;
  }
  return `${weight}g`;
};

interface LeftPanelProps {
  filteredInventory: PlayerInventoryItem[];
  attachedBlueprints: string[];
  attachedWithLabels: AttachedBlueprint[];
  playerBlueprints: PlayerBlueprint[];
  validBlueprintItems: string[];
  isBlueprint: (itemName: string | undefined | null) => boolean;
  stagedItems: StagedItem[];
  craftingInventoryConfig: CraftingInventoryConfig;
  draggedItem: DragItem | null;
  inventoryDragAmount: number;
  craftingDragAmount: number;
  onStartDrag: (item: DragItem, e: React.MouseEvent) => void;
  onInventoryDragAmountChange: (amount: number) => void;
  onCraftingDragAmountChange: (amount: number) => void;
  t: (key: string, params?: Record<string, any>) => string;
  inventoryRef: React.RefObject<HTMLDivElement>;
  craftingRef: React.RefObject<HTMLDivElement>;
  dropRipple: { x: number; y: number; key: number } | null;
  inventorySearchTerm: string;
  onInventorySearchChange: (term: string) => void;
  craftingSearchTerm: string;
  onCraftingSearchChange: (term: string) => void;
  onCraftingSlotRef: (index: number, el: HTMLDivElement | null) => void;
  hoveredCraftingSlot: number | null;
  inventoryWeight: number;
  stagedWeight: number;
  inventoryMaxWeight: number;
  recipes: Recipe[];
  totalSlots: number;
  supportsSlots: boolean;
  hoveredInventorySlot: number | null;
  onInventorySlotRef: (index: number, el: HTMLDivElement | null) => void;
}

const LeftPanel = memo(({
  filteredInventory,
  attachedBlueprints,
  attachedWithLabels,
  playerBlueprints,
  validBlueprintItems,
  isBlueprint,
  stagedItems,
  craftingInventoryConfig,
  draggedItem,
  inventoryDragAmount,
  craftingDragAmount,
  onStartDrag,
  onInventoryDragAmountChange,
  onCraftingDragAmountChange,
  t,
  inventoryRef,
  craftingRef,
  dropRipple,
  inventorySearchTerm,
  onInventorySearchChange,
  craftingSearchTerm,
  onCraftingSearchChange,
  onCraftingSlotRef,
  hoveredCraftingSlot,
  inventoryWeight,
  stagedWeight,
  inventoryMaxWeight,
  recipes,
  totalSlots,
  supportsSlots,
  hoveredInventorySlot,
  onInventorySlotRef,
}: LeftPanelProps) => {
  const isBlueprintUsable = useCallback((blueprintItem: string) => {
    // Check if any recipe uses this blueprint
    return recipes.some(r => r.blueprint === blueprintItem);
  }, [recipes]);

  const getBlueprintLabel = useCallback((blueprintItem: string) => {
    // First check if we have the actual label from the server
    const attachedData = attachedWithLabels.find(a => a.item === blueprintItem);
    if (attachedData?.label) {
      return attachedData.label;
    }
    // Fallback to finding recipe that uses this blueprint
    const recipe = recipes.find(r => r.blueprint === blueprintItem);
    if (recipe) {
      return `${recipe.label} ${t('blueprints.suffix')}`;
    }
    // Handle both underscores and camelCase in item names (no prefix assumption)
    const formatted = blueprintItem
      .replace(/_/g, ' ')
      .replace(/([a-z])([A-Z])/g, '$1 $2') // Insert space before capitals in camelCase
      .replace(/\b\w/g, l => l.toUpperCase());
    return `${formatted} ${t('blueprints.suffix')}`;
  }, [attachedWithLabels, recipes, t]);

  const stagedSlotMap = new Map<number, StagedItem>();
  const usedSlots = new Set<number>();

  stagedItems.forEach(item => {
    if (item.slot !== undefined) {
      stagedSlotMap.set(item.slot, item);
      usedSlots.add(item.slot);
    }
  });

  let nextAvailableSlot = 0;
  stagedItems.forEach(item => {
    if (item.slot === undefined) {
      while (usedSlots.has(nextAvailableSlot)) nextAvailableSlot++;
      stagedSlotMap.set(nextAvailableSlot, { ...item, slot: nextAvailableSlot });
      usedSlots.add(nextAvailableSlot);
      nextAvailableSlot++;
    }
  });

  const filteredAttachedBlueprints = attachedBlueprints.filter(bp =>
    bp.toLowerCase().includes(craftingSearchTerm.toLowerCase())
  );
  const filteredPlayerBlueprints = playerBlueprints.filter(bp =>
    bp.label.toLowerCase().includes(craftingSearchTerm.toLowerCase()) ||
    bp.item.toLowerCase().includes(craftingSearchTerm.toLowerCase())
  );

  const panelStyle = {
    background: 'rgba(12, 12, 14, 0.82)',
    border: '1px solid rgba(255,255,255,0.15)',
    boxShadow: '10px 0 40px rgba(0,0,0,0.5)'
  };

  const panelHeight = 'calc((100% - 12px) / 2)';

  const craftingPanelTitle = craftingInventoryConfig.enabled ? t('craftingInventory.stagedItems') : t('craftingInventory.blueprints');

  const craftingPanelTotal = craftingInventoryConfig.enabled
    ? stagedItems.length
    : attachedBlueprints.length + playerBlueprints.length;
  const craftingPanelLabel = craftingInventoryConfig.enabled
    ? `${craftingPanelTotal}/${craftingInventoryConfig.maxSlots} items`
    : `${craftingPanelTotal} blueprints`;

  const getItemBackground = (_itemName: string, isBlueprintItem: boolean, isDragging: boolean) => {
    if (isDragging) return '#2d4a2d';
    if (isBlueprintItem) return '#1e2a3a';
    return '#1a1a1f';
  };

  return (
    <div
      className="flex flex-col animate-slideInLeft"
      style={{
        width: 'calc((27.083vw + 48.148vh) / 2)',
        height: 'calc(100vh - calc((3.333vw + 5.926vh) / 2))',
        transform: 'rotateY(4deg)',
        transformOrigin: 'left center',
        gap: 'calc((0.625vw + 1.111vh) / 2)',
      }}
    >
      {/* Inventory Container - Top Half */}
      <div
        ref={inventoryRef}
        className={`rounded-xl overflow-hidden relative drop-zone ${draggedItem ? 'drop-zone-active' : ''}`}
        style={{ ...panelStyle, height: panelHeight }}
      >
        {/* Drop ripple effect */}
        {dropRipple && (
          <div
            key={dropRipple.key}
            className="drop-ripple"
            style={{
              left: dropRipple.x - 30,
              top: dropRipple.y - 30,
            }}
          />
        )}
        <NoiseOverlay />
        <div className="relative z-20 h-full flex flex-col">
          {/* Header with title and weight bar */}
          <div className="flex items-center justify-between flex-shrink-0" style={{ padding: 'calc((0.833vw + 1.481vh) / 2) calc((0.833vw + 1.481vh) / 2) calc((0.417vw + 0.741vh) / 2) calc((0.833vw + 1.481vh) / 2)' }}>
            <div className="flex items-center" style={{ gap: 'calc((0.417vw + 0.741vh) / 2)' }}>
              <span className="text-white font-semibold" style={{ fontSize: 'calc((0.729vw + 1.296vh) / 2)' }}>{t('inventory.title')}</span>
              <span className="text-gray-500" style={{ fontSize: 'calc((0.625vw + 1.111vh) / 2)' }}>{filteredInventory.length} {t('common.items')}</span>
            </div>
            {/* Weight bar - top right */}
            {inventoryMaxWeight > 0 && (
              <div className="flex items-center" style={{ gap: 'calc((0.313vw + 0.556vh) / 2)' }}>
                <svg className="text-gray-500" style={{ width: 'calc((0.729vw + 1.296vh) / 2)', height: 'calc((0.729vw + 1.296vh) / 2)' }} fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1.323l3.954 1.582 1.599-.8a1 1 0 01.894 1.79l-1.233.616 1.738 5.42a1 1 0 01-.285 1.05A3.989 3.989 0 0115 15a3.989 3.989 0 01-2.667-1.019 1 1 0 01-.285-1.05l1.715-5.349L11 6.477V16h2a1 1 0 110 2H7a1 1 0 110-2h2V6.477L6.237 7.582l1.715 5.349a1 1 0 01-.285 1.05A3.989 3.989 0 015 15a3.989 3.989 0 01-2.667-1.019 1 1 0 01-.285-1.05l1.738-5.42-1.233-.617a1 1 0 01.894-1.788l1.599.799L9 4.323V3a1 1 0 011-1z" clipRule="evenodd" />
                </svg>
                <span className={`${inventoryWeight >= inventoryMaxWeight ? 'text-red-400' : inventoryWeight >= inventoryMaxWeight * 0.8 ? 'text-yellow-400' : 'text-gray-400'}`} style={{ fontSize: 'calc((0.573vw + 1.019vh) / 2)' }}>
                  {formatWeight(inventoryWeight)}/{formatWeight(inventoryMaxWeight)}
                </span>
              </div>
            )}
          </div>
          {/* Search Bar */}
          <div className="border-b border-white/10 flex-shrink-0" style={{ padding: '0 calc((0.833vw + 1.481vh) / 2) calc((0.625vw + 1.111vh) / 2) calc((0.833vw + 1.481vh) / 2)' }}>
            <div className="relative">
              <input
                type="text"
                placeholder={t('inventory.searchPlaceholder')}
                value={inventorySearchTerm}
                onChange={(e) => onInventorySearchChange(e.target.value)}
                onClick={(e) => { e.stopPropagation(); (e.target as HTMLInputElement).focus(); }}
                onMouseDown={(e) => e.stopPropagation()}
                className="w-full bg-[#1a1a1f] rounded-lg pl-4 pr-10 py-2 text-white text-xs placeholder-gray-600 focus:outline-none border border-transparent focus:border-white/10"
              />
              {inventorySearchTerm ? (
                <button
                  onClick={() => onInventorySearchChange('')}
                  className="absolute right-3 top-1/2 -translate-y-1/2 p-0.5 hover:bg-white/10 rounded transition-colors z-10"
                >
                  <X className="w-3.5 h-3.5 text-gray-400 hover:text-white" />
                </button>
              ) : (
                <Search className="w-3.5 h-3.5 text-gray-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              )}
            </div>
          </div>
          <div className="flex-1 overflow-y-auto min-h-0" style={{ padding: 'calc((0.625vw + 1.111vh) / 2)' }}>
            <div className="grid grid-cols-5" style={{ gap: 'calc((0.417vw + 0.741vh) / 2)' }}>
              {supportsSlots && totalSlots > 0 ? (
                // Slot-based rendering - items appear in their actual inventory slots
                Array.from({ length: totalSlots }).map((_, slotIndex) => {
                  const slotNum = slotIndex + 1; // Slots are 1-indexed
                  const item = filteredInventory.find(i => i.slot === slotNum);

                  if (!item) {
                    // Show drop target for staged items being moved to this slot
                    const isDropTarget = !!(draggedItem && hoveredInventorySlot === slotNum && draggedItem.type === 'staged');
                    return (
                      <EmptySlot
                        key={`inv-slot-${slotNum}`}
                        slotIndex={slotNum}
                        isDropTarget={isDropTarget}
                        onSlotRef={onInventorySlotRef}
                      />
                    );
                  }

                  const matchesSearch = !inventorySearchTerm ||
                    item.label.toLowerCase().includes(inventorySearchTerm.toLowerCase()) ||
                    item.item.toLowerCase().includes(inventorySearchTerm.toLowerCase());

                  if (!matchesSearch) {
                    return (
                      <EmptySlot
                        key={`inv-slot-${slotNum}`}
                        slotIndex={slotNum}
                        onSlotRef={onInventorySlotRef}
                      />
                    );
                  }

                  const isBlueprintItem = isBlueprint(item.item);
                  const isDragging = draggedItem?.item === item.item && draggedItem?.sourceSlot === slotNum && draggedItem?.type !== 'staged';
                  return (
                    <div
                      key={`inv-slot-${slotNum}`}
                      ref={(el) => onInventorySlotRef(slotNum, el)}
                      className={`relative rounded-lg overflow-hidden flex flex-col items-center justify-center p-2 cursor-grab active:cursor-grabbing transition-all duration-200 hover:scale-105 hover:brightness-110 hover:z-10 ${isDragging ? 'opacity-50 scale-95' : ''}`}
                      style={{
                        height: 'calc((4.167vw + 7.407vh) / 2)',
                        backgroundColor: getItemBackground(item.item, isBlueprintItem, isDragging),
                        boxShadow: isDragging ? '0 0 12px rgba(74, 222, 128, 0.4)' : 'inset 0 1px 0 rgba(255,255,255,0.05)'
                      }}
                      onMouseDown={(e) => onStartDrag({
                        type: isBlueprintItem ? 'blueprint' : 'inventory',
                        item: item.item,
                        data: item,
                        amount: inventoryDragAmount === 0 ? item.count : Math.min(inventoryDragAmount, item.count),
                        sourceSlot: slotNum
                      }, e)}
                      data-slot={slotNum}
                    >
                      <ItemSlotNoise />
                      <div className="absolute top-1 right-1 flex items-center justify-center px-1 rounded font-bold bg-black/50 text-white z-10" style={{ minWidth: 'calc((0.938vw + 1.667vh) / 2)', height: 'calc((0.938vw + 1.667vh) / 2)', fontSize: 'calc((0.521vw + 0.926vh) / 2)' }}>
                        {item.count}
                      </div>
                      {isBlueprintItem && (
                        <div className="absolute top-1 left-1 w-4 h-4 flex items-center justify-center z-10">
                          <svg className="w-3 h-3 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                          </svg>
                        </div>
                      )}
                      <ItemImage
                        src={getItemImage(item.item, item.image)}
                        alt={item.item}
                        className="w-10 h-10 object-contain pointer-events-none relative z-10"
                        fallbackClassName="w-10 h-10 text-gray-600 pointer-events-none relative z-10"
                      />
                      <span className="text-gray-300 text-center leading-tight mt-1 line-clamp-1 w-full px-1 pointer-events-none relative z-10" style={{ fontSize: 'calc((0.469vw + 0.833vh) / 2)' }}>
                        {item.label}
                      </span>
                      {item.durability !== undefined && (
                        <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/50 z-20">
                          <div
                            className="h-full transition-all duration-300"
                            style={{
                              width: `${item.durability}%`,
                              backgroundColor: item.durability > 50 ? '#22c55e' : item.durability > 25 ? '#eab308' : '#ef4444'
                            }}
                          />
                        </div>
                      )}
                    </div>
                  );
                })
              ) : (
                // Legacy rendering - items appear in order (no slot info)
                <>
                  {filteredInventory.map((item, index) => {
                    const matchesSearch = !inventorySearchTerm ||
                      item.label.toLowerCase().includes(inventorySearchTerm.toLowerCase()) ||
                      item.item.toLowerCase().includes(inventorySearchTerm.toLowerCase());

                    if (!matchesSearch) {
                      return <EmptySlot key={`filtered-${item.item}-${index}`} />;
                    }

                    const isBlueprintItem = isBlueprint(item.item);
                    const isDragging = draggedItem?.item === item.item && draggedItem?.type !== 'staged';
                    return (
                      <div
                        key={item.item + index}
                        className={`relative rounded-lg overflow-hidden flex flex-col items-center justify-center p-2 cursor-grab active:cursor-grabbing transition-all duration-200 hover:scale-105 hover:brightness-110 hover:z-10 ${isDragging ? 'opacity-50 scale-95' : ''}`}
                        style={{
                          height: 'calc((4.167vw + 7.407vh) / 2)',
                          backgroundColor: getItemBackground(item.item, isBlueprintItem, isDragging),
                          boxShadow: isDragging ? '0 0 12px rgba(74, 222, 128, 0.4)' : 'inset 0 1px 0 rgba(255,255,255,0.05)'
                        }}
                        onMouseDown={(e) => onStartDrag({
                          type: isBlueprintItem ? 'blueprint' : 'inventory',
                          item: item.item,
                          data: item,
                          amount: inventoryDragAmount === 0 ? item.count : Math.min(inventoryDragAmount, item.count)
                        }, e)}
                      >
                        <ItemSlotNoise />
                        <div className="absolute top-1 right-1 flex items-center justify-center px-1 rounded font-bold bg-black/50 text-white z-10" style={{ minWidth: 'calc((0.938vw + 1.667vh) / 2)', height: 'calc((0.938vw + 1.667vh) / 2)', fontSize: 'calc((0.521vw + 0.926vh) / 2)' }}>
                          {item.count}
                        </div>
                        {isBlueprintItem && (
                          <div className="absolute top-1 left-1 w-4 h-4 flex items-center justify-center z-10">
                            <svg className="w-3 h-3 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                              <path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                            </svg>
                          </div>
                        )}
                        <ItemImage
                          src={getItemImage(item.item, item.image)}
                          alt={item.item}
                          className="w-10 h-10 object-contain pointer-events-none relative z-10"
                          fallbackClassName="w-10 h-10 text-gray-600 pointer-events-none relative z-10"
                        />
                        <span className="text-gray-300 text-center leading-tight mt-1 line-clamp-1 w-full px-1 pointer-events-none relative z-10" style={{ fontSize: 'calc((0.469vw + 0.833vh) / 2)' }}>
                          {item.label}
                        </span>
                        {item.durability !== undefined && (
                          <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/50 z-20">
                            <div
                              className="h-full transition-all duration-300"
                              style={{
                                width: `${item.durability}%`,
                                backgroundColor: item.durability > 50 ? '#22c55e' : item.durability > 25 ? '#eab308' : '#ef4444'
                              }}
                            />
                          </div>
                        )}
                      </div>
                    );
                  })}
                  {/* Empty slot placeholders - show 20 total slots */}
                  {Array.from({ length: Math.max(0, 20 - filteredInventory.length) }).map((_, index) => (
                    <EmptySlot key={`empty-inv-${index}`} />
                  ))}
                </>
              )}
            </div>
          </div>
          {/* Drag Amount Input */}
          <div className="px-3 py-2 border-t border-white/10 flex items-center gap-1.5 flex-shrink-0">
            <span className="text-gray-400 text-[10px]">{t('common.drag')}:</span>
            <div className="flex items-center">
              <div className="relative flex items-center">
                <input
                  type="number"
                  min="0"
                  max="999"
                  value={inventoryDragAmount}
                  onChange={(e) => onInventoryDragAmountChange(Math.max(0, Math.min(999, parseInt(e.target.value) || 0)))}
                  className="w-12 bg-[#1a1a1f] rounded-l px-1.5 py-1 text-white text-[10px] text-center focus:outline-none border border-white/10 focus:border-[#4ade80]/50 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                  placeholder="0"
                />
                <div className="flex flex-col border border-l-0 border-white/10 rounded-r overflow-hidden">
                  <button
                    onClick={() => onInventoryDragAmountChange(Math.min(999, inventoryDragAmount + 1))}
                    className="px-1 py-0.5 bg-[#1a1a1f] hover:bg-[#2a2a2f] text-gray-400 hover:text-white transition-colors"
                  >
                    <svg className="w-2 h-2" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clipRule="evenodd" /></svg>
                  </button>
                  <button
                    onClick={() => onInventoryDragAmountChange(Math.max(0, inventoryDragAmount - 1))}
                    className="px-1 py-0.5 bg-[#1a1a1f] hover:bg-[#2a2a2f] text-gray-400 hover:text-white transition-colors border-t border-white/10"
                  >
                    <svg className="w-2 h-2" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" /></svg>
                  </button>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-0.5 ml-1">
              {[-50, -10, -5].map((val) => (
                <button
                  key={val}
                  onClick={() => onInventoryDragAmountChange(Math.max(0, inventoryDragAmount + val))}
                  className="px-1 py-0.5 text-[9px] bg-[#1a1a1f] hover:bg-red-500/20 text-red-400 hover:text-red-300 rounded border border-white/10 hover:border-red-500/30 transition-colors"
                >
                  {val}
                </button>
              ))}
              {[5, 10, 50].map((val) => (
                <button
                  key={val}
                  onClick={() => onInventoryDragAmountChange(Math.min(999, inventoryDragAmount + val))}
                  className="px-1 py-0.5 text-[9px] bg-[#1a1a1f] hover:bg-[#4ade80]/20 text-[#4ade80] hover:text-[#6ee7a0] rounded border border-white/10 hover:border-[#4ade80]/30 transition-colors"
                >
                  +{val}
                </button>
              ))}
            </div>
            <span className="text-gray-500 text-[9px] ml-1">(0=all)</span>
          </div>
        </div>
      </div>

      {/* Crafting Inventory - Bottom Half */}
      <div
        ref={craftingRef}
        className={`rounded-xl overflow-hidden relative drop-zone ${draggedItem ? 'drop-zone-active' : ''}`}
        style={{ ...panelStyle, height: panelHeight }}
      >
        {/* Drop ripple effect */}
        {dropRipple && (
          <div
            key={dropRipple.key}
            className="drop-ripple"
            style={{
              left: dropRipple.x - 30,
              top: dropRipple.y - 30,
            }}
          />
        )}
        <NoiseOverlay />
        <div className="relative z-20 h-full flex flex-col">
          {/* Header with title and weight bar */}
          <div className="flex items-center justify-between flex-shrink-0" style={{ padding: 'calc((0.833vw + 1.481vh) / 2) calc((0.833vw + 1.481vh) / 2) calc((0.417vw + 0.741vh) / 2) calc((0.833vw + 1.481vh) / 2)' }}>
            <div className="flex items-center" style={{ gap: 'calc((0.417vw + 0.741vh) / 2)' }}>
              <span className="text-white font-semibold" style={{ fontSize: 'calc((0.729vw + 1.296vh) / 2)' }}>{craftingPanelTitle}</span>
              <span className="text-gray-500" style={{ fontSize: 'calc((0.625vw + 1.111vh) / 2)' }}>{craftingPanelLabel}</span>
            </div>
            {/* Weight bar - top right (only for staging mode) */}
            {craftingInventoryConfig.enabled && craftingInventoryConfig.maxWeight > 0 && (
              <div className="flex items-center" style={{ gap: 'calc((0.313vw + 0.556vh) / 2)' }}>
                <svg className="text-gray-500" style={{ width: 'calc((0.729vw + 1.296vh) / 2)', height: 'calc((0.729vw + 1.296vh) / 2)' }} fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1.323l3.954 1.582 1.599-.8a1 1 0 01.894 1.79l-1.233.616 1.738 5.42a1 1 0 01-.285 1.05A3.989 3.989 0 0115 15a3.989 3.989 0 01-2.667-1.019 1 1 0 01-.285-1.05l1.715-5.349L11 6.477V16h2a1 1 0 110 2H7a1 1 0 110-2h2V6.477L6.237 7.582l1.715 5.349a1 1 0 01-.285 1.05A3.989 3.989 0 015 15a3.989 3.989 0 01-2.667-1.019 1 1 0 01-.285-1.05l1.738-5.42-1.233-.617a1 1 0 01.894-1.788l1.599.799L9 4.323V3a1 1 0 011-1z" clipRule="evenodd" />
                </svg>
                <span className={`${stagedWeight >= craftingInventoryConfig.maxWeight ? 'text-red-400' : stagedWeight >= craftingInventoryConfig.maxWeight * 0.8 ? 'text-yellow-400' : 'text-gray-400'}`} style={{ fontSize: 'calc((0.573vw + 1.019vh) / 2)' }}>
                  {formatWeight(stagedWeight)}/{formatWeight(craftingInventoryConfig.maxWeight)}
                </span>
              </div>
            )}
          </div>
          {/* Search Bar */}
          <div className="border-b border-white/10 flex-shrink-0" style={{ padding: '0 calc((0.833vw + 1.481vh) / 2) calc((0.625vw + 1.111vh) / 2) calc((0.833vw + 1.481vh) / 2)' }}>
            <div className="relative">
              <input
                type="text"
                placeholder={craftingInventoryConfig.enabled ? t('craftingInventory.searchStagedPlaceholder') : t('craftingInventory.searchBlueprintsPlaceholder')}
                value={craftingSearchTerm}
                onChange={(e) => onCraftingSearchChange(e.target.value)}
                onClick={(e) => { e.stopPropagation(); (e.target as HTMLInputElement).focus(); }}
                onMouseDown={(e) => e.stopPropagation()}
                className="w-full bg-[#1a1a1f] rounded-lg pl-4 pr-10 py-2 text-white text-xs placeholder-gray-600 focus:outline-none border border-transparent focus:border-white/10"
              />
              {craftingSearchTerm ? (
                <button
                  onClick={() => onCraftingSearchChange('')}
                  className="absolute right-3 top-1/2 -translate-y-1/2 p-0.5 hover:bg-white/10 rounded transition-colors z-10"
                >
                  <X className="w-3.5 h-3.5 text-gray-400 hover:text-white" />
                </button>
              ) : (
                <Search className="w-3.5 h-3.5 text-gray-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              )}
            </div>
          </div>
          <div className="flex-1 overflow-y-auto min-h-0" style={{ padding: 'calc((0.625vw + 1.111vh) / 2)' }}>
            <div className="grid grid-cols-5" style={{ gap: 'calc((0.417vw + 0.741vh) / 2)' }}>
              {/* Show staged items if staging is enabled - slot-based rendering */}
              {craftingInventoryConfig.enabled ? (
                <>
                  {Array.from({ length: craftingInventoryConfig.maxSlots }).map((_, slotIndex) => {
                    const item = stagedSlotMap.get(slotIndex);

                    if (!item) {
                      const isHovered = hoveredCraftingSlot === slotIndex && draggedItem !== null;
                      return (
                        <EmptySlot
                          key={`slot-${slotIndex}`}
                          slotIndex={slotIndex}
                          isDropTarget={isHovered}
                          onSlotRef={onCraftingSlotRef}
                        />
                      );
                    }

                    const matchesSearch = !craftingSearchTerm ||
                      item.label.toLowerCase().includes(craftingSearchTerm.toLowerCase()) ||
                      item.item.toLowerCase().includes(craftingSearchTerm.toLowerCase());

                    if (!matchesSearch) {
                      return (
                        <EmptySlot
                          key={`slot-${slotIndex}`}
                          slotIndex={slotIndex}
                          onSlotRef={onCraftingSlotRef}
                        />
                      );
                    }

                    const isBlueprint = validBlueprintItems.includes(item.item);
                    const isDragging = draggedItem?.item === item.item && draggedItem?.type === 'staged' && draggedItem?.sourceSlot === slotIndex;

                    return (
                      <div
                        key={`slot-${slotIndex}`}
                        ref={(el) => onCraftingSlotRef(slotIndex, el)}
                        data-slot={slotIndex}
                        className={`relative rounded-lg overflow-hidden flex flex-col items-center justify-center p-2 cursor-grab active:cursor-grabbing transition-all duration-200 hover:scale-105 hover:brightness-110 hover:z-10 ${isDragging ? 'opacity-50 scale-95' : ''}`}
                        style={{
                          height: 'calc((4.167vw + 7.407vh) / 2)',
                          backgroundColor: getItemBackground(item.item, isBlueprint, isDragging),
                          boxShadow: isDragging ? '0 0 12px rgba(74, 222, 128, 0.4)' : 'inset 0 1px 0 rgba(255,255,255,0.05)'
                        }}
                        onMouseDown={(e) => onStartDrag({
                          type: 'staged',
                          item: item.item,
                          data: item,
                          amount: craftingDragAmount === 0 ? item.count : Math.min(craftingDragAmount, item.count),
                          sourceSlot: slotIndex
                        }, e)}
                      >
                        {/* Noise texture overlay */}
                        <ItemSlotNoise />
                        {/* Count Badge - Top Right */}
                        <div className="absolute top-1 right-1 flex items-center justify-center px-1 rounded font-bold bg-black/50 text-white z-10" style={{ minWidth: 'calc((0.938vw + 1.667vh) / 2)', height: 'calc((0.938vw + 1.667vh) / 2)', fontSize: 'calc((0.521vw + 0.926vh) / 2)' }}>
                          {item.count}
                        </div>
                        {/* Blueprint indicator */}
                        {isBlueprint && (
                          <div className="absolute top-1 left-1 w-4 h-4 flex items-center justify-center z-10">
                            <svg className="w-3 h-3 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                              <path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                            </svg>
                          </div>
                        )}
                        <ItemImage
                          src={getItemImage(item.item, item.image)}
                          alt={item.item}
                          className="w-10 h-10 object-contain pointer-events-none relative z-10"
                          fallbackClassName="w-10 h-10 text-gray-600 pointer-events-none relative z-10"
                        />
                        <span className="text-gray-300 text-center leading-tight mt-1 line-clamp-1 w-full px-1 pointer-events-none relative z-10" style={{ fontSize: 'calc((0.469vw + 0.833vh) / 2)' }}>
                          {item.label}
                        </span>
                        {/* Durability bar for blueprints */}
                        {item.durability !== undefined && (
                          <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/50 z-20">
                            <div
                              className="h-full transition-all duration-300"
                              style={{
                                width: `${item.durability}%`,
                                backgroundColor: item.durability > 50 ? '#22c55e' : item.durability > 25 ? '#eab308' : '#ef4444'
                              }}
                            />
                          </div>
                        )}
                      </div>
                    );
                  })}
                </>
              ) : (
                <>
                  {/* Blueprint-only mode: show attached blueprints first */}
                  {attachedBlueprints.map((bp, index) => {
                    const matchesSearch = !craftingSearchTerm ||
                      bp.toLowerCase().includes(craftingSearchTerm.toLowerCase());

                    if (!matchesSearch) {
                      return <EmptySlot key={`attached-${bp}-${index}`} />;
                    }

                    const isDragging = draggedItem?.item === bp;
                    const isUsable = isBlueprintUsable(bp);
                    return (
                      <div
                        key={bp + index}
                        className={`relative rounded-lg overflow-hidden flex flex-col items-center justify-center p-2 cursor-grab active:cursor-grabbing transition-all duration-200 hover:scale-105 hover:brightness-110 hover:z-10 ${isDragging ? 'opacity-50 scale-95' : ''}`}
                        style={{
                          height: 'calc((4.167vw + 7.407vh) / 2)',
                          backgroundColor: isUsable ? '#2d4a2d' : '#4a2d2d', // Green for active, red for unavailable
                          boxShadow: isDragging ? '0 0 12px rgba(74, 222, 128, 0.4)' : 'inset 0 1px 0 rgba(255,255,255,0.05)'
                        }}
                        onMouseDown={(e) => onStartDrag({ type: 'attached', item: bp, data: bp }, e)}
                        title={isUsable ? undefined : t('blueprints.unavailableOnWorkbench')}
                      >
                        {/* Noise texture overlay */}
                        <ItemSlotNoise />
                        {/* Status indicator */}
                        <div className="absolute top-1 left-1 w-4 h-4 flex items-center justify-center z-10">
                          {isUsable ? (
                            <div className="w-2 h-2 bg-green-400 rounded-full" />
                          ) : (
                            <AlertCircle className="w-3 h-3 text-red-400" />
                          )}
                        </div>
                        <ItemImage
                          src={getItemImage(bp)}
                          alt={bp}
                          className={`w-10 h-10 object-contain pointer-events-none relative z-10 ${isUsable ? '' : 'opacity-50'}`}
                          fallbackSvg="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%234ade80'><path d='M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'/></svg>"
                        />
                        <span className={`text-center leading-tight mt-1 line-clamp-1 w-full px-1 pointer-events-none relative z-10 ${isUsable ? 'text-gray-300' : 'text-red-300'}`} style={{ fontSize: 'calc((0.469vw + 0.833vh) / 2)' }}>
                          {getBlueprintLabel(bp)}
                        </span>
                      </div>
                    );
                  })}
                  {/* Player blueprints (only in blueprint mode) */}
                  {playerBlueprints.map((blueprint, index) => {
                    const matchesSearch = !craftingSearchTerm ||
                      blueprint.label.toLowerCase().includes(craftingSearchTerm.toLowerCase()) ||
                      blueprint.item.toLowerCase().includes(craftingSearchTerm.toLowerCase());

                    if (!matchesSearch) {
                      return <EmptySlot key={`player-${blueprint.item}-${index}`} />;
                    }

                    const isDragging = draggedItem?.item === blueprint.item;
                    return (
                      <div
                        key={blueprint.item + index}
                        className={`relative rounded-lg overflow-hidden flex flex-col items-center justify-center p-2 cursor-grab active:cursor-grabbing transition-all duration-200 hover:scale-105 hover:brightness-110 hover:z-10 ${isDragging ? 'opacity-50 scale-95' : ''}`}
                        style={{
                          height: 'calc((4.167vw + 7.407vh) / 2)',
                          backgroundColor: '#1e2a3a', // Blue for unattached blueprints
                          boxShadow: isDragging ? '0 0 12px rgba(74, 222, 128, 0.4)' : 'inset 0 1px 0 rgba(255,255,255,0.05)'
                        }}
                        onMouseDown={(e) => onStartDrag({ type: 'blueprint', item: blueprint.item, data: blueprint }, e)}
                      >
                        {/* Noise texture overlay */}
                        <ItemSlotNoise />
                        {/* Count Badge - Top Right */}
                        <div className="absolute top-1 right-1 flex items-center justify-center px-1 rounded font-bold bg-black/50 text-white z-10" style={{ minWidth: 'calc((0.938vw + 1.667vh) / 2)', height: 'calc((0.938vw + 1.667vh) / 2)', fontSize: 'calc((0.521vw + 0.926vh) / 2)' }}>
                          {blueprint.count}
                        </div>
                        <ItemImage
                          src={getItemImage(blueprint.item)}
                          alt={blueprint.item}
                          className="w-10 h-10 object-contain pointer-events-none relative z-10"
                          fallbackSvg="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23666'><path d='M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'/></svg>"
                        />
                        <span className="text-gray-300 text-center leading-tight mt-1 line-clamp-1 w-full px-1 pointer-events-none relative z-10" style={{ fontSize: 'calc((0.469vw + 0.833vh) / 2)' }}>
                          {blueprint.label}
                        </span>
                      </div>
                    );
                  })}
                  {/* Empty slot placeholders - show up to 20 slots */}
                  {Array.from({ length: Math.max(0, 20 - (attachedBlueprints.length + playerBlueprints.length)) }).map((_, index) => (
                    <EmptySlot key={`empty-bp-${index}`} />
                  ))}
                  {filteredAttachedBlueprints.length === 0 && filteredPlayerBlueprints.length === 0 && craftingSearchTerm && (
                    <div className="col-span-5 text-center py-4 text-gray-500 text-xs absolute inset-0 flex items-center justify-center">
                      {t('craftingInventory.noBlueprintsMatch')}
                    </div>
                  )}
                </>
              )}
            </div>
          </div>
          {/* Drag Amount Input */}
          <div className="px-3 py-2 border-t border-white/10 flex items-center gap-1.5 flex-shrink-0">
            <span className="text-gray-400 text-[10px]">{t('common.drag')}:</span>
            <div className="flex items-center">
              <div className="relative flex items-center">
                <input
                  type="number"
                  min="0"
                  max="999"
                  value={craftingDragAmount}
                  onChange={(e) => onCraftingDragAmountChange(Math.max(0, Math.min(999, parseInt(e.target.value) || 0)))}
                  className="w-12 bg-[#1a1a1f] rounded-l px-1.5 py-1 text-white text-[10px] text-center focus:outline-none border border-white/10 focus:border-[#4ade80]/50 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                  placeholder="0"
                />
                <div className="flex flex-col border border-l-0 border-white/10 rounded-r overflow-hidden">
                  <button
                    onClick={() => onCraftingDragAmountChange(Math.min(999, craftingDragAmount + 1))}
                    className="px-1 py-0.5 bg-[#1a1a1f] hover:bg-[#2a2a2f] text-gray-400 hover:text-white transition-colors"
                  >
                    <svg className="w-2 h-2" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clipRule="evenodd" /></svg>
                  </button>
                  <button
                    onClick={() => onCraftingDragAmountChange(Math.max(0, craftingDragAmount - 1))}
                    className="px-1 py-0.5 bg-[#1a1a1f] hover:bg-[#2a2a2f] text-gray-400 hover:text-white transition-colors border-t border-white/10"
                  >
                    <svg className="w-2 h-2" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" /></svg>
                  </button>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-0.5 ml-1">
              {[-50, -10, -5].map((val) => (
                <button
                  key={val}
                  onClick={() => onCraftingDragAmountChange(Math.max(0, craftingDragAmount + val))}
                  className="px-1 py-0.5 text-[9px] bg-[#1a1a1f] hover:bg-red-500/20 text-red-400 hover:text-red-300 rounded border border-white/10 hover:border-red-500/30 transition-colors"
                >
                  {val}
                </button>
              ))}
              {[5, 10, 50].map((val) => (
                <button
                  key={val}
                  onClick={() => onCraftingDragAmountChange(Math.min(999, craftingDragAmount + val))}
                  className="px-1 py-0.5 text-[9px] bg-[#1a1a1f] hover:bg-[#4ade80]/20 text-[#4ade80] hover:text-[#6ee7a0] rounded border border-white/10 hover:border-[#4ade80]/30 transition-colors"
                >
                  +{val}
                </button>
              ))}
            </div>
            <span className="text-gray-500 text-[9px] ml-1">(0=all)</span>
          </div>
        </div>
      </div>
    </div>
  );
});

const TranslatedContent: React.FC<{ children: (t: (key: string, params?: Record<string, any>) => string) => React.ReactNode }> = ({ children }) => {
  const { t } = useTranslation();
  return <>{children(t)}</>;
};

function App() {
  const [isVisible, setIsVisible] = useState(false);
  const [isAdminOpen, setIsAdminOpen] = useState(false);
  const [isAdminHidden, setIsAdminHidden] = useState(false);
  const [activeTab, setActiveTab] = useState<TabType>('crafting');
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [inventory, setInventory] = useState<PlayerInventoryItem[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe | null>(null);
  const [craftQuantity, setCraftQuantity] = useState(1);
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [completingItems, setCompletingItems] = useState<Map<string, { status: 'success' | 'partial' | 'failure', animating: boolean }>>(new Map());
  const [showFilterMenu, setShowFilterMenu] = useState(false);
  const [categoryFilter, setCategoryFilter] = useState<string | null>(null);
  const [attachedBlueprints, setAttachedBlueprints] = useState<string[]>([]);
  const [attachedWithLabels, setAttachedWithLabels] = useState<AttachedBlueprint[]>([]);
  const [playerBlueprints, setPlayerBlueprints] = useState<PlayerBlueprint[]>([]);
  const [validBlueprintItems, setValidBlueprintItems] = useState<string[]>([]);
  const [blueprintSearchTerm, setBlueprintSearchTerm] = useState('');
  const [playerLevel, setPlayerLevel] = useState<PlayerLevel>({ xp: 0, level: 1, enabled: false });
  const [inventoryPanelEnabled, setInventoryPanelEnabled] = useState(false);
  const [filteredInventory, setFilteredInventory] = useState<PlayerInventoryItem[]>([]);
  const [stagedItems, setStagedItems] = useState<StagedItem[]>([]);
  const [craftingInventoryConfig, setCraftingInventoryConfig] = useState<CraftingInventoryConfig>({
    enabled: false,
    perWorkbench: false,
    maxSlots: 20,
    maxWeight: 0,
    returnOnClose: false
  });
  const [stagedWeight, setStagedWeight] = useState(0);
  const [inventoryWeight, setInventoryWeight] = useState(0);
  const [inventoryMaxWeight, setInventoryMaxWeight] = useState(120000);
  const [totalSlots, setTotalSlots] = useState(0);
  const [supportsSlots, setSupportsSlots] = useState(false);
  const [hoveredInventorySlot, setHoveredInventorySlot] = useState<number | null>(null);
  const [inventoryDragAmount, setInventoryDragAmount] = useState(0);
  const [craftingDragAmount, setCraftingDragAmount] = useState(0);
  const [inventorySearchTerm, setInventorySearchTerm] = useState('');
  const [craftingSearchTerm, setCraftingSearchTerm] = useState('');
  const [locale, setLocale] = useState('en');
  const [draggedItem, setDraggedItem] = useState<DragItem | null>(null);
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [dropRipple, setDropRipple] = useState<{ x: number; y: number; key: number } | null>(null);
  const [hoveredCraftingSlot, setHoveredCraftingSlot] = useState<number | null>(null);
  const queueTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const inventoryDropRef = useRef<HTMLDivElement>(null);
  const craftingDropRef = useRef<HTMLDivElement>(null);
  const ghostRef = useRef<HTMLDivElement>(null);
  const craftingSlotRefs = useRef<Map<number, HTMLDivElement>>(new Map());
  const inventorySlotRefs = useRef<Map<number, HTMLDivElement>>(new Map());

  const [techPoints, setTechPoints] = useState<TechPointsData>({ points: 0, enabled: false });
  const [unlockedNodes, setUnlockedNodes] = useState<{ [key: string]: boolean }>({});
  const [techTreeConfig, setTechTreeConfig] = useState<TechTreeConfig>({ enabled: false });
  const [selectedTree, setSelectedTree] = useState<string | null>(null);
  const [selectedNode, setSelectedNode] = useState<TechTreeNode | null>(null);

  const [techTreePan, setTechTreePan] = useState({ x: 0, y: 0 });
  const [techTreeZoom, setTechTreeZoom] = useState(1);
  const [isPanningTechTree, setIsPanningTechTree] = useState(false);
  const [panStart, setPanStart] = useState({ x: 0, y: 0 });
  const techTreeContainerRef = useRef<HTMLDivElement | null>(null);
  const techTreeWheelCleanup = useRef<(() => void) | null>(null);

  const techTreeRefCallback = useCallback((node: HTMLDivElement | null) => {
    if (techTreeWheelCleanup.current) {
      techTreeWheelCleanup.current();
      techTreeWheelCleanup.current = null;
    }
    techTreeContainerRef.current = node;
    if (node) {
      const onWheel = (e: WheelEvent) => {
        e.preventDefault();
        const delta = e.deltaY > 0 ? -0.1 : 0.1;
        setTechTreeZoom(z => Math.max(0.4, Math.min(1.5, z + delta)));
      };
      node.addEventListener('wheel', onWheel, { passive: false });
      techTreeWheelCleanup.current = () => node.removeEventListener('wheel', onWheel);
    }
  }, []);

  // Permission system state
  const [permissions, setPermissions] = useState<PermissionEntry[]>([]);
  const [isWorkbenchOwner, setIsWorkbenchOwner] = useState(false);
  const [isPlacedWorkbench, setIsPlacedWorkbench] = useState(false);
  const [permissionsEnabled, setPermissionsEnabled] = useState(false);
  const [sourceInput, setSourceInput] = useState('');

  // History system state
  const [historyEnabled, setHistoryEnabled] = useState(false);
  const [historyOwnerOnlyDelete, setHistoryOwnerOnlyDelete] = useState(true);
  const [historyDateFormat, setHistoryDateFormat] = useState<'DMY' | 'MDY'>('DMY');
  const [history, setHistory] = useState<HistoryEntry[]>([]);

  // Shared crafting state
  const [sharedCrafting, setSharedCrafting] = useState(false);

  const [toasts, setToasts] = useState<ToastNotification[]>([]);
  const toastIdRef = useRef(0);
  const MAX_TOASTS = 5;

  // Memoized Set for O(1) blueprint lookups
  const blueprintItemsSet = useMemo(() => new Set(validBlueprintItems), [validBlueprintItems]);

  // Check if an item is a blueprint (based on recipes, not name prefix)
  const isBlueprint = useCallback((itemName: string | undefined | null): boolean => {
    if (!itemName) return false;
    return blueprintItemsSet.has(itemName);
  }, [blueprintItemsSet]);

  const showToast = useCallback((message: string, type: 'error' | 'success' | 'info' = 'error') => {
    const id = ++toastIdRef.current;

    setToasts(prev => {
      let newToasts = [...prev];

      // If we're at max capacity, remove the oldest non-exiting toast
      while (newToasts.filter(t => !t.exiting).length >= MAX_TOASTS) {
        const oldestIndex = newToasts.findIndex(t => !t.exiting);
        if (oldestIndex !== -1) {
          newToasts[oldestIndex] = { ...newToasts[oldestIndex], exiting: true };
          // Schedule removal of the exiting toast
          const oldestId = newToasts[oldestIndex].id;
          setTimeout(() => {
            setToasts(current => current.filter(t => t.id !== oldestId));
          }, 300);
        }
      }

      return [...newToasts, { id, message, type, exiting: false }];
    });

    // Auto-remove after 3 seconds
    setTimeout(() => {
      setToasts(prev => prev.map(t => t.id === id ? { ...t, exiting: true } : t));
      setTimeout(() => {
        setToasts(prev => prev.filter(t => t.id !== id));
      }, 300);
    }, 3000);
  }, []);

  const handleCraftingSlotRef = useCallback((index: number, el: HTMLDivElement | null) => {
    if (el) {
      craftingSlotRefs.current.set(index, el);
    } else {
      craftingSlotRefs.current.delete(index);
    }
  }, []);

  const handleInventorySlotRef = useCallback((index: number, el: HTMLDivElement | null) => {
    if (el) {
      inventorySlotRefs.current.set(index, el);
    } else {
      inventorySlotRefs.current.delete(index);
    }
  }, []);

  const getInventoryCount = useCallback((itemName: string): number => {
    // Sum all stacks of the same item (items can be in multiple slots)
    return inventory
      .filter(i => i.item === itemName)
      .reduce((sum, item) => sum + (item.count || 0), 0);
  }, [inventory]);

  const getStagedCount = useCallback((itemName: string): number => {
    // Sum all stacks of the same item (items can be in multiple slots)
    return stagedItems
      .filter(i => i.item === itemName)
      .reduce((sum, item) => sum + (item.count || 0), 0);
  }, [stagedItems]);

  const meetsLevelRequirement = useCallback((recipe: Recipe): boolean => {
    if (!playerLevel.enabled || !recipe.levelRequired) return true;
    return playerLevel.level >= recipe.levelRequired;
  }, [playerLevel]);

  const isTechTreeLocked = useCallback((recipe: Recipe): boolean => {
    if (!techTreeConfig.enabled || !techTreeConfig.trees) return false;
    for (const [treeId, tree] of Object.entries(techTreeConfig.trees)) {
      const node = tree.nodes.find(n => n.recipeId === recipe.id);
      if (node && !unlockedNodes[`${treeId}:${node.id}`]) {
        return true; // Recipe requires tech tree unlock but isn't unlocked
      }
    }
    return false;
  }, [techTreeConfig, unlockedNodes]);

  const canCraft = useCallback((recipe: Recipe, quantity: number = 1): boolean => {
    if (quantity < 1) return false;
    if (!meetsLevelRequirement(recipe)) return false;
    if (isTechTreeLocked(recipe)) return false;
    const getCount = craftingInventoryConfig.enabled ? getStagedCount : getInventoryCount;
    return recipe.ingredients.every(ing =>
      getCount(ing.item) >= ing.amount * quantity
    );
  }, [getInventoryCount, getStagedCount, meetsLevelRequirement, craftingInventoryConfig.enabled, isTechTreeLocked]);

  const getMaxCraftable = useCallback((recipe: Recipe): number => {
    if (recipe.ingredients.length === 0) return 99;
    let maxQuantity = Infinity;
    const getCount = craftingInventoryConfig.enabled ? getStagedCount : getInventoryCount;
    for (const ing of recipe.ingredients) {
      const playerHas = getCount(ing.item);
      const canMake = Math.floor(playerHas / ing.amount);
      maxQuantity = Math.min(maxQuantity, canMake);
    }

    // Limit by blueprint durability if applicable
    if (recipe.blueprint && craftingInventoryConfig.blueprintDurabilityEnabled) {
      const durabilityLoss = recipe.blueprintDurabilityLoss || craftingInventoryConfig.defaultDurabilityLoss || 10;

      // Find blueprint in staged items
      const stagedBlueprint = stagedItems.find(item => item.item === recipe.blueprint);
      if (stagedBlueprint && stagedBlueprint.durability !== undefined) {
        const maxFromDurability = Math.floor(stagedBlueprint.durability / durabilityLoss);
        maxQuantity = Math.min(maxQuantity, maxFromDurability);
      }
    }

    // Limit by tool durability if applicable
    if (recipe.tools && recipe.tools.length > 0 && craftingInventoryConfig.toolsDurabilityEnabled) {
      for (const tool of recipe.tools) {
        if (tool.consumptionType !== 'durability') continue;

        const durabilityLoss = tool.durabilityLoss || craftingInventoryConfig.toolsDefaultLoss || 10;
        const defaultDurability = craftingInventoryConfig.toolsDefaultDurability || 100;

        // Find all staged items of this tool type and sum their durability
        const stagedToolItems = stagedItems.filter(item => item.item === tool.item);
        if (stagedToolItems.length > 0) {
          let totalDurability = 0;
          for (const stagedTool of stagedToolItems) {
            const itemDurability = stagedTool.durability ?? defaultDurability;
            const itemCount = stagedTool.count || 1;
            totalDurability += itemDurability * itemCount;
          }
          const maxFromToolDurability = Math.floor(totalDurability / durabilityLoss);
          maxQuantity = Math.min(maxQuantity, maxFromToolDurability);
        }
      }
    }

    return Math.min(maxQuantity, 99);
  }, [getInventoryCount, getStagedCount, craftingInventoryConfig.enabled, craftingInventoryConfig.blueprintDurabilityEnabled, craftingInventoryConfig.defaultDurabilityLoss, craftingInventoryConfig.toolsDurabilityEnabled, craftingInventoryConfig.toolsDefaultLoss, craftingInventoryConfig.toolsDefaultDurability, stagedItems]);

  const getBlueprintDurabilityLimit = useCallback((recipe: Recipe): { limited: boolean; maxCrafts: number; durability: number; queuedCrafts: number } | null => {
    if (!recipe.blueprint || !craftingInventoryConfig.blueprintDurabilityEnabled) return null;

    const durabilityLoss = recipe.blueprintDurabilityLoss || craftingInventoryConfig.defaultDurabilityLoss || 10;
    const stagedBlueprint = stagedItems.find(item => item.item === recipe.blueprint);

    if (stagedBlueprint && stagedBlueprint.durability !== undefined) {
      // Calculate how many crafts are already queued using the same blueprint
      const queuedCrafts = queue
        .filter(q => q.recipe.blueprint === recipe.blueprint)
        .reduce((sum, q) => sum + q.quantity, 0);

      // Calculate max from durability, accounting for queued items
      const totalMaxFromDurability = Math.floor(stagedBlueprint.durability / durabilityLoss);
      const remainingMaxCrafts = Math.max(0, totalMaxFromDurability - queuedCrafts);

      return {
        limited: remainingMaxCrafts < 99,
        maxCrafts: remainingMaxCrafts,
        durability: stagedBlueprint.durability,
        queuedCrafts
      };
    }
    return null;
  }, [craftingInventoryConfig.blueprintDurabilityEnabled, craftingInventoryConfig.defaultDurabilityLoss, stagedItems, queue]);

  const getToolDurabilityLimit = useCallback((recipe: Recipe): { limited: boolean; maxCrafts: number; toolName: string; queuedCrafts: number } | null => {
    if (!recipe.tools || recipe.tools.length === 0 || !craftingInventoryConfig.toolsDurabilityEnabled) return null;

    let mostLimitingTool: { maxCrafts: number; toolName: string; queuedCrafts: number } | null = null;

    for (const tool of recipe.tools) {
      // Only check durability-type tools
      if (tool.consumptionType !== 'durability') continue;

      const durabilityLoss = tool.durabilityLoss || craftingInventoryConfig.toolsDefaultLoss || 10;
      const defaultDurability = craftingInventoryConfig.toolsDefaultDurability || 100;

      // Find all staged items of this tool type and sum their durability
      const stagedToolItems = stagedItems.filter(item => item.item === tool.item);
      if (stagedToolItems.length === 0) continue;

      let totalDurability = 0;
      for (const stagedTool of stagedToolItems) {
        const itemDurability = stagedTool.durability ?? defaultDurability;
        const itemCount = stagedTool.count || 1;
        totalDurability += itemDurability * itemCount;
      }

      // Calculate how many crafts are already queued using this tool
      const queuedCrafts = queue
        .filter(q => q.recipe.tools?.some(t => t.item === tool.item && t.consumptionType === 'durability'))
        .reduce((sum, q) => sum + q.quantity, 0);

      // Calculate max from total durability, accounting for queued items
      const totalMaxFromDurability = Math.floor(totalDurability / durabilityLoss);
      const remainingMaxCrafts = Math.max(0, totalMaxFromDurability - queuedCrafts);

      // Track the most limiting tool
      if (mostLimitingTool === null || remainingMaxCrafts < mostLimitingTool.maxCrafts) {
        mostLimitingTool = {
          maxCrafts: remainingMaxCrafts,
          toolName: tool.label || tool.item,
          queuedCrafts
        };
      }
    }

    if (mostLimitingTool && mostLimitingTool.maxCrafts < 99) {
      return {
        limited: true,
        ...mostLimitingTool
      };
    }

    return null;
  }, [craftingInventoryConfig.toolsDurabilityEnabled, craftingInventoryConfig.toolsDefaultLoss, craftingInventoryConfig.toolsDefaultDurability, stagedItems, queue]);

  const filteredRecipes = recipes.filter(recipe => {
    const matchesSearch = recipe.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         recipe.name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = !categoryFilter || recipe.category === categoryFilter;
    const isVisibleInCrafting = !isTechTreeLocked(recipe);
    const hasBlueprintIfRequired = !recipe.blueprintMissing; // Hide if blueprint is required but not attached
    return matchesSearch && matchesCategory && isVisibleInCrafting && hasBlueprintIfRequired;
  });

  const categories = [...new Set(recipes.map(r => r.category).filter(Boolean))];

  const handleAddToQueue = async () => {
    if (!selectedRecipe || !canCraft(selectedRecipe, craftQuantity)) return;
    const result = await fetchNui<{ success: boolean; queue?: QueueItem[] }>('addToQueue', {
      recipeId: selectedRecipe.id,
      quantity: craftQuantity
    });
    if (result.success && result.queue) {
      const luaQueue = result.queue;
      setQueue(prevQueue => {
        // Preserve React's local countdown for the active item if it hasn't changed.
        // Lua's remainingTime drifts behind React's because lib.callback.await blocks
        // the countdown loop, so using Lua's value would cause a visible uptick.
        // Only preserve when: our timer hasn't hit 0 yet AND we own the item.
        // For non-owned shared items, server is the authority — using React's stale 0
        // would cause the timer to appear stuck at 0s until the owner finishes.
        if (prevQueue.length > 0 && luaQueue.length > 0 && prevQueue[0].id === luaQueue[0].id
            && prevQueue[0].remainingTime > 0 && prevQueue[0].isOwnItem !== false) {
          const merged = [...luaQueue];
          merged[0] = { ...merged[0], remainingTime: prevQueue[0].remainingTime };
          return merged;
        }
        return luaQueue;
      });
    }
    setCraftQuantity(1);
  };

  const handleRemoveFromQueue = async (queueItemId: string) => {
    const result = await fetchNui<{ success: boolean; queue?: QueueItem[] }>('removeFromQueue', {
      queueItemId
    });
    if (result.success && result.queue) {
      const luaQueue = result.queue;
      setQueue(prevQueue => {
        if (prevQueue.length > 0 && luaQueue.length > 0 && prevQueue[0].id === luaQueue[0].id
            && prevQueue[0].remainingTime > 0 && prevQueue[0].isOwnItem !== false) {
          const merged = [...luaQueue];
          merged[0] = { ...merged[0], remainingTime: prevQueue[0].remainingTime };
          return merged;
        }
        return luaQueue;
      });
    }
  };

  const handleAttachBlueprint = async (blueprintItem: string) => {
    await fetchNui<{ success: boolean }>('attachBlueprint', { blueprintItem });
  };

  const handleDetachBlueprint = async (blueprintItem: string) => {
    await fetchNui<{ success: boolean }>('detachBlueprint', { blueprintItem });
  };

  const handleStageItem = async (itemName: string, count: number, targetSlot?: number, sourceSlot?: number) => {
    // When sourceSlot is provided, find the specific item in that slot; otherwise fallback to first match
    const invItem = sourceSlot !== undefined
      ? filteredInventory.find(i => i.item === itemName && i.slot === sourceSlot)
      : filteredInventory.find(i => i.item === itemName);
    if (!invItem) return;

    const actualCount = Math.min(count, invItem.count);
    if (actualCount <= 0) return;

    const originalFilteredInventory = [...filteredInventory];
    const originalInventory = [...inventory];
    const originalStagedItems = [...stagedItems];

    // Update inventory (remove from player inventory)
    setFilteredInventory(prev => prev.map(item =>
      (sourceSlot !== undefined ? item.slot === sourceSlot : item.item === itemName)
        ? { ...item, count: item.count - actualCount }
        : item
    ).filter(item => item.count > 0));

    setInventory(prev => prev.map(item =>
      (sourceSlot !== undefined ? item.slot === sourceSlot : item.item === itemName)
        ? { ...item, count: item.count - actualCount }
        : item
    ).filter(item => item.count > 0));

    // Update staged items - only merge if dropping onto same item in target slot
    setStagedItems(prev => {
      // Check if target slot has an item of the same type
      const targetSlotItem = targetSlot !== undefined ? prev.find(i => i.slot === targetSlot) : null;

      if (targetSlotItem && targetSlotItem.item === itemName) {
        // Merge into existing stack at target slot
        return prev.map(item =>
          item.slot === targetSlot
            ? { ...item, count: item.count + actualCount }
            : item
        );
      } else {
        // Create new stack - find available slot
        let slotToUse = targetSlot;
        if (slotToUse === undefined || prev.some(i => i.slot === slotToUse)) {
          const usedSlots = new Set(prev.map(i => i.slot).filter(s => s !== undefined));
          slotToUse = 0;
          while (usedSlots.has(slotToUse)) slotToUse++;
        }
        return [...prev, {
          item: itemName,
          label: invItem.label,
          count: actualCount,
          image: invItem.image,
          slot: slotToUse,
          durability: invItem.durability
        }];
      }
    });

    const result = await fetchNui<{ success: boolean; message?: string }>('stageItem', {
      item: itemName,
      count: actualCount,
      slot: targetSlot,
      sourceSlot: sourceSlot
    });

    if (!result?.success) {
      // Revert optimistic update
      setFilteredInventory(originalFilteredInventory);
      setInventory(originalInventory);
      setStagedItems(originalStagedItems);

      // Show toast notification
      if (result?.message) {
        showToast(result.message, 'error');
      }
    }
  };

  const handleUnstageItem = async (itemName: string, count: number, sourceSlot?: number) => {
    // Find the specific staged item by both name and slot (if provided)
    const stagedItem = sourceSlot !== undefined
      ? stagedItems.find(i => i.item === itemName && i.slot === sourceSlot)
      : stagedItems.find(i => i.item === itemName);
    if (!stagedItem) return;

    const actualCount = Math.min(count, stagedItem.count);
    if (actualCount <= 0) return;

    // Store original state for rollback
    const originalStagedItems = [...stagedItems];
    const originalFilteredInventory = [...filteredInventory];
    const originalInventory = [...inventory];

    // Optimistically update UI - only update the specific slot
    setStagedItems(prev => prev.map(item =>
      (item.item === itemName && (sourceSlot === undefined || item.slot === sourceSlot))
        ? { ...item, count: item.count - actualCount }
        : item
    ).filter(item => item.count > 0));

    setFilteredInventory(prev => {
      const existing = prev.find(i => i.item === itemName);
      if (existing) {
        return prev.map(item =>
          item.item === itemName
            ? { ...item, count: item.count + actualCount }
            : item
        );
      } else {
        return [...prev, {
          item: itemName,
          label: stagedItem.label,
          count: actualCount,
          image: stagedItem.image,
          durability: stagedItem.durability
        }];
      }
    });

    setInventory(prev => {
      const existing = prev.find(i => i.item === itemName);
      if (existing) {
        return prev.map(item =>
          item.item === itemName
            ? { ...item, count: item.count + actualCount }
            : item
        );
      } else {
        return [...prev, {
          item: itemName,
          label: stagedItem.label,
          count: actualCount,
          image: stagedItem.image,
          durability: stagedItem.durability
        }];
      }
    });

    const result = await fetchNui<{ success: boolean; message?: string }>('unstageItem', { item: itemName, count: actualCount, sourceSlot });

    if (!result?.success) {
      // Revert optimistic update
      setStagedItems(originalStagedItems);
      setFilteredInventory(originalFilteredInventory);
      setInventory(originalInventory);

      // Show toast notification
      if (result?.message) {
        showToast(result.message, 'error');
      }
    }
  };

  const handleUnstageItemToSlot = async (itemName: string, count: number, targetSlot: number, sourceSlot?: number) => {
    // Find the specific staged item by both name and slot (if provided)
    const stagedItem = sourceSlot !== undefined
      ? stagedItems.find(i => i.item === itemName && i.slot === sourceSlot)
      : stagedItems.find(i => i.item === itemName);
    if (!stagedItem) return;

    const actualCount = Math.min(count, stagedItem.count);
    if (actualCount <= 0) return;

    // Store original state for rollback
    const originalStagedItems = [...stagedItems];
    const originalFilteredInventory = [...filteredInventory];
    const originalInventory = [...inventory];

    // Optimistically update UI - only update the specific slot
    setStagedItems(prev => prev.map(item =>
      (item.item === itemName && (sourceSlot === undefined || item.slot === sourceSlot))
        ? { ...item, count: item.count - actualCount }
        : item
    ).filter(item => item.count > 0));

    // For slot-based inventory, add item at specific slot
    setFilteredInventory(prev => {
      const existingAtSlot = prev.find(i => i.slot === targetSlot);
      if (existingAtSlot && existingAtSlot.item === itemName) {
        // Same item at slot, increase count
        return prev.map(item =>
          item.slot === targetSlot
            ? { ...item, count: item.count + actualCount }
            : item
        );
      } else if (!existingAtSlot) {
        // Empty slot, add new item
        return [...prev, {
          item: itemName,
          label: stagedItem.label,
          count: actualCount,
          slot: targetSlot,
          image: stagedItem.image,
          durability: stagedItem.durability
        }];
      }
      // Slot occupied by different item - shouldn't happen but fallback to regular add
      return prev;
    });

    setInventory(prev => {
      const existingAtSlot = prev.find(i => i.slot === targetSlot);
      if (existingAtSlot && existingAtSlot.item === itemName) {
        return prev.map(item =>
          item.slot === targetSlot
            ? { ...item, count: item.count + actualCount }
            : item
        );
      } else if (!existingAtSlot) {
        return [...prev, {
          item: itemName,
          label: stagedItem.label,
          count: actualCount,
          slot: targetSlot,
          image: stagedItem.image,
          durability: stagedItem.durability
        }];
      }
      return prev;
    });

    const result = await fetchNui<{ success: boolean; message?: string }>('unstageItemToSlot', {
      item: itemName,
      count: actualCount,
      targetSlot: targetSlot,
      sourceSlot: sourceSlot
    });

    if (!result?.success) {
      // Revert optimistic update
      setStagedItems(originalStagedItems);
      setFilteredInventory(originalFilteredInventory);
      setInventory(originalInventory);

      // Show toast notification
      if (result?.message) {
        showToast(result.message, 'error');
      }
    }
  };

  const handleClose = useCallback(async () => {
    // Check if we're allowed to close
    const response = await fetchNui<{ canClose: boolean }>('canCloseUI');
    if (response && response.canClose === false) {
      return; // Server denied close request
    }

    setIsVisible(false);
    setSelectedRecipe(null);
    setCraftQuantity(1);
    setSearchTerm('');
    fetchNui('closeUI');
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isVisible) {
        handleClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isVisible, handleClose]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent<NUIMessage>) => {
      const data = event.data;
      switch (data.action) {
        case 'open':
          setIsVisible(true);
          if (data.recipes) setRecipes(data.recipes);
          if (data.inventory) setInventory(data.inventory);
          if (data.filteredInventory) setFilteredInventory(data.filteredInventory);
          if (data.queue) setQueue(data.queue);
          if (data.attachedBlueprints) setAttachedBlueprints(data.attachedBlueprints);
          if (data.attachedWithLabels) setAttachedWithLabels(data.attachedWithLabels);
          if (data.playerBlueprints) setPlayerBlueprints(data.playerBlueprints);
          if (data.validBlueprintItems) setValidBlueprintItems(data.validBlueprintItems);
          if (data.playerLevel) setPlayerLevel(data.playerLevel);
          if (data.inventoryPanelEnabled !== undefined) setInventoryPanelEnabled(data.inventoryPanelEnabled);
          if (data.craftingInventoryConfig) setCraftingInventoryConfig(data.craftingInventoryConfig);
          if (data.stagedItems) setStagedItems(data.stagedItems);
          if (data.stagedWeight !== undefined) setStagedWeight(data.stagedWeight);
          if (data.inventoryWeight !== undefined) setInventoryWeight(data.inventoryWeight);
          if (data.inventoryMaxWeight !== undefined) setInventoryMaxWeight(data.inventoryMaxWeight);
          if (data.totalSlots !== undefined) setTotalSlots(data.totalSlots);
          if (data.supportsSlots !== undefined) setSupportsSlots(data.supportsSlots);
          if (data.techPoints) setTechPoints(data.techPoints);
          if (data.unlockedNodes) setUnlockedNodes(data.unlockedNodes);
          if (data.techTreeConfig) {
            setTechTreeConfig(data.techTreeConfig);
            // Reset selected tree if current selection is not available in new config
            if (data.techTreeConfig.trees) {
              const availableTrees = Object.keys(data.techTreeConfig.trees);
              setSelectedTree(prev => {
                if (!prev || !availableTrees.includes(prev)) {
                  return availableTrees[0] || null;
                }
                return prev;
              });
            } else {
              setSelectedTree(null);
            }
          }
          if (data.locale) setLocale(data.locale);
          // Permission system data
          if (data.isPlacedWorkbench !== undefined) setIsPlacedWorkbench(data.isPlacedWorkbench);
          if (data.isWorkbenchOwner !== undefined) setIsWorkbenchOwner(data.isWorkbenchOwner);
          if (data.permissionsEnabled !== undefined) setPermissionsEnabled(data.permissionsEnabled);
          setPermissions([]);
          setSourceInput('');
          // History system data
          if (data.historyEnabled !== undefined) setHistoryEnabled(data.historyEnabled);
          if (data.historyOwnerOnlyDelete !== undefined) setHistoryOwnerOnlyDelete(data.historyOwnerOnlyDelete);
          if (data.historyDateFormat) setHistoryDateFormat(data.historyDateFormat);
          setHistory([]);
          // Shared crafting data
          if (data.sharedCrafting !== undefined) setSharedCrafting(data.sharedCrafting);
          // Reset to crafting tab on open
          setActiveTab('crafting');
          break;
        case 'close':
          setIsVisible(false);
          setSelectedRecipe(null);
          break;
        case 'historyUpdated':
          if (data.history !== undefined) setHistory(data.history);
          break;
        case 'updateInventory':
          if (data.inventory) setInventory(data.inventory);
          if (data.filteredInventory) setFilteredInventory(data.filteredInventory);
          if (data.inventoryWeight !== undefined) setInventoryWeight(data.inventoryWeight);
          if (data.totalSlots !== undefined) setTotalSlots(data.totalSlots);
          if (data.supportsSlots !== undefined) setSupportsSlots(data.supportsSlots);
          break;
        case 'updateQueue':
          if (data.queue) {
            const luaQueue = data.queue;
            setQueue(prevQueue => {
              // Preserve React's local countdown for the active item if it hasn't changed.
              // Without this, each queue update resets the timer to Lua's value, which drifts
              // behind React's independent setInterval — causing successive crafts to appear
              // shorter until they become instant.
              // Only preserve when: our timer hasn't hit 0 yet AND we own the item.
              // For non-owned shared items, server is the authority — using React's stale 0
              // would cause the timer to appear stuck at 0s until the owner finishes.
              if (prevQueue.length > 0 && luaQueue.length > 0 && prevQueue[0].id === luaQueue[0].id
                  && prevQueue[0].remainingTime > 0 && prevQueue[0].isOwnItem !== false) {
                const merged = [...luaQueue];
                merged[0] = { ...merged[0], remainingTime: prevQueue[0].remainingTime };
                return merged;
              }
              return luaQueue;
            });
          }
          break;
        case 'updateRecipes':
          if (data.recipes) setRecipes(data.recipes);
          break;
        case 'updateBlueprints':
          if (data.attachedBlueprints) setAttachedBlueprints(data.attachedBlueprints);
          if (data.attachedWithLabels) setAttachedWithLabels(data.attachedWithLabels);
          if (data.playerBlueprints) setPlayerBlueprints(data.playerBlueprints);
          if (data.recipes) setRecipes(data.recipes);
          break;
        case 'updateLevel':
          if (data.playerLevel) setPlayerLevel(data.playerLevel);
          break;
        case 'updateStagedItems':
          if (data.stagedItems) {
            setStagedItems(prev => {
              const currentSlotMap = new Map(prev.map(item => [item.item, item.slot]));
              return data.stagedItems!.map((item, index) => ({
                ...item,
                slot: item.slot !== undefined ? item.slot : (currentSlotMap.get(item.item) ?? index)
              }));
            });
          }
          if (data.stagedWeight !== undefined) setStagedWeight(data.stagedWeight);
          break;
        case 'updateTechPoints':
          if (data.techPoints) setTechPoints(data.techPoints);
          break;
        case 'updateUnlockedNodes':
          if (data.unlockedNodes) setUnlockedNodes(data.unlockedNodes);
          break;
        case 'showToast':
          if (data.toastMessage) {
            showToast(data.toastMessage, data.toastType || 'error');
          }
          break;
        case 'queueItemComplete':
          // Trigger completion animation for a queue item
          if (data.itemId && data.status) {
            const itemId = data.itemId;
            const status = data.status;
            setCompletingItems(prev => {
              const newMap = new Map(prev);
              newMap.set(itemId, { status, animating: false });
              return newMap;
            });
            // Start animation after a brief delay to ensure the element is rendered
            setTimeout(() => {
              setCompletingItems(prev => {
                const newMap = new Map(prev);
                const item = newMap.get(itemId);
                if (item) {
                  newMap.set(itemId, { ...item, animating: true });
                }
                return newMap;
              });
            }, 50);
            // Remove from completing items after animation completes
            setTimeout(() => {
              setCompletingItems(prev => {
                const newMap = new Map(prev);
                newMap.delete(itemId);
                return newMap;
              });
            }, 850);
          }
          break;
        case 'openAdmin':
          setIsAdminOpen(true);
          setIsAdminHidden(false);
          if (data.locale) setLocale(data.locale);
          break;
        case 'closeAdmin':
          setIsAdminOpen(false);
          setIsAdminHidden(false);
          break;
        case 'hideAdmin':
          setIsAdminHidden(true);
          break;
        case 'showAdmin':
          setIsAdminHidden(false);
          break;
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  // Local countdown timer for smooth UI updates
  // Lua is still the source of truth for queue completion
  // Only depends on queue[0]?.id so the interval is not disrupted by add/remove of other items
  useEffect(() => {
    // Clear any existing timer
    if (queueTimerRef.current) {
      clearInterval(queueTimerRef.current);
      queueTimerRef.current = null;
    }

    // Only run timer if there are items in queue and first item has time remaining
    if (queue.length > 0 && queue[0].remainingTime > 0) {
      queueTimerRef.current = setInterval(() => {
        setQueue(prevQueue => {
          if (prevQueue.length === 0 || prevQueue[0].remainingTime <= 0) {
            return prevQueue;
          }
          // Create new array with decremented first item
          const newQueue = [...prevQueue];
          newQueue[0] = {
            ...newQueue[0],
            remainingTime: Math.max(0, newQueue[0].remainingTime - 1)
          };
          return newQueue;
        });
      }, 1000);
    }

    return () => {
      if (queueTimerRef.current) {
        clearInterval(queueTimerRef.current);
        queueTimerRef.current = null;
      }
    };
  }, [queue[0]?.id]);

  useEffect(() => {
    if (isEnvBrowser()) {
      setIsVisible(true);
      setRecipes([
        { id: 'advanced_kiln', name: 'advanced_kiln', label: 'Advanced Kiln', craftTime: 5, category: 'tools', xpReward: 15, ingredients: [{ item: 'steel', label: 'Steel', amount: 1 }] },
        { id: 'charcoal', name: 'charcoal', label: 'Charcoal', craftTime: 3, category: 'materials', xpReward: 5, ingredients: [{ item: 'wood', label: 'Wood', amount: 10 }] },
        { id: 'electric_drill', name: 'electric_drill', label: 'Electric drill', craftTime: 8, category: 'tools', xpReward: 25, levelRequired: 3, ingredients: [{ item: 'steel', label: 'Steel', amount: 2 }, { item: 'electronics', label: 'Electronics', amount: 1 }] },
        { id: 'flat_screwdriver', name: 'flat_screwdriver', label: 'Flat screwdriver', craftTime: 2, category: 'tools', xpReward: 10, ingredients: [{ item: 'steel', label: 'Steel', amount: 1 }] },
        { id: 'metalcutting_scissors', name: 'metalcutting_scissors', label: 'Metalcutting scissors', craftTime: 4, category: 'tools', xpReward: 15, levelRequired: 2, ingredients: [{ item: 'steel', label: 'Steel', amount: 2 }] },
        { id: 'thermite', name: 'thermite', label: 'Thermite', craftTime: 10, category: 'explosives', blueprint: 'blueprint_thermite', xpReward: 50, levelRequired: 7, ingredients: [{ item: 'aluminium', label: 'Aluminium', amount: 3 }] },
        { id: 'pipe_grip_wrench', name: 'pipe_grip_wrench', label: 'Pipe grip wrench', craftTime: 3, category: 'tools', xpReward: 10, ingredients: [{ item: 'steel', label: 'Steel', amount: 1 }] },
        { id: 'pliers', name: 'pliers', label: 'Pliers', craftTime: 2, category: 'tools', xpReward: 10, levelRequired: 5, ingredients: [{ item: 'steel', label: 'Steel', amount: 1 }] },
      ]);
      setInventory([
        { item: 'steel', label: 'Steel', count: 68 },
        { item: 'wood', label: 'Wood', count: 25 },
        { item: 'aluminium', label: 'Aluminium', count: 12 },
        { item: 'electronics', label: 'Electronics', count: 5 },
        { item: 'plastic', label: 'Plastic', count: 30 },
      ]);
      setFilteredInventory([
        { item: 'steel', label: 'Steel', count: 68 },
        { item: 'wood', label: 'Wood', count: 25 },
        { item: 'aluminium', label: 'Aluminium', count: 12 },
        { item: 'electronics', label: 'Electronics', count: 5 },
      ]);
      setInventoryPanelEnabled(true);
      setQueue([{ id: 'queue_1', recipe: { id: 'advanced_kiln', name: 'advanced_kiln', label: 'Advanced Kiln', craftTime: 5, ingredients: [] }, quantity: 1, startTime: Date.now(), totalTime: 5, remainingTime: 4 }]);
      setSelectedRecipe({ id: 'advanced_kiln', name: 'advanced_kiln', label: 'Advanced Kiln', craftTime: 5, category: 'tools', ingredients: [{ item: 'steel', label: 'Steel', amount: 1 }] });
      setAttachedBlueprints(['blueprint_thermite']);
      setAttachedWithLabels([
        { item: 'blueprint_thermite', label: 'Thermite Blueprint', recipeId: 'thermite', recipeLabel: 'Thermite' },
      ]);
      setPlayerBlueprints([
        { item: 'blueprint_advancedlockpick', label: 'Advanced Lockpick Blueprint', count: 1, recipeId: 'advancedlockpick', recipeLabel: 'Advanced Lockpick' },
        { item: 'blueprint_armour', label: 'Bulletproof Vest Blueprint', count: 2, recipeId: 'armour', recipeLabel: 'Bulletproof Vest' },
      ]);
      setValidBlueprintItems(['blueprint_thermite', 'blueprint_advancedlockpick', 'blueprint_armour']);
      setPlayerLevel({ xp: 450, level: 4, enabled: true, maxLevel: 10, xpForNextLevel: 850, xpForCurrentLevel: 500 });
      setCraftingInventoryConfig({
        enabled: true,
        perWorkbench: false,
        maxSlots: 20,
        maxWeight: 50000,
        returnOnClose: false
      });
      setStagedItems([
        { item: 'steel', label: 'Steel', count: 10, weight: 1000 },
        { item: 'wood', label: 'Wood', count: 5, weight: 500 },
      ]);
      setStagedWeight(12500);
      setInventoryWeight(75000);
    }
  }, []);

  const handleStartDrag = useCallback((item: DragItem, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDraggedItem(item);
    setMousePos({ x: e.clientX, y: e.clientY });
  }, []);

  const isPointInElement = useCallback((x: number, y: number, element: HTMLElement | null): boolean => {
    if (!element) return false;
    const rect = element.getBoundingClientRect();
    return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
  }, []);

  const findHoveredSlot = useCallback((x: number, y: number): number | null => {
    for (const [slotIndex, el] of craftingSlotRefs.current.entries()) {
      if (isPointInElement(x, y, el)) {
        return slotIndex;
      }
    }
    return null;
  }, [isPointInElement]);

  const findHoveredInventorySlot = useCallback((x: number, y: number): number | null => {
    for (const [slotIndex, el] of inventorySlotRefs.current.entries()) {
      if (isPointInElement(x, y, el)) {
        return slotIndex;
      }
    }
    return null;
  }, [isPointInElement]);

  useEffect(() => {
    if (!draggedItem) {
      setHoveredCraftingSlot(null);
      setHoveredInventorySlot(null);
      return;
    }

    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({ x: e.clientX, y: e.clientY });
      const slot = findHoveredSlot(e.clientX, e.clientY);
      setHoveredCraftingSlot(slot);

      // Track inventory slot hover when dragging staged items (for slot-based unstaging)
      if (supportsSlots && draggedItem.type === 'staged') {
        const invSlot = findHoveredInventorySlot(e.clientX, e.clientY);
        setHoveredInventorySlot(invSlot);
      }
    };

    const handleMouseUp = async (e: MouseEvent) => {
      const x = e.clientX;
      const y = e.clientY;
      const dropAmount = draggedItem.amount || 1;
      const targetSlot = findHoveredSlot(x, y);

      const createRipple = (refElement: HTMLDivElement | null) => {
        const rect = refElement?.getBoundingClientRect();
        if (rect) {
          setDropRipple({
            x: x - rect.left,
            y: y - rect.top,
            key: Date.now()
          });
          setTimeout(() => setDropRipple(null), 500);
        }
      };

      setHoveredCraftingSlot(null);

      setDraggedItem(null);

      if (isPointInElement(x, y, craftingDropRef.current)) {
        if (craftingInventoryConfig.enabled) {
          if (draggedItem.type === 'inventory' || draggedItem.type === 'blueprint') {
            const item = draggedItem.data as PlayerInventoryItem;
            createRipple(craftingDropRef.current);
            handleStageItem(item.item, dropAmount, targetSlot !== null ? targetSlot : undefined, draggedItem.sourceSlot);
          }
          else if (draggedItem.type === 'staged' && targetSlot !== null) {
            const item = draggedItem.data as StagedItem;
            const sourceSlot = draggedItem.sourceSlot;
            if (sourceSlot !== undefined && sourceSlot !== targetSlot) {
              createRipple(craftingDropRef.current);

              // Check if target slot has an item
              const targetItem = stagedItems.find(si => si.slot === targetSlot);
              const isSplitting = dropAmount < item.count;

              // Helper to check if durabilities match (both undefined, or both same value)
              const durabilityMatches = (dur1: number | undefined, dur2: number | undefined) => {
                if (dur1 === undefined && dur2 === undefined) return true;
                if (dur1 === undefined || dur2 === undefined) return false;
                return dur1 === dur2;
              };

              if (isSplitting) {
                // Splitting stack - move partial amount to target slot
                if (targetItem && targetItem.item !== item.item) {
                  // Can't split onto different item type
                  return;
                }
                // Can't merge onto item with different durability
                if (targetItem && !durabilityMatches(item.durability, targetItem.durability)) {
                  showToast('Cannot merge items with different durability', 'error');
                  return;
                }
                const originalStagedItems = [...stagedItems];
                setStagedItems(prev => {
                  const result = prev.map(si => {
                    if (si.slot === sourceSlot) {
                      return { ...si, count: si.count - dropAmount };
                    }
                    if (si.slot === targetSlot && targetItem) {
                      return { ...si, count: si.count + dropAmount };
                    }
                    return si;
                  });
                  // If target slot was empty, add new stack
                  if (!targetItem) {
                    result.push({
                      item: item.item,
                      label: item.label,
                      count: dropAmount,
                      slot: targetSlot,
                      image: item.image,
                      durability: item.durability
                    });
                  }
                  return result;
                });
                fetchNui<{ success: boolean; message?: string }>('splitStagedStack', { sourceSlot, targetSlot, amount: dropAmount }).then(result => {
                  if (!result?.success) {
                    setStagedItems(originalStagedItems);
                    if (result?.message) showToast(result.message, 'error');
                  }
                });
              } else if (targetItem && targetItem.item === item.item) {
                // Same item type - check durability before merging
                if (!durabilityMatches(item.durability, targetItem.durability)) {
                  showToast('Cannot merge items with different durability', 'error');
                  return;
                }
                // Same item type, same durability - merge stacks (full amount)
                const originalStagedItems = [...stagedItems];
                setStagedItems(prev => {
                  const merged = prev.filter(si => si.slot !== sourceSlot).map(si => {
                    if (si.slot === targetSlot) {
                      return { ...si, count: si.count + item.count };
                    }
                    return si;
                  });
                  return merged;
                });
                fetchNui<{ success: boolean; message?: string }>('mergeStagedStacks', { sourceSlot, targetSlot }).then(result => {
                  if (!result?.success) {
                    setStagedItems(originalStagedItems);
                    if (result?.message) showToast(result.message, 'error');
                  }
                });
              } else {
                // Different item or empty slot - move/swap (full amount)
                setStagedItems(prev => {
                  return prev.map(stagedItem => {
                    if (stagedItem.slot === sourceSlot) {
                      return { ...stagedItem, slot: targetSlot };
                    }
                    if (stagedItem.slot === targetSlot) {
                      return { ...stagedItem, slot: sourceSlot };
                    }
                    return stagedItem;
                  });
                });
                fetchNui('moveStagedSlot', { sourceSlot, newSlot: targetSlot });
              }
            }
          }
        } else {
          let itemToAttach: string | null = null;

          if (draggedItem.type === 'blueprint') {
            const blueprint = draggedItem.data as PlayerBlueprint;
            itemToAttach = blueprint.item;
          } else if (draggedItem.type === 'inventory') {
            const item = draggedItem.data as PlayerInventoryItem;
            if (validBlueprintItems.includes(item.item)) {
              itemToAttach = item.item;
            }
          }

          if (itemToAttach) {
            createRipple(craftingDropRef.current);
            handleAttachBlueprint(itemToAttach);
          }
        }
      }
      else if (isPointInElement(x, y, inventoryDropRef.current)) {
        if (craftingInventoryConfig.enabled) {
          if (draggedItem.type === 'staged') {
            const item = draggedItem.data as StagedItem;
            createRipple(inventoryDropRef.current);
            // Check if dropping to a specific inventory slot (slot-based inventory)
            // Pass sourceSlot to ensure we remove from the correct staged slot
            if (supportsSlots && hoveredInventorySlot !== null) {
              handleUnstageItemToSlot(item.item, dropAmount, hoveredInventorySlot, draggedItem.sourceSlot);
            } else {
              handleUnstageItem(item.item, dropAmount, draggedItem.sourceSlot);
            }
          }
        } else {
          if (draggedItem.type === 'attached') {
            createRipple(inventoryDropRef.current);
            const blueprintItem = draggedItem.data as string;
            handleDetachBlueprint(blueprintItem);
          }
        }
      }
      setHoveredInventorySlot(null);
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [draggedItem, isPointInElement, craftingInventoryConfig.enabled, supportsSlots, hoveredInventorySlot, findHoveredInventorySlot]);

  const getGhostInfo = useCallback(() => {
    if (!draggedItem) return null;
    const itemData = draggedItem.data;
    let itemName: string;
    let itemLabel: string;
    let count: number = 1;

    if (typeof itemData === 'string') {
      itemName = itemData;
      itemLabel = itemData.replace(/_/g, ' ');
    } else {
      itemName = itemData.item;
      itemLabel = itemData.label || itemName;
      count = draggedItem.amount || ('count' in itemData ? (itemData.count || 1) : 1);
    }

    return { itemName, itemLabel, count };
  }, [draggedItem]);

  if (!isVisible && !isAdminOpen) return null;

  if (isAdminOpen) {
    return (
      <TranslationProvider locale={locale}>
        {/* Toast Notifications (shared with admin panel) */}
        <div className="fixed top-6 left-1/2 -translate-x-1/2 z-[9999] flex flex-col gap-2 pointer-events-none">
          {toasts.map((toast) => (
            <div
              key={toast.id}
              className={`pointer-events-auto flex items-center gap-2 px-4 py-2.5 rounded-xl border shadow-lg ${toast.exiting ? 'animate-toastFadeOut' : 'animate-toastSlideIn'}`}
              style={{
                backgroundColor: toast.type === 'error' ? 'rgba(127,29,29,0.95)' : toast.type === 'success' ? 'rgba(6,78,59,0.95)' : 'rgba(26,26,31,0.95)',
                borderColor: toast.type === 'error' ? 'rgba(239,68,68,0.4)' : toast.type === 'success' ? 'rgba(16,185,129,0.4)' : 'rgba(255,255,255,0.2)',
              }}
            >
              <span className={`text-xs ${toast.type === 'error' ? 'text-red-100' : toast.type === 'success' ? 'text-emerald-100' : 'text-white'}`}>
                {toast.message}
              </span>
            </div>
          ))}
        </div>
        <div className="w-full h-full" style={{ display: isAdminHidden ? 'none' : undefined }}>
          <AdminPanel fetchNui={fetchNui} showToast={showToast} />
        </div>
      </TranslationProvider>
    );
  }

  const ghostInfo = getGhostInfo();

  return (
    <TranslationProvider locale={locale}>
    <TranslatedContent>
    {(t) => (
    <div className={`w-full h-full flex ${inventoryPanelEnabled ? 'justify-between' : 'justify-end'} items-center`} style={{ padding: 'calc((1.667vw + 2.963vh) / 2)', perspective: 'calc((62.5vw + 111.111vh) / 2)', backgroundColor: 'rgba(0, 0, 0, 0.5)' }}>
      {/* Toast Notifications */}
      <div className="fixed top-6 left-1/2 -translate-x-1/2 z-[9999] flex flex-col gap-2 pointer-events-none">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={`${toast.exiting ? 'animate-toastFadeOut' : 'animate-toastSlideIn'} flex items-center gap-2.5 px-4 py-2.5 rounded-lg shadow-lg border ${
              toast.type === 'error'
                ? 'bg-red-900/95 border-red-500/40 text-red-100'
                : toast.type === 'success'
                ? 'bg-emerald-900/95 border-emerald-500/40 text-emerald-100'
                : 'bg-[#1a1a1f]/95 border-white/20 text-white'
            }`}
            style={{
              boxShadow: toast.type === 'error'
                ? '0 4px 20px rgba(220, 38, 38, 0.3)'
                : toast.type === 'success'
                ? '0 4px 20px rgba(16, 185, 129, 0.3)'
                : '0 4px 20px rgba(0, 0, 0, 0.4)'
            }}
          >
            <AlertCircle className={`w-4 h-4 flex-shrink-0 ${
              toast.type === 'error' ? 'text-red-400' : toast.type === 'success' ? 'text-emerald-400' : 'text-gray-400'
            }`} />
            <span className="text-sm font-medium">{toast.message}</span>
          </div>
        ))}
      </div>

      {/* Drag Ghost Element */}
      {draggedItem && ghostInfo && (
        <div
          ref={ghostRef}
          key={draggedItem.item}
          className="fixed pointer-events-none z-[9999] animate-plop-out"
          style={{
            left: mousePos.x - 40,
            top: mousePos.y - 40,
            width: 80,
            height: 80,
            background: 'rgba(26, 26, 31, 0.95)',
            border: '2px solid rgba(74, 222, 128, 0.6)',
            borderRadius: 8,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 8,
            boxShadow: '0 8px 24px rgba(0, 0, 0, 0.5), 0 0 30px rgba(74, 222, 128, 0.3)',
          }}
        >
          <ItemImage
            src={`nui://ox_inventory/web/images/${ghostInfo.itemName}.png`}
            alt={ghostInfo.itemName}
            className="w-9 h-9 object-contain"
            fallbackClassName="w-9 h-9 text-gray-600"
          />
          <span className="text-gray-300 text-center mt-1 max-w-[70px] truncate" style={{ fontSize: 'calc((0.469vw + 0.833vh) / 2)' }}>
            {ghostInfo.itemLabel}
          </span>
          <span className="absolute top-1 right-1 bg-black/60 text-white font-bold px-1.5 rounded" style={{ fontSize: 'calc((0.521vw + 0.926vh) / 2)' }}>
            {ghostInfo.count}
          </span>
        </div>
      )}

      {/* Left Panel - Inventory & Crafting Inventory */}
      {inventoryPanelEnabled && (
        <LeftPanel
          filteredInventory={filteredInventory}
          attachedBlueprints={attachedBlueprints}
          attachedWithLabels={attachedWithLabels}
          playerBlueprints={playerBlueprints}
          validBlueprintItems={validBlueprintItems}
          isBlueprint={isBlueprint}
          stagedItems={stagedItems}
          craftingInventoryConfig={craftingInventoryConfig}
          draggedItem={draggedItem}
          inventoryDragAmount={inventoryDragAmount}
          craftingDragAmount={craftingDragAmount}
          onStartDrag={handleStartDrag}
          onInventoryDragAmountChange={setInventoryDragAmount}
          onCraftingDragAmountChange={setCraftingDragAmount}
          t={t}
          inventoryRef={inventoryDropRef}
          craftingRef={craftingDropRef}
          dropRipple={dropRipple}
          inventorySearchTerm={inventorySearchTerm}
          onInventorySearchChange={setInventorySearchTerm}
          craftingSearchTerm={craftingSearchTerm}
          onCraftingSearchChange={setCraftingSearchTerm}
          onCraftingSlotRef={handleCraftingSlotRef}
          hoveredCraftingSlot={hoveredCraftingSlot}
          inventoryWeight={inventoryWeight}
          stagedWeight={stagedWeight}
          inventoryMaxWeight={inventoryMaxWeight}
          recipes={recipes}
          totalSlots={totalSlots}
          supportsSlots={supportsSlots}
          hoveredInventorySlot={hoveredInventorySlot}
          onInventorySlotRef={handleInventorySlotRef}
        />
      )}

      {/* Main Panel with 3D tilt and noise texture */}
      <div className="flex flex-col rounded-xl overflow-hidden animate-slideIn relative"
        style={{
          width: activeTab === 'techtree' && techTreeConfig.enabled ? 'calc((46.875vw + 83.333vh) / 2)' : 'calc((27.083vw + 48.148vh) / 2)',
          height: 'calc(100vh - calc((3.333vw + 5.926vh) / 2))',
          background: 'rgba(12, 12, 14, 0.82)',
          border: 'calc((0.052vw + 0.093vh) / 2) solid rgba(255,255,255,0.15)',
          transform: activeTab === 'techtree' && techTreeConfig.enabled ? 'rotateY(-2deg)' : 'rotateY(-4deg)',
          transformOrigin: 'right center',
          boxShadow: 'calc((-0.521vw + -0.926vh) / 2) 0 calc((2.083vw + 3.704vh) / 2) rgba(0,0,0,0.5)',
          transition: 'width 0.4s cubic-bezier(0.4, 0, 0.2, 1), transform 0.4s cubic-bezier(0.4, 0, 0.2, 1)'
        }}>
        {/* Noise texture overlay */}
        <div className="absolute inset-0 pointer-events-none z-10"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
            backgroundRepeat: 'repeat',
            backgroundSize: '128px 128px',
            opacity: 0.08,
            mixBlendMode: 'soft-light'
          }}
        />
        {/* Secondary grain layer for more visible dots */}
        <div className="absolute inset-0 pointer-events-none z-10"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='grain'%3E%3CfeTurbulence type='turbulence' baseFrequency='0.7' numOctaves='3' stitchTiles='stitch'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23grain)'/%3E%3C/svg%3E")`,
            backgroundRepeat: 'repeat',
            backgroundSize: '100px 100px',
            opacity: 0.12
          }}
        />

        {/* History Icon Button - Absolute positioned */}
        {historyEnabled && isPlacedWorkbench && (
          <button
            onClick={() => {
              setActiveTab('history');
              fetchNui<{ success: boolean; history: HistoryEntry[] }>('getHistory').then(res => {
                if (res.success) setHistory(res.history);
              });
            }}
            className={`absolute top-[18px] right-5 z-20 p-2 rounded-lg transition-all duration-200 ${
              activeTab === 'history'
                ? 'text-white bg-white/10'
                : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
            }`}
            title={t('tabs.history')}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </button>
        )}

        {/* Tabs */}
        <div className="px-5 pt-4 pb-3 pr-14 flex gap-1 flex-nowrap">
          <button
            onClick={() => setActiveTab('crafting')}
            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 whitespace-nowrap flex-shrink-0 ${
              activeTab === 'crafting'
                ? 'bg-[#1a1a1f] text-white'
                : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
            }`}
          >
            {t('tabs.crafting')}
          </button>
          <button
            onClick={() => setActiveTab('blueprints')}
            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 whitespace-nowrap flex-shrink-0 ${
              activeTab === 'blueprints'
                ? 'bg-[#1a1a1f] text-white'
                : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
            }`}
          >
            {t('craftingInventory.blueprints').toUpperCase()}
          </button>
          {techTreeConfig.enabled && (
            <button
              onClick={() => { setActiveTab('techtree'); if (!selectedTree && techTreeConfig.trees) setSelectedTree(Object.keys(techTreeConfig.trees)[0]); }}
              className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 whitespace-nowrap flex-shrink-0 ${
                activeTab === 'techtree'
                  ? 'bg-[#1a1a1f] text-white'
                  : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
              }`}
            >
              {t('tabs.techTree')}
            </button>
          )}
          {permissionsEnabled && isPlacedWorkbench && isWorkbenchOwner && (
            <button
              onClick={() => {
                setActiveTab('permissions');
                // Fetch permissions when switching to tab
                fetchNui<{ success: boolean; permissions: PermissionEntry[] }>('getPermissions').then(res => {
                  if (res.success) setPermissions(res.permissions);
                });
              }}
              className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 whitespace-nowrap flex-shrink-0 ${
                activeTab === 'permissions'
                  ? 'bg-[#1a1a1f] text-white'
                  : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
              }`}
            >
              {t('tabs.permissions')}
            </button>
          )}

        </div>

        {/* Level/XP Bar */}
        {playerLevel.enabled && (
          <div className="px-5 pb-3">
            <div className="bg-[#1a1a1f] rounded-lg p-3">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-[#4ade80]/20 flex items-center justify-center">
                    <span className="text-[#4ade80] font-bold text-sm">{playerLevel.level}</span>
                  </div>
                  <div>
                    <span className="text-white text-sm font-semibold">{t('common.level')} {playerLevel.level}</span>
                    {playerLevel.level < (playerLevel.maxLevel || 10) && (
                      <span className="text-gray-500 text-xs block">
                        {playerLevel.xp} / {playerLevel.xpForNextLevel} {t('common.xp')}
                      </span>
                    )}
                    {playerLevel.level >= (playerLevel.maxLevel || 10) && (
                      <span className="text-[#4ade80] text-xs block">{t('common.maxLevel')}</span>
                    )}
                  </div>
                </div>
                <span className="text-gray-500 text-xs">{playerLevel.xp} {t('common.xpTotal')}</span>
              </div>
              {/* XP Progress Bar */}
              {playerLevel.level < (playerLevel.maxLevel || 10) && (
                <div className="h-1.5 bg-[#252528] rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-[#4ade80] to-[#22c55e] transition-all duration-500"
                    style={{
                      width: `${Math.min(100, Math.max(0,
                        ((playerLevel.xp - (playerLevel.xpForCurrentLevel || 0)) /
                        ((playerLevel.xpForNextLevel || 1) - (playerLevel.xpForCurrentLevel || 0))) * 100
                      ))}%`
                    }}
                  />
                </div>
              )}
            </div>
          </div>
        )}

        {/* Crafting Tab Content */}
        {activeTab === 'crafting' && (
          <>
            {/* Search Bar with Filter */}
            <div className="px-5 pb-3 flex items-center gap-2">
              <div className="flex-1 relative">
                <input
                  type="text"
                  placeholder={t('recipes.searchPlaceholder')}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  onClick={(e) => { e.stopPropagation(); (e.target as HTMLInputElement).focus(); }}
                  onMouseDown={(e) => e.stopPropagation()}
                  className="w-full bg-[#1a1a1f] rounded-lg pl-4 pr-10 py-2.5 text-white text-sm placeholder-gray-600 focus:outline-none border border-transparent focus:border-white/10"
                />
                {searchTerm ? (
                  <button
                    onClick={() => setSearchTerm('')}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-0.5 hover:bg-white/10 rounded transition-colors z-10"
                  >
                    <X className="w-4 h-4 text-gray-400 hover:text-white" />
                  </button>
                ) : (
                  <Search className="w-4 h-4 text-gray-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                )}
              </div>
              <button
                className={`p-2.5 rounded-lg transition-all duration-200 relative ${
                  categoryFilter
                    ? 'bg-green-500/20 hover:bg-green-500/30'
                    : 'bg-[#1a1a1f] hover:bg-white/10'
                }`}
                onClick={() => setShowFilterMenu(!showFilterMenu)}
              >
                <Filter className={`w-5 h-5 transition-colors ${categoryFilter ? 'text-green-400' : 'text-gray-400'}`} />
                {categoryFilter && (
                  <div className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-green-400 rounded-full border-2 border-[#0c0c0e]" />
                )}
              </button>
            </div>

            {/* Filter Menu - Overlay */}
            {showFilterMenu && categories.length > 0 && (
              <>
                {/* Backdrop */}
                <div
                  className="fixed inset-0 z-40"
                  onClick={() => setShowFilterMenu(false)}
                />
                {/* Dropdown */}
                <div className="absolute right-5 top-24 z-50 filter-dropdown rounded-xl p-1.5 min-w-[180px] animate-dropdownSlideIn overflow-hidden">
                  {/* Noise texture */}
                  <div className="absolute inset-0 pointer-events-none rounded-xl overflow-hidden"
                    style={{
                      backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
                      backgroundRepeat: 'repeat',
                      backgroundSize: '128px 128px',
                      opacity: 0.07,
                      mixBlendMode: 'soft-light'
                    }}
                  />
                  {/* Gradient overlay */}
                  <div className="absolute inset-0 pointer-events-none rounded-xl"
                    style={{
                      background: 'linear-gradient(180deg, rgba(255,255,255,0.03) 0%, rgba(0,0,0,0.1) 100%)'
                    }}
                  />
                  {/* Content */}
                  <div className="relative z-10">
                    {/* Header */}
                    <div className="px-3 py-2 border-b border-white/5 mb-1">
                      <span className="text-[10px] font-semibold text-gray-500 uppercase tracking-wider">Category</span>
                    </div>
                    {/* Options */}
                    <button
                      onClick={() => { setCategoryFilter(null); setShowFilterMenu(false); }}
                      className={`filter-dropdown-item w-full text-left px-3 py-2 rounded-lg text-sm flex items-center gap-2 ${!categoryFilter ? 'active text-green-400' : 'text-gray-300 hover:text-white'}`}
                    >
                      <div className={`w-2 h-2 rounded-full ${!categoryFilter ? 'bg-green-400' : 'bg-gray-600'}`} />
                      {t('filter.all')}
                    </button>
                    {categories.map(cat => (
                      <button
                        key={cat}
                        onClick={() => { setCategoryFilter(cat!); setShowFilterMenu(false); }}
                        className={`filter-dropdown-item w-full text-left px-3 py-2 rounded-lg text-sm capitalize flex items-center gap-2 ${categoryFilter === cat ? 'active text-green-400' : 'text-gray-300 hover:text-white'}`}
                      >
                        <div className={`w-2 h-2 rounded-full ${categoryFilter === cat ? 'bg-green-400' : 'bg-gray-600'}`} />
                        {cat}
                      </button>
                    ))}
                  </div>
                </div>
              </>
            )}

        {/* Recipe Grid */}
        <div className="flex-shrink-0 px-5 pb-4 overflow-y-auto" style={{ height: 'calc((14.583vw + 25.926vh) / 2)' }}>
          <div className="grid grid-cols-4 pt-1" style={{ gap: 'calc((0.417vw + 0.741vh) / 2)' }}>
            {filteredRecipes.map(recipe => {
              const meetsLevel = meetsLevelRequirement(recipe);
              const craftable = canCraft(recipe);
              const maxQty = getMaxCraftable(recipe);
              const isSelected = selectedRecipe?.id === recipe.id;
              const isLevelLocked = !meetsLevel && recipe.levelRequired;

              let cardBg = '#3d2020';
              if (isSelected) {
                cardBg = '#2d4a2d';
              } else if (isLevelLocked) {
                cardBg = '#2d2040';
              } else if (craftable) {
                cardBg = '#2a2a30';
              }

              return (
                <button
                  key={recipe.id}
                  onClick={() => { setSelectedRecipe(recipe); setCraftQuantity(1); }}
                  className="relative rounded-lg overflow-hidden flex flex-col items-center justify-center p-2 transition-all duration-200 hover:scale-105 hover:brightness-110 hover:z-10"
                  style={{
                    aspectRatio: '1',
                    backgroundColor: cardBg,
                    boxShadow: isSelected ? '0 0 12px rgba(74, 222, 128, 0.4)' : 'none'
                  }}
                >
                  {/* Level Lock Indicator - Top Left */}
                  {isLevelLocked && (
                    <div className="absolute top-1 left-1 flex items-center gap-0.5 px-1 rounded bg-purple-500/30 text-purple-300">
                      <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
                      </svg>
                      <span className="text-[8px] font-bold">{recipe.levelRequired}</span>
                    </div>
                  )}

                  {/* Badge - Top Right */}
                  <div className="absolute top-1 right-1 flex items-center justify-center px-1 rounded font-bold bg-black/50 text-white" style={{ minWidth: 'calc((0.938vw + 1.667vh) / 2)', height: 'calc((0.938vw + 1.667vh) / 2)', fontSize: 'calc((0.521vw + 0.926vh) / 2)' }}>
                    {maxQty}
                  </div>

                  {/* Item Image - Centered */}
                  <ItemImage
                    src={getItemImage(recipe.name, recipe.image)}
                    alt={recipe.label}
                    className={`w-12 h-12 object-contain ${isLevelLocked ? 'opacity-50 grayscale' : ''}`}
                    fallbackClassName={`w-12 h-12 text-gray-600 ${isLevelLocked ? 'opacity-50' : ''}`}
                  />

                  {/* Item Label - Directly below image */}
                  <span className={`font-medium leading-tight text-center line-clamp-2 mt-1 ${isLevelLocked ? 'text-gray-400' : 'text-white'}`} style={{ fontSize: 'calc((0.469vw + 0.833vh) / 2)' }}>
                    {recipe.label}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Divider Line */}
        <div className="mx-5 border-t border-white/10" />

        {/* Recipe Details Section */}
        <div className="px-5 py-4 flex-shrink-0 flex flex-col">
          {/* Recipe Name & Quantity */}
          <div className="flex items-start justify-between mb-3">
            <div className="flex items-center gap-3">
              <h2 className="text-white font-bold text-xl tracking-wide">
                {selectedRecipe ? selectedRecipe.label.toUpperCase() : '\u00A0'}
              </h2>
              {/* Level Requirement - Right of recipe name */}
              {selectedRecipe && playerLevel.enabled && (
                <span className={`text-xs font-bold px-2 py-0.5 rounded flex items-center gap-1 ${
                  meetsLevelRequirement(selectedRecipe)
                    ? 'bg-[#4ade80]/20 text-[#4ade80]'
                    : 'bg-purple-500/20 text-purple-300'
                }`}>
                  <span className="text-[10px] opacity-70">{t('recipes.levelRequired')}</span>
                  <span className="font-bold">{selectedRecipe.levelRequired || 1}</span>
                  {!meetsLevelRequirement(selectedRecipe) && selectedRecipe.levelRequired && (
                    <span className="opacity-70">({playerLevel.level}/{selectedRecipe.levelRequired})</span>
                  )}
                </span>
              )}
              {/* Fail Chance Warning - Right of level badge */}
              {selectedRecipe?.failChance && selectedRecipe.failChance > 0 && (
                <span className="text-xs font-bold px-2 py-0.5 rounded flex items-center gap-1 bg-red-500/20 text-red-400">
                  <AlertCircle className="w-3 h-3" />
                  <span className="text-[10px] opacity-70">FAIL</span>
                  <span className="font-bold">{selectedRecipe.failChance}%</span>
                </span>
              )}
            </div>
            <div className="text-right">
              <span className="text-gray-500 text-[10px] block tracking-widest">{t('recipes.quantityOutput')}</span>
              <span className="text-white font-bold text-xl">{selectedRecipe ? `${craftQuantity} / ${(selectedRecipe.outputAmount ?? 1) * craftQuantity}` : '-'}</span>
            </div>
          </div>

          {/* Crafting Time & Rewards */}
          <div className="flex items-center gap-3 mb-3 flex-wrap">
            <span className="text-gray-400 text-sm font-semibold tracking-wide">{t('recipes.craftingTime')}</span>
            {selectedRecipe ? (
              <span className="bg-[#4ade80] text-black text-xs font-bold px-3 py-1 rounded">
                {selectedRecipe.craftTime * craftQuantity}s
              </span>
            ) : (
              <span className="text-gray-600">-</span>
            )}
            {selectedRecipe?.xpReward && playerLevel.enabled && (
              <>
                <span className="text-gray-400 text-sm font-semibold tracking-wide ml-2">{t('recipes.xpReward')}</span>
                <span className="bg-blue-500/30 text-blue-300 text-xs font-bold px-3 py-1 rounded">
                  +{selectedRecipe.xpReward * craftQuantity}
                </span>
              </>
            )}
            {selectedRecipe?.techPointsReward && techPoints.enabled && (
              <>
                <span className="text-gray-400 text-sm font-semibold tracking-wide ml-2">{t('recipes.techPointsReward')}</span>
                <span className="bg-purple-500/30 text-purple-300 text-xs font-bold px-3 py-1 rounded">
                  +{selectedRecipe.techPointsReward * craftQuantity}
                </span>
              </>
            )}
          </div>

          {/* Items Required / Tools Required */}
          <div className="mb-4">
            <span className="text-gray-400 text-sm font-semibold block mb-2 tracking-wide">
              {t('recipes.itemsRequired')}{selectedRecipe?.tools && selectedRecipe.tools.length > 0 && ` / ${t('recipes.toolsRequired')}`} {craftingInventoryConfig.enabled && <span className="text-gray-500 text-xs font-normal">{t('craftingInventory.fromCraftingInventory')}</span>}
            </span>
            <div className="flex flex-wrap gap-3 items-start">
              {selectedRecipe ? (
                <>
                  {selectedRecipe.ingredients.map((ing, idx) => {
                    const playerHas = craftingInventoryConfig.enabled ? getStagedCount(ing.item) : getInventoryCount(ing.item);
                    const needed = ing.amount * craftQuantity;
                    const hasEnough = playerHas >= needed;
                    return (
                      <div key={idx} className="flex flex-col items-center group relative">
                        <div className={`w-12 h-12 rounded bg-[#1a1a1f] border ${hasEnough ? 'border-white/10' : 'border-red-500/30'} flex items-center justify-center`}>
                          <ItemImage
                            src={getItemImage(ing.item, ing.image)}
                            alt={ing.label}
                            className="w-8 h-8 object-contain"
                            fallbackClassName="w-8 h-8 text-gray-600"
                          />
                        </div>
                        <span className={`text-xs mt-1 ${hasEnough ? 'text-white' : 'text-red-400'}`}>{playerHas}/{needed}</span>
                        {/* Tooltip */}
                        <div className="absolute -top-8 left-1/2 -translate-x-1/2 px-2 py-1 bg-black/90 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
                          {ing.label}
                        </div>
                      </div>
                    );
                  })}
                  {/* Cash Cost Display */}
                  {selectedRecipe.cost && selectedRecipe.cost > 0 && (
                    <div className="flex flex-col items-center group relative">
                      <div className="w-12 h-12 rounded bg-[#1a1a1f] border border-yellow-500/30 flex items-center justify-center">
                        <DollarSign className="w-8 h-8 text-yellow-400" />
                      </div>
                      <span className="text-xs mt-1 text-yellow-400">${(selectedRecipe.cost * craftQuantity).toLocaleString()}</span>
                      {/* Tooltip */}
                      <div className="absolute -top-8 left-1/2 -translate-x-1/2 px-2 py-1 bg-black/90 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
                        Cash
                      </div>
                    </div>
                  )}
                  {/* Tools Required - Separator and Tools */}
                  {selectedRecipe.tools && selectedRecipe.tools.length > 0 && (
                    <>
                      {/* Vertical Separator */}
                      <div className="flex flex-col items-center justify-center mx-2 self-center">
                        <div className="w-px h-4 bg-gradient-to-b from-transparent to-gray-500/40" />
                        <div className="w-1.5 h-1.5 rounded-full bg-gray-500/40 my-0.5" />
                        <div className="w-px h-4 bg-gradient-to-t from-transparent to-gray-500/40" />
                      </div>
                      {selectedRecipe.tools.map((tool, idx) => {
                        const playerHas = craftingInventoryConfig.enabled ? getStagedCount(tool.item) : getInventoryCount(tool.item);
                        const needed = tool.consumptionType === 'consume' ? tool.amount * craftQuantity : tool.amount;
                        const hasEnough = playerHas >= needed;

                        const getConsumptionBadge = () => {
                          switch (tool.consumptionType) {
                            case 'none':
                              return null;
                            case 'durability':
                              return (
                                <span className="absolute -top-1 -right-1 bg-orange-500/80 text-white text-[8px] px-1 rounded font-bold">
                                  DUR
                                </span>
                              );
                            case 'chance':
                              return (
                                <span className="absolute -top-1 -right-1 bg-yellow-500/80 text-white text-[8px] px-1 rounded font-bold">
                                  {tool.consumeChance}%
                                </span>
                              );
                            case 'consume':
                              return (
                                <span className="absolute -top-1 -right-1 bg-red-500/80 text-white text-[8px] px-1 rounded font-bold">
                                  USE
                                </span>
                              );
                            default:
                              return null;
                          }
                        };

                        return (
                          <div key={`tool-${idx}`} className="flex flex-col items-center group relative">
                            <div className={`w-12 h-12 rounded bg-[#1a1a1f] border ${hasEnough ? 'border-white/10' : 'border-red-500/30'} flex items-center justify-center relative`}>
                              <ItemImage
                                src={getItemImage(tool.item, tool.image)}
                                alt={tool.label}
                                className="w-8 h-8 object-contain"
                                fallbackClassName="w-8 h-8 text-gray-600"
                              />
                              {getConsumptionBadge()}
                            </div>
                            <span className={`text-xs mt-1 ${hasEnough ? 'text-white' : 'text-red-400'}`}>{playerHas}/{needed}</span>
                            {/* Tooltip */}
                            <div className="absolute -top-12 left-1/2 -translate-x-1/2 px-2 py-1 bg-black/90 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
                              <div>{tool.label}</div>
                              <div className="text-gray-400 text-[10px]">
                                {tool.consumptionType === 'none' && t('recipes.toolNotConsumed')}
                                {tool.consumptionType === 'durability' && t('recipes.toolDurability', { loss: tool.durabilityLoss || 10 })}
                                {tool.consumptionType === 'chance' && t('recipes.toolChance', { chance: tool.consumeChance || 25 })}
                                {tool.consumptionType === 'consume' && t('recipes.toolConsumed')}
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </>
                  )}
                </>
              ) : (
                <span className="text-gray-600 text-sm">{t('recipes.selectRecipe')}</span>
              )}
            </div>
          </div>

          {/* Quantity Controls & Add to Queue */}
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <span className="text-gray-400 text-sm font-semibold tracking-wide">{t('recipes.quantity')}</span>
              <div className="flex items-center bg-[#1a1a1f] rounded-lg overflow-hidden">
                <button
                  onClick={() => setCraftQuantity(q => Math.max(1, q - 1))}
                  disabled={!selectedRecipe}
                  className={`w-9 h-9 flex items-center justify-center text-white hover:bg-white/10 transition-colors disabled:opacity-30 ${
                    craftQuantity <= 1 ? 'opacity-30 cursor-not-allowed' : ''
                  }`}
                >
                  <span className="text-lg">-</span>
                </button>
                <input
                  type="number"
                  min="1"
                  max={selectedRecipe ? getMaxCraftable(selectedRecipe) : 99}
                  value={craftQuantity}
                  onChange={(e) => {
                    const val = parseInt(e.target.value) || 1;
                    const max = selectedRecipe ? getMaxCraftable(selectedRecipe) : 99;
                    setCraftQuantity(Math.max(1, Math.min(max, val)));
                  }}
                  disabled={!selectedRecipe}
                  className="w-12 h-9 text-center text-white font-bold text-sm bg-transparent focus:outline-none focus:bg-white/5 disabled:opacity-50 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                />
                <button
                  onClick={() => {
                    if (selectedRecipe) {
                      const max = getMaxCraftable(selectedRecipe);
                      if (max < 1) return;
                      const blueprintDurabilityInfo = getBlueprintDurabilityLimit(selectedRecipe);
                      const toolDurabilityInfo = getToolDurabilityLimit(selectedRecipe);
                      // Check if all crafts are already in queue (blueprint)
                      if (blueprintDurabilityInfo && blueprintDurabilityInfo.limited && blueprintDurabilityInfo.maxCrafts <= 0) {
                        showToast(t('recipes.blueprintLimitNoMore', { queued: blueprintDurabilityInfo.queuedCrafts }), 'error');
                      } else if (craftQuantity >= max && blueprintDurabilityInfo && blueprintDurabilityInfo.limited) {
                        showToast(t('recipes.blueprintLimitMax', { max: blueprintDurabilityInfo.maxCrafts, queued: blueprintDurabilityInfo.queuedCrafts }), 'info');
                      // Check tool durability limits
                      } else if (toolDurabilityInfo && toolDurabilityInfo.limited && toolDurabilityInfo.maxCrafts <= 0) {
                        showToast(t('recipes.toolDurabilityNoMore', { tool: toolDurabilityInfo.toolName, queued: toolDurabilityInfo.queuedCrafts }), 'error');
                      } else if (craftQuantity >= max && toolDurabilityInfo && toolDurabilityInfo.limited) {
                        showToast(t('recipes.toolDurabilityLimit', { tool: toolDurabilityInfo.toolName, max: toolDurabilityInfo.maxCrafts }), 'info');
                      } else {
                        setCraftQuantity(q => Math.min(max, q + 1));
                      }
                    }
                  }}
                  disabled={!selectedRecipe}
                  title={(() => {
                    if (!selectedRecipe) return undefined;
                    const blueprintInfo = getBlueprintDurabilityLimit(selectedRecipe);
                    const toolInfo = getToolDurabilityLimit(selectedRecipe);
                    if (blueprintInfo && blueprintInfo.limited && blueprintInfo.maxCrafts <= 0) return t('recipes.blueprintLimitReached');
                    if (craftQuantity >= getMaxCraftable(selectedRecipe) && blueprintInfo?.limited) return t('recipes.blueprintLimitReached');
                    if (toolInfo && toolInfo.limited && toolInfo.maxCrafts <= 0) return t('recipes.toolDurabilityLimitReached', { tool: toolInfo.toolName });
                    if (craftQuantity >= getMaxCraftable(selectedRecipe) && toolInfo?.limited) return t('recipes.toolDurabilityLimitReached', { tool: toolInfo.toolName });
                    return undefined;
                  })()}
                  className={`w-9 h-9 flex items-center justify-center text-white hover:bg-white/10 transition-colors disabled:opacity-30 ${
                    selectedRecipe && (() => {
                      const max = getMaxCraftable(selectedRecipe);
                      if (max < 1) return true;
                      const blueprintInfo = getBlueprintDurabilityLimit(selectedRecipe);
                      const toolInfo = getToolDurabilityLimit(selectedRecipe);
                      if (blueprintInfo && blueprintInfo.limited && blueprintInfo.maxCrafts <= 0) return true;
                      if (craftQuantity >= max && blueprintInfo?.limited) return true;
                      if (toolInfo && toolInfo.limited && toolInfo.maxCrafts <= 0) return true;
                      if (craftQuantity >= max && toolInfo?.limited) return true;
                      return false;
                    })() ? 'opacity-30 cursor-not-allowed' : ''
                  }`}
                >
                  <span className="text-lg">+</span>
                </button>
              </div>
            </div>

            <button
              onClick={handleAddToQueue}
              disabled={!selectedRecipe || !canCraft(selectedRecipe, craftQuantity) || (() => {
                if (!selectedRecipe) return false;
                const blueprintInfo = getBlueprintDurabilityLimit(selectedRecipe);
                const toolInfo = getToolDurabilityLimit(selectedRecipe);
                if (blueprintInfo && blueprintInfo.limited && craftQuantity > blueprintInfo.maxCrafts) return true;
                if (toolInfo && toolInfo.limited && craftQuantity > toolInfo.maxCrafts) return true;
                return false;
              })()}
              className="flex-1 py-2.5 px-4 rounded-lg font-bold text-sm tracking-wider bg-[#1a1a1f] text-gray-300 hover:bg-[#252528] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {t('recipes.addToQueue')}
            </button>
          </div>
        </div>

            {/* Queue Divider */}
            <div className="mx-5 border-t border-white/10 mt-2" />

            {/* Queue Section */}
            <div className="px-5 pt-3 pb-4 flex-1 flex flex-col min-h-0">
              <span className="text-gray-400 text-sm font-semibold block mb-2 tracking-wide">{t('recipes.queue')}</span>
              <div className="space-y-2 flex-1 overflow-y-auto">
                {queue.length > 0 ? (
                  queue.map((item, index) => {
                    const completionState = completingItems.get(item.id);
                    const isCompleting = !!completionState;
                    const completionStatus = completionState?.status || 'success';
                    const isAnimating = completionState?.animating || false;

                    return (
                      <div
                        key={item.id}
                        className={`queue-item flex items-center gap-3 bg-[#1a1a1f] rounded-lg p-2.5 animate-slideInUp ${
                          isCompleting ? `queue-item-completing ${completionStatus}` : ''
                        }`}
                      >
                        {/* Completion progress overlay */}
                        {isCompleting && (
                          <div className="queue-item-completion-overlay">
                            <div className={`queue-completion-progress ${completionStatus} ${isAnimating ? 'animate' : ''}`} />
                          </div>
                        )}
                        <div className="w-10 h-10 rounded bg-[#252528] flex-shrink-0 flex items-center justify-center relative z-20">
                          <ItemImage
                            src={getItemImage(item.recipe.name, item.recipe.image)}
                            alt={item.recipe.label}
                            className="w-7 h-7 object-contain"
                            fallbackClassName="w-7 h-7 text-gray-600"
                          />
                        </div>
                        <div className="flex-1 min-w-0 relative z-20">
                          <span className="text-white text-sm font-medium truncate block">{item.recipe.label}</span>
                          {sharedCrafting && item.ownerName && !item.isOwnItem && (
                            <span className="text-gray-500 text-xs truncate block">{item.ownerName}</span>
                          )}
                        </div>
                        <span className="text-gray-400 text-sm relative z-20">
                          {t('recipes.qty')} {item.quantity}
                          {(item.recipe.outputAmount ?? 1) > 1 && (
                            <>, {t('recipes.out')} {item.quantity * (item.recipe.outputAmount ?? 1)}</>
                          )}
                        </span>
                        <span className="text-white text-sm font-bold ml-2 relative z-20">
                          {index === 0 ? `${item.remainingTime}s` : `${item.totalTime}s`}
                        </span>
                        {item.isOwnItem !== false && (
                          <button
                            onClick={() => handleRemoveFromQueue(item.id)}
                            className="p-1 hover:bg-red-500/20 rounded relative z-20"
                            title="Cancel craft"
                          >
                            <X className="w-4 h-4 text-gray-500 hover:text-red-400" />
                          </button>
                        )}
                      </div>
                    );
                  })
                ) : (
                  <div className="text-gray-600 text-sm py-2">{t('recipes.noQueueItems')}</div>
                )}
              </div>
            </div>
          </>
        )}

        {/* Blueprints Tab Content */}
        {activeTab === 'blueprints' && (
          <div className="flex-1 flex flex-col px-5 pb-4 overflow-hidden">
            {/* Search Bar */}
            <div className="pb-3">
              <div className="relative">
                <input
                  type="text"
                  placeholder={t('blueprints.searchPlaceholder')}
                  value={blueprintSearchTerm}
                  onChange={(e) => setBlueprintSearchTerm(e.target.value)}
                  onClick={(e) => { e.stopPropagation(); (e.target as HTMLInputElement).focus(); }}
                  onMouseDown={(e) => e.stopPropagation()}
                  className="w-full bg-[#1a1a1f] rounded-lg pl-4 pr-10 py-2.5 text-white text-sm placeholder-gray-600 focus:outline-none border border-transparent focus:border-white/10"
                />
                <Search className="w-4 h-4 text-gray-500 absolute right-3 top-1/2 -translate-y-1/2" />
              </div>
            </div>

            <div className="flex-1 overflow-y-auto space-y-4">
              {/* Attached Blueprints Section */}
              <div>
                <span className="text-gray-400 text-xs font-semibold block mb-2 tracking-wide">{t('blueprints.attachedToStation')}</span>
                {attachedBlueprints.filter(bp => validBlueprintItems.includes(bp)).length > 0 ? (
                  <div className="space-y-2">
                    {attachedBlueprints
                      .filter(bp => validBlueprintItems.includes(bp) && bp.toLowerCase().includes(blueprintSearchTerm.toLowerCase()))
                      .map(blueprintItem => {
                        // Find recipe that uses this blueprint (on this workbench)
                        const recipe = recipes.find(r => r.blueprint === blueprintItem);
                        const isUsable = !!recipe;
                        // Get label from attachedWithLabels (which has the actual blueprint item label from server)
                        const attachedData = attachedWithLabels.find(a => a.item === blueprintItem);
                        const blueprintLabel = attachedData?.label
                          ?? (recipe ? `${recipe.label} ${t('blueprints.suffix')}` : `${blueprintItem.replace(/_/g, ' ')} ${t('blueprints.suffix')}`);
                        return (
                          <div key={blueprintItem} className={`flex items-center gap-3 rounded-lg p-3 animate-slideInUp ${isUsable ? 'bg-[#2d4a2d]' : 'bg-[#4a2d2d]'}`}>
                            <div className={`w-10 h-10 rounded flex-shrink-0 flex items-center justify-center ${isUsable ? 'bg-[#1a1a1f]' : 'bg-[#2a1a1a]'}`}>
                              <ItemImage
                                src={getItemImage(blueprintItem)}
                                alt={blueprintItem}
                                className={`w-7 h-7 object-contain ${isUsable ? '' : 'opacity-50'}`}
                                fallbackSvg="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%234ade80'><path d='M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'/></svg>"
                              />
                            </div>
                            <div className="flex-1 min-w-0">
                              <span className={`text-sm font-medium block truncate ${isUsable ? 'text-white' : 'text-gray-400'}`}>
                                {blueprintLabel}
                              </span>
                              {isUsable ? (
                                <span className="text-green-400 text-xs">{t('blueprints.active')}</span>
                              ) : (
                                <span className="text-red-400 text-xs flex items-center gap-1">
                                  <AlertCircle className="w-3 h-3" />
                                  {t('blueprints.unavailableOnWorkbench')}
                                </span>
                              )}
                            </div>
                            {!craftingInventoryConfig.enabled && (
                              <button
                                onClick={() => handleDetachBlueprint(blueprintItem)}
                                className="px-3 py-1.5 bg-red-500/20 hover:bg-red-500/30 text-red-400 text-xs font-semibold rounded transition-colors"
                              >
                                {t('blueprints.detach')}
                              </button>
                            )}
                          </div>
                        );
                      })}
                  </div>
                ) : (
                  <div className="text-gray-600 text-sm py-2">{t('blueprints.noAttached')}</div>
                )}
              </div>

              {/* Player's Blueprints Section - Only show when staging is disabled */}
              {!craftingInventoryConfig.enabled && (
                <>
                  {/* Divider */}
                  <div className="border-t border-white/10" />

                  <div>
                    <span className="text-gray-400 text-xs font-semibold block mb-2 tracking-wide">{t('blueprints.yourBlueprints')}</span>
                    {playerBlueprints.length > 0 ? (
                      <div className="space-y-2">
                        {playerBlueprints
                          .filter(bp => bp.label.toLowerCase().includes(blueprintSearchTerm.toLowerCase()) || bp.recipeLabel.toLowerCase().includes(blueprintSearchTerm.toLowerCase()))
                          .map(blueprint => (
                            <div key={blueprint.item} className="flex items-center gap-3 bg-[#1a1a1f] rounded-lg p-3 animate-slideInUp">
                              <div className="w-10 h-10 rounded bg-[#252528] flex-shrink-0 flex items-center justify-center">
                                <ItemImage
                                  src={getItemImage(blueprint.item)}
                                  alt={blueprint.label}
                                  className="w-7 h-7 object-contain"
                                  fallbackSvg="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23666'><path d='M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'/></svg>"
                                />
                              </div>
                              <div className="flex-1 min-w-0">
                                <span className="text-white text-sm font-medium block truncate">{blueprint.recipeLabel}</span>
                                <span className="text-gray-500 text-xs">{t('blueprints.inInventory', { count: blueprint.count })}</span>
                              </div>
                              <button
                                onClick={() => handleAttachBlueprint(blueprint.item)}
                                className="px-3 py-1.5 bg-green-500/20 hover:bg-green-500/30 text-green-400 text-xs font-semibold rounded transition-colors"
                              >
                                {t('blueprints.attach')}
                              </button>
                            </div>
                          ))}
                      </div>
                    ) : (
                      <div className="text-center py-8">
                        <div className="w-12 h-12 mx-auto mb-3 rounded-lg bg-[#1a1a1f] flex items-center justify-center">
                          <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                          </svg>
                        </div>
                        <p className="text-gray-500 text-sm">{t('blueprints.noInInventory')}</p>
                        <p className="text-gray-600 text-xs mt-1">{t('blueprints.findBlueprints')}</p>
                      </div>
                    )}
                  </div>
                </>
              )}
            </div>
          </div>
        )}

        {/* Tech Tree Tab Content */}
        {activeTab === 'techtree' && techTreeConfig.enabled && techTreeConfig.trees && (
          <div className="flex-1 flex flex-col px-5 pb-4 overflow-hidden relative">
            {/* Tech Points Display */}
            <div className="pb-3">
              <div className="flex items-center justify-between bg-[#1a1a1f] rounded-lg px-4 py-2.5">
                <div className="flex items-center gap-2">
                  <svg className="w-5 h-5 text-[#4ade80]" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                  <span className="text-white font-bold text-lg">{techPoints.points}</span>
                  <span className="text-gray-500 text-sm">{t('techTree.points')}</span>
                </div>
                <span className="text-gray-600 text-xs">{t('techTree.earnPoints')}</span>
              </div>
            </div>

            {/* Tree Selector Tabs */}
            <div className="pb-3 flex gap-2 overflow-x-auto">
              {Object.entries(techTreeConfig.trees).map(([treeId, tree]) => (
                <button
                  key={treeId}
                  onClick={() => { setSelectedTree(treeId); setSelectedNode(null); setTechTreePan({ x: 0, y: 0 }); setTechTreeZoom(1); }}
                  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all whitespace-nowrap flex-shrink-0 ${
                    selectedTree === treeId
                      ? 'text-white'
                      : 'text-gray-500 hover:text-gray-300 hover:bg-white/5'
                  }`}
                  style={{
                    backgroundColor: selectedTree === treeId ? tree.color + '30' : 'transparent',
                    borderColor: selectedTree === treeId ? tree.color : 'transparent',
                    borderWidth: '1px'
                  }}
                >
                  {tree.label}
                </button>
              ))}
            </div>

            {/* Tree Visualization Area */}
            <div
              ref={techTreeRefCallback}
              className={`flex-1 overflow-hidden relative ${isPanningTechTree ? 'cursor-grabbing' : 'cursor-grab'}`}
              onMouseDown={(e) => {
                if (e.button === 0 && (e.target as HTMLElement).closest('.tech-tree-content')) {
                  setIsPanningTechTree(true);
                  setPanStart({ x: e.clientX - techTreePan.x, y: e.clientY - techTreePan.y });
                }
              }}
              onMouseMove={(e) => {
                if (isPanningTechTree && techTreeContainerRef.current) {
                  const container = techTreeContainerRef.current;
                  const containerRect = container.getBoundingClientRect();

                  const contentEl = container.querySelector('.tech-tree-content > div') as HTMLElement | null;
                  const contentWidth = contentEl ? contentEl.offsetWidth * techTreeZoom : containerRect.width;
                  const contentHeight = contentEl ? contentEl.offsetHeight * techTreeZoom : containerRect.height;

                  const maxPanX = Math.max(containerRect.width * 0.5, (contentWidth - containerRect.width) / 2 + containerRect.width * 0.3);
                  const maxPanY = Math.max(containerRect.height * 0.5, (contentHeight - containerRect.height) / 2 + containerRect.height * 0.3);

                  const newX = e.clientX - panStart.x;
                  const newY = e.clientY - panStart.y;

                  setTechTreePan({
                    x: Math.max(-maxPanX, Math.min(maxPanX, newX)),
                    y: Math.max(-maxPanY, Math.min(maxPanY, newY))
                  });
                }
              }}
              onMouseUp={() => setIsPanningTechTree(false)}
              onMouseLeave={() => setIsPanningTechTree(false)}
            >
              {selectedTree && techTreeConfig.trees[selectedTree] && (() => {
                const currentTree = techTreeConfig.trees[selectedTree];

                const isUnlocked = (nodeId: string) => unlockedNodes[`${selectedTree}:${nodeId}`] === true;
                const canUnlock = (node: TechTreeNode) => {
                  if (isUnlocked(node.id)) return false;
                  if (techPoints.points < node.cost) return false;
                  for (const prereqId of node.prerequisites) {
                    if (!isUnlocked(prereqId)) return false;
                  }
                  return true;
                };
                const getRecipeForNode = (node: TechTreeNode) => recipes.find(r => r.id === node.recipeId);

                let minRow = Infinity, maxRow = 0, minCol = Infinity, maxCol = 0;
                currentTree.nodes.forEach(n => {
                  minRow = Math.min(minRow, n.position.row);
                  maxRow = Math.max(maxRow, n.position.row);
                  minCol = Math.min(minCol, n.position.col);
                  maxCol = Math.max(maxCol, n.position.col);
                });

                const nodeSize = 90;
                const gapX = 140;
                const gapY = 120;
                const padding = 50;

                const gridWidth = (maxCol - minCol) * gapX + nodeSize;
                const gridHeight = (maxRow - minRow) * gapY + nodeSize;

                const getNodeX = (col: number) => (col - minCol) * gapX;
                const getNodeY = (row: number) => (row - minRow) * gapY;

                return (
                  <div
                    className="tech-tree-content flex items-center justify-center min-h-full w-full py-4"
                    style={{
                      transform: `translate(${techTreePan.x}px, ${techTreePan.y}px) scale(${techTreeZoom})`,
                      transition: isPanningTechTree ? 'none' : 'transform 0.15s ease-out'
                    }}
                  >
                    <div
                      className="relative tech-grid-animate"
                      style={{
                        width: gridWidth + padding * 2,
                        height: gridHeight + padding * 2,
                        minWidth: 400
                      }}
                    >
                      {/* SVG for connection lines */}
                      <svg
                        className="absolute pointer-events-none"
                        style={{
                          left: padding,
                          top: padding,
                          width: gridWidth,
                          height: gridHeight
                        }}
                      >
                        {currentTree.nodes.map(node =>
                          node.prerequisites.map(prereqId => {
                            const prereq = currentTree.nodes.find(n => n.id === prereqId);
                            if (!prereq) return null;

                            const x1 = getNodeX(prereq.position.col) + nodeSize / 2;
                            const y1 = getNodeY(prereq.position.row) + nodeSize;
                            const x2 = getNodeX(node.position.col) + nodeSize / 2;
                            const y2 = getNodeY(node.position.row);

                            const isPrereqUnlocked = isUnlocked(prereqId);
                            const isNodeUnlockedState = isUnlocked(node.id);

                            const midY = (y1 + y2) / 2;

                            return (
                              <path
                                key={`${prereqId}-${node.id}`}
                                d={`M ${x1} ${y1} C ${x1} ${midY}, ${x2} ${midY}, ${x2} ${y2}`}
                                stroke={isNodeUnlockedState ? currentTree.color : isPrereqUnlocked ? '#6b7280' : '#374151'}
                                strokeWidth={2}
                                strokeDasharray={isNodeUnlockedState ? '' : '6 4'}
                                fill="none"
                              />
                            );
                          })
                        )}
                      </svg>

                      {/* Node Grid */}
                      {currentTree.nodes.map(node => {
                        const recipe = getRecipeForNode(node);
                        const unlocked = isUnlocked(node.id);
                        const available = canUnlock(node);
                        const isSelected = selectedNode?.id === node.id;

                        return (
                          <button
                            key={node.id}
                            onClick={() => setSelectedNode(node)}
                            className={`absolute rounded-xl border-2 flex flex-col items-center justify-center transition-all duration-200 hover:scale-110 ${
                              isSelected ? 'ring-2 ring-white ring-offset-2 ring-offset-[#0c0c0e]' : ''
                            } ${available ? 'tech-node-available' : ''}`}
                            style={{
                              left: getNodeX(node.position.col) + padding,
                              top: getNodeY(node.position.row) + padding,
                              width: nodeSize,
                              height: nodeSize,
                              backgroundColor: unlocked ? currentTree.color + '25' : available ? '#1f1f24' : '#18181b',
                              borderColor: unlocked ? currentTree.color : available ? currentTree.color : '#3f3f46',
                              opacity: unlocked || available ? 1 : 0.6,
                              boxShadow: unlocked
                                ? `0 0 20px ${currentTree.color}40, inset 0 0 15px ${currentTree.color}15`
                                : available
                                  ? `0 0 15px ${currentTree.color}25`
                                  : 'none',
                            }}
                          >
                            {recipe ? (
                              <>
                                <ItemImage
                                  src={getItemImage(recipe.name, recipe.image)}
                                  alt={recipe.label}
                                  className={`w-12 h-12 object-contain ${!unlocked && !available ? 'grayscale opacity-60' : ''}`}
                                  fallbackClassName={`w-12 h-12 text-gray-600 ${!unlocked && !available ? 'opacity-60' : ''}`}
                                />
                                {!unlocked && (
                                  <div className="absolute -bottom-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-black/80 text-white border border-white/10">
                                    {node.cost} TP
                                  </div>
                                )}
                                {unlocked && (
                                  <div
                                    className="absolute -top-1 -right-1 w-5 h-5 rounded-full flex items-center justify-center"
                                    style={{ backgroundColor: currentTree.color }}
                                  >
                                    <svg className="w-3 h-3" fill="white" viewBox="0 0 20 20">
                                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                    </svg>
                                  </div>
                                )}
                              </>
                            ) : (
                              <span className="text-gray-500 text-[10px]">{t('techTree.unknown')}</span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                );
              })()}

              {!selectedTree && (
                <div className="flex flex-col items-center justify-center h-full text-gray-500 py-8">
                  <svg className="w-12 h-12 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                  </svg>
                  <span>{t('techTree.selectTree')}</span>
                </div>
              )}

              {/* Pan/Zoom hints */}
              {selectedTree && (
                <>
                  <div className="pan-hint">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 11.5V14m0-2.5v-6a1.5 1.5 0 113 0m-3 6a1.5 1.5 0 00-3 0v2a7.5 7.5 0 0015 0v-5a1.5 1.5 0 00-3 0m-6-3V11m0-5.5v-1a1.5 1.5 0 013 0v1m0 0V11m0-5.5a1.5 1.5 0 013 0v3m0 0V11" />
                    </svg>
                    <span>{t('techTree.dragToPan')}</span>
                    <span className="text-white/30 mx-1">|</span>
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" className="w-3.5 h-3.5">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v6m3-3H7" />
                    </svg>
                    <span>{t('techTree.scrollToZoom')}</span>
                  </div>
                  {/* Zoom indicator */}
                  <div className="absolute top-3 right-3 bg-black/60 px-2.5 py-1 rounded-lg text-xs text-white/70 font-medium">
                    {Math.round(techTreeZoom * 100)}%
                  </div>
                </>
              )}
            </div>

            {/* Node Details Panel - Overlay */}
            {selectedNode && selectedTree && techTreeConfig.trees[selectedTree] && (() => {
              const currentTree = techTreeConfig.trees[selectedTree];
              const recipe = recipes.find(r => r.id === selectedNode.recipeId);
              const unlocked = unlockedNodes[`${selectedTree}:${selectedNode.id}`] === true;
              const prereqsMet = selectedNode.prerequisites.every(prereqId => unlockedNodes[`${selectedTree}:${prereqId}`] === true);
              const available = !unlocked && prereqsMet && techPoints.points >= selectedNode.cost;

              const handleUnlock = async () => {
                await fetchNui('unlockTechNode', { treeId: selectedTree, nodeId: selectedNode.id });
              };

              return (
                <div className="absolute bottom-4 left-4 right-4 bg-[#1a1a1f]/95 backdrop-blur-sm rounded-xl p-4 border border-white/10 shadow-2xl z-20 animate-slideInUp">
                  {/* Close button */}
                  <button
                    onClick={() => setSelectedNode(null)}
                    className="absolute top-3 right-3 w-6 h-6 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
                  >
                    <svg className="w-3.5 h-3.5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>

                  <div className="flex items-center gap-3 mb-3 pr-8">
                    {recipe && (
                      <div className="w-12 h-12 rounded bg-[#252528] flex items-center justify-center flex-shrink-0">
                        <ItemImage
                          src={getItemImage(recipe.name, recipe.image)}
                          alt={recipe.label}
                          className="w-9 h-9 object-contain"
                          fallbackClassName="w-9 h-9 text-gray-600"
                        />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="text-white font-bold text-lg truncate">
                          {recipe?.label || selectedNode.id}
                        </span>
                        {recipe?.blueprint && (
                          <span className="text-xs px-1.5 py-0.5 rounded bg-purple-500/20 text-purple-400 border border-purple-500/30 flex items-center gap-1 flex-shrink-0">
                            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                            </svg>
                            {t('techTree.blueprintRequired')}
                          </span>
                        )}
                      </div>
                      <span className={`text-sm ${unlocked ? 'text-[#4ade80]' : available ? 'text-yellow-400' : 'text-gray-400'}`}>
                        {unlocked ? t('techTree.unlocked') : available ? t('techTree.available') : t('techTree.locked')}
                      </span>
                    </div>
                  </div>

                  {!unlocked && (
                    <div className="flex items-center gap-3">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-gray-400 text-sm">{t('techTree.cost')}</span>
                          <span className={`font-bold ${techPoints.points >= selectedNode.cost ? 'text-[#4ade80]' : 'text-red-400'}`}>
                            {selectedNode.cost} TP
                          </span>
                        </div>
                        {selectedNode.prerequisites.length > 0 && (
                          <div className="flex flex-wrap gap-1">
                            {selectedNode.prerequisites.map(prereqId => {
                              const prereqUnlocked = unlockedNodes[`${selectedTree}:${prereqId}`] === true;
                              const prereqNode = currentTree.nodes.find(n => n.id === prereqId);
                              const prereqRecipe = prereqNode ? recipes.find(r => r.id === prereqNode.recipeId) : null;
                              return (
                                <span
                                  key={prereqId}
                                  className={`text-xs px-2 py-0.5 rounded ${
                                    prereqUnlocked ? 'bg-[#4ade80]/20 text-[#4ade80]' : 'bg-red-500/20 text-red-400'
                                  }`}
                                >
                                  {prereqRecipe?.label || prereqId}
                                </span>
                              );
                            })}
                          </div>
                        )}
                      </div>
                      <button
                        onClick={handleUnlock}
                        disabled={!available}
                        className={`px-6 py-2.5 rounded-lg font-bold text-sm transition-all flex-shrink-0 ${
                          available
                            ? 'bg-[#4ade80] text-black hover:bg-[#22c55e]'
                            : 'bg-gray-700 text-gray-400 cursor-not-allowed'
                        }`}
                      >
                        {available ? t('techTree.unlock') : prereqsMet ? t('techTree.needPoints') : t('techTree.locked').toUpperCase()}
                      </button>
                    </div>
                  )}

                  {unlocked && recipe && (
                    <div className="flex items-center gap-3 text-gray-400 text-sm">
                      <span>Craft Time: {recipe.craftTime}s</span>
                      {recipe.ingredients && (
                        <div className="flex flex-wrap gap-1.5">
                          {recipe.ingredients.map((ing, idx) => (
                            <div key={idx} className="flex items-center gap-1 bg-[#252528] rounded px-2 py-1">
                              <ItemImage
                                src={getItemImage(ing.item, ing.image)}
                                alt={ing.label}
                                className="w-4 h-4 object-contain"
                                fallbackClassName="w-4 h-4 text-gray-600"
                              />
                              <span className="text-xs text-gray-300">{ing.amount}x</span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })()}
          </div>
        )}

        {/* Permissions Tab */}
        {activeTab === 'permissions' && permissionsEnabled && isPlacedWorkbench && isWorkbenchOwner && (
          <div className="flex-1 flex flex-col px-5 pb-4 overflow-hidden">
            <h2 className="text-white font-bold text-lg mb-4">{t('permissions.title')}</h2>

            {/* Add Player Input */}
            <div className="flex gap-2 mb-4">
              <div className="flex-1 relative flex items-center">
                <input
                  type="number"
                  value={sourceInput}
                  onChange={(e) => setSourceInput(e.target.value)}
                  placeholder={t('permissions.sourceInputPlaceholder')}
                  className="w-full bg-[#1a1a1f] text-white text-sm px-4 py-2 rounded-l-lg border border-white/10 focus:outline-none focus:border-[#4ade80]/50 placeholder-gray-500 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                  min="1"
                />
                <div className="flex flex-col border border-l-0 border-white/10 rounded-r-lg overflow-hidden self-stretch">
                  <button
                    onClick={() => setSourceInput(s => String(Math.min(999, (parseInt(s) || 0) + 1)))}
                    className="px-1.5 flex-1 bg-[#1a1a1f] hover:bg-[#2a2a2f] text-gray-400 hover:text-white transition-colors flex items-center justify-center"
                  >
                    <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clipRule="evenodd" /></svg>
                  </button>
                  <button
                    onClick={() => setSourceInput(s => String(Math.max(1, (parseInt(s) || 0) - 1)))}
                    className="px-1.5 flex-1 bg-[#1a1a1f] hover:bg-[#2a2a2f] text-gray-400 hover:text-white transition-colors border-t border-white/10 flex items-center justify-center"
                  >
                    <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" /></svg>
                  </button>
                </div>
              </div>
              <button
                onClick={async () => {
                  if (!sourceInput.trim()) return;
                  const res = await fetchNui<{ success: boolean; message?: string }>('addPermission', { sourceId: parseInt(sourceInput) });
                  if (res.success) {
                    showToast(t('permissions.playerAdded'), 'success');
                    // Refresh permissions list
                    const permRes = await fetchNui<{ success: boolean; permissions: PermissionEntry[] }>('getPermissions');
                    if (permRes.success) setPermissions(permRes.permissions);
                    setSourceInput('');
                  } else {
                    showToast(res.message || t('permissions.invalidSource'), 'error');
                  }
                }}
                disabled={!sourceInput.trim()}
                className="px-4 py-2 bg-[#4ade80] text-black font-bold text-sm rounded-lg hover:bg-[#22c55e] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {t('permissions.add')}
              </button>
            </div>

            {/* Allowed Players List */}
            <div className="flex-1 overflow-y-auto">
              <h3 className="text-gray-400 text-sm font-semibold mb-2">{t('permissions.allowedPlayers')}</h3>

              {permissions.length === 0 ? (
                <div className="text-gray-500 text-sm py-4 text-center">
                  {t('permissions.noPlayersAllowed')}
                </div>
              ) : (
                <div className="space-y-2">
                  {permissions.map((perm) => (
                    <div
                      key={perm.identifier}
                      className="flex items-center justify-between bg-[#1a1a1f] rounded-lg px-4 py-3 border border-white/10"
                    >
                      <div>
                        <span className="text-white font-medium">{perm.name}</span>
                        <span className="text-gray-500 text-xs block">{perm.identifier}</span>
                      </div>
                      <button
                        onClick={async () => {
                          const res = await fetchNui<{ success: boolean; message?: string }>('removePermission', { identifier: perm.identifier });
                          if (res.success) {
                            showToast(t('permissions.playerRemoved'), 'success');
                            setPermissions(prev => prev.filter(p => p.identifier !== perm.identifier));
                          } else {
                            showToast(res.message || 'Failed to remove player', 'error');
                          }
                        }}
                        className="px-3 py-1 bg-red-500/20 text-red-400 text-xs font-bold rounded hover:bg-red-500/30 transition-colors"
                      >
                        {t('permissions.remove')}
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {/* History Tab */}
        {activeTab === 'history' && historyEnabled && isPlacedWorkbench && (
          <div className="flex-1 flex flex-col px-5 pb-4 min-h-0">
            <h2 className="text-white font-bold text-lg mb-4">{t('history.title')}</h2>

            {history.length === 0 ? (
              <div className="text-gray-500 text-sm py-4 text-center">
                {t('history.noHistory')}
              </div>
            ) : (
              <div className="flex-1 overflow-y-auto pt-9 -mt-9 space-y-2" style={{ clipPath: 'inset(-36px 0 0 0)' }}>
                {history.map((entry, index) => (
                  <div
                    key={index}
                    className="bg-[#1a1a1f] rounded-lg p-3 border border-white/5 hover:border-white/10 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      {/* Ingredients */}
                      <div className="flex items-center gap-1.5 flex-wrap">
                        {entry.ingredients && entry.ingredients.length > 0 ? (
                          entry.ingredients.map((ing, idx) => (
                            <div key={idx} className="flex flex-col items-center group relative">
                              <div className="w-12 h-12 rounded-lg bg-[#252528] border border-white/10 flex items-center justify-center">
                                <ItemImage
                                  src={getItemImage(ing.item, ing.image)}
                                  alt={ing.label}
                                  className="w-8 h-8 object-contain"
                                  fallbackClassName="w-8 h-8 text-gray-600"
                                />
                              </div>
                              <span className="text-[11px] text-gray-500 mt-0.5">{ing.amount}x</span>
                              <div className="absolute -top-8 left-1/2 -translate-x-1/2 px-2 py-1 bg-black/90 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
                                {ing.label}
                              </div>
                            </div>
                          ))
                        ) : (
                          <span className="text-gray-600 text-xs italic">No ingredients</span>
                        )}
                      </div>

                      {/* Arrow */}
                      <div className="text-gray-600">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                        </svg>
                      </div>

                      {/* Output */}
                      <div className="flex flex-col items-center group relative">
                        <div className="w-12 h-12 rounded-lg bg-[#1a2e1a] border border-[#4ade80]/20 flex items-center justify-center">
                          <ItemImage
                            src={getItemImage(entry.output_item || entry.recipe_id, entry.output_image)}
                            alt={entry.output_label || entry.recipe_name}
                            className="w-8 h-8 object-contain"
                            fallbackClassName="w-8 h-8 text-gray-600"
                          />
                        </div>
                        <span className="text-[11px] text-[#4ade80] mt-0.5">{entry.output_amount || entry.quantity}x</span>
                        <div className="absolute -top-8 left-1/2 -translate-x-1/2 px-2 py-1 bg-black/90 text-white text-xs rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
                          {entry.output_label || entry.recipe_name}
                        </div>
                      </div>

                      {/* Spacer */}
                      <div className="flex-1" />

                      {/* Info & Delete */}
                      <div className="text-right">
                        <div className="text-white text-sm font-medium">{entry.player_name}</div>
                        <div className="flex items-center justify-end gap-1.5 mt-0.5">
                          <span className="text-gray-500 text-[11px]">
                            {(() => {
                              const date = new Date(entry.crafted_at);
                              const day = date.getDate().toString().padStart(2, '0');
                              const month = (date.getMonth() + 1).toString().padStart(2, '0');
                              const year = date.getFullYear();
                              const dateStr = historyDateFormat === 'MDY' ? `${month}/${day}/${year}` : `${day}/${month}/${year}`;
                              return `${dateStr} ${date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
                            })()}
                          </span>
                          {(!historyOwnerOnlyDelete || isWorkbenchOwner) && (
                            <button
                              onClick={async () => {
                                const res = await fetchNui<{ success: boolean }>('deleteHistoryEntry', { entryIndex: index + 1 });
                                if (res.success) {
                                  setHistory(prev => prev.filter((_, i) => i !== index));
                                }
                              }}
                              className="text-gray-600 hover:text-red-400 transition-colors"
                            >
                              <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                              </svg>
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
    )}
    </TranslatedContent>
    </TranslationProvider>
  );
}

export default App;
