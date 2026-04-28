import { DeliveriesType } from "../components/Admin/types";

export const ApiDeliveries: DeliveriesType = {
  enabled: true,
  maxDistance: 2000.0,
  minProducts: 5,
  maxProducts: 10,
  maxOrders: 20,
  maxPrice: 100,
  maxTip: 200,
  overprice: 50,
  toIgnore: ["box", "others"],
  deliveryWait: [1, 3],
  stash: {
    label: "Customer",
    weight: 100000,
    slots: 10,
  },
};
