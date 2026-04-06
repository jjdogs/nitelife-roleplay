-- If you want to use showGallons or customFuelCanWeight You must do the ox_inventory edits!!!!
-- Inventory edits documentation: https://renewed-scripts.gitbook.io/renewed-scripts/paid-scripts/renewed-fuel/petrol-cans/ox-inventory-edits

return {
    fuelCans = true, -- Use fuel cans (Also known as petrol cans or jerry cans)

    fuelPerDurability = 0.1, -- How many gallons of fuel per durability, 0.1 means 10 gallons of fuel per petrolcan, 1.0 would mean 100 gallons of fuel per petrolcan

    customFuelCanWeight = {
        enabled = false, -- If set to true MAKE SURE you do the edits in ox_inventory referenced on the documentation
        maxWeight = 12000, -- Max weight of fuel cans in grams (12kg)
        minWeight = 1000, -- Min weight of fuel cans in grams (1kg)
    },
    showGallons = false, -- If set to true it shows gallons remaining in the metadata, IF TRUE YOU MUST DO THE OX_INVENTORY CHANGES

    petrolCanSpeed = 3.0, -- 3x longer to fill up a petrol can compared to a car
}