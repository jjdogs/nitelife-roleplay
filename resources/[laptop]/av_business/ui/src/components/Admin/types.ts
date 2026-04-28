export interface DeliveryStash {
  label: string;
  weight: number;
  slots: number;
}

export interface DeliveriesType {
  enabled: boolean;
  maxDistance: number;
  minProducts: number;
  maxProducts: number;
  maxOrders: number;
  maxPrice: number;
  maxTip: number;
  overprice: number;
  toIgnore: string[];
  deliveryWait: [number, number];
  stash: DeliveryStash;
}
