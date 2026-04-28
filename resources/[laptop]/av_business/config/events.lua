Config = Config or {}
Config.Events = { -- Used to create zones
    -- key index needs to be the item type
    -- label: string (except for cashiers, it uses table)
    -- subheader?:string Description for context menu (only available if not using target)
    -- icon: "string" (except for cashiers, it uses table)
    -- job: boolean (job restricted zone)
    -- icons are from the free section in fontawesome website: https://fontawesome.com/search?m=free&o=r
    ['cashier'] = {
        label = {employee = "Cashier", customer = "Pay"},
        icon = { employee = "fas fa-cash-register", customer = "fas fa-credit-card" },
        subheader = {
            employee = "Create a new order",
            customer = "Pay for your order"
        },
        job = true
    },
    ['drink'] = {
        label = "Drinks",
        subheader = "Use the drinks station",
        event = "av_business:products",
        icon = "fas fa-glass-whiskey",
        job = true
    },
    ['food'] = {
        label = "Food",
        subheader = "Use the food station",
        event = "av_business:products",
        icon = "fas fa-utensils",
        job = true
    },
    ['joint'] = {
        label = "Joint",
        subheader = "Use the joint station",
        event = "av_business:products",
        icon = "fas fa-cannabis",
        job = true
    },
    ['alcohol'] = {
        label = "Alcohol",
        subheader = "Use the alcohol station",
        event = "av_business:products",
        icon = "fa-solid fa-wine-glass",
        job = true
    },
    ['others'] = {
        label = "Others",
        subheader = "Use the others station",
        event = "av_business:products",
        icon = "fas fa-box",
        job = true
    },
    ['stash'] = {
        label = "Stash",
        subheader = "Open the business stash",
        event = "av_business:stash",
        icon = "fas fa-box-open",
        job = true
    },
    ['tray'] = {
        label = "Tray",
        subheader = "Open the tray",
        event = "av_business:tray",
        icon = "fas fa-box-open",
        job = false
    },
    ['rate'] = {
        label = "Rate",
        subheader = "We really appreciate your review!",
        event = "av_business:rate",
        icon = "fas fa-star",
        job = false
    },
    ['duty'] = {
        label = "Duty",
        subheader = "Toggle your duty status",
        event = "av_business:duty",
        icon = "fa-solid fa-briefcase",
        job = true
    },
    ['applications'] = {
        label = "Applications",
        subheader = "Leave your job application",
        event = "av_business:applications",
        icon = "fa-solid fa-briefcase",
        job = false
    },
    ['box'] = {
        label = "Boxes",
        subheader = "Grab a box for your products",
        event = "av_business:products",
        icon = "fa-solid fa-box",
        job = true
    },
    ['orders'] = {
        label = "Orders",
        subheader = "View pending orders",
        event = "av_business:orders",
        icon = "fa-solid fa-clipboard-list",
        job = true
    },
    ['poster'] = {
        label = "Poster",
        subheader = "View the business poster",
        event = "av_business:showPoster",
        icon = "fa-solid fa-file-image",
        job = false
    },
    ['dirty_vault'] = {
        label = "Vault",
        subheader = "Business Vault",
        event = "av_business:openVault",
        icon = "fa-solid fa-vault",
        job = true
    },
}