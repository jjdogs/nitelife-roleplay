import { atom } from "recoil";
import { ApiBusiness } from "../API/business";
import { BusinessType, Permissions } from "../types/types";

export const Lang = atom<Object>({
  key: "lang",
  default: {},
});

export const BusinessInfo = atom<BusinessType>({
  key: "business",
  default: ApiBusiness,
});

export const MyPermissions = atom<Permissions>({
  key: "myPermissions",
  default: {},
});
