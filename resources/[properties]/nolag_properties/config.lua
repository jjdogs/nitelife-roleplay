Config = {
    RealEstateJobs = {
        realestate = {
            creation = 4,
            allproperties = 4,
            deleteproperty = 4,
            deletebuilding = 4,
            forceopeninventory = 4,
            transfer = 4,
            update_inventory_config = 2,
            edit_property = 4,
            edit_building = 4,
            change_interior = 4,
            give_furniture = 0,
            terminate_renter = 1,
        },
    },
    CreatePropertyCommand = "createproperty",
    ToggleBlipsCommand = "togglepropertyblips",
    AdminPanelCommand = "allproperties",
    GiveStarterApartmentCommand = "givestarterapartments",
    GiveFurnitureCommand = "givefurniture",
    PoliceRaid = {
        Enabled = true,
        Jobs = {
            police = 0,
            sheriff = 1,
        },
    },
    PoliceLockdown = {
        DisableEnter = true,
        DisableInventory = true,
        DisableGarage = true,
        DisableKeyManagement = true,
        DisableInteractablePoints = true,
        DisableDoorManagement = true,
        DisableSellProperty = true,
        DisableFurniture = true,
        DisableIplManagement = true,
    },
    FixShellOffsets = true,
    EnableOffsetFinder = true,
    Framework = "auto",
    InteractOption = "auto",
    Garage = "auto",
    Inventory = "auto",
    Clothes = "auto",
    Weather = "auto",
    Banking = "auto",
    Logs = "ox_lib",
    ColorTheme = {
        useOxTheme = true,
        laser = {
            r = 108,
            g = 0,
            b = 135,
            a = 200,
        },
        laserBasedOnTheme = true,
    },
    UseContextMenuForInteractionMenu = true,
    ModelRequestTime = 30000,
    FurnitureModelTimeout = 10000,
    DynamicDoors = true,
    PointSelectionMethods = {
        enterPoint = "laser",
        exitPoint = "laser",
        mloInteractPoint = "laser",
        interactablePoints = "laser",
    },
    Lockpick = {
        Enable = false,
        RequireOwnerOnline = false,
        AllowCompanyProperties = true,
        Item = {
            Require = false,
            Name = "lockpick",
            Amount = 1,
            RemoveOnFail = true,
            RemoveOnSuccess = false,
        },
        Minigame = function(item, difficulty, pins)
            lib.playAnim(cache.ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 3.0, 1.0, -1, 49)
            local success = lib.skillCheck({ 'easy', 'easy', { areaSize = 60, speedMultiplier = 2 }, 'hard' }, { 'q', 'w', 'e', 'r' })
            ClearPedTasks(cache.ped)
            return success
        end,
    },
    LockDoorsByDefault = false,
    ExitEnterWhileLocked = true,
    OpenForPreview = true,
    SpawnInProperty = true,
    PropertyPrice = {
        1,
        1000000,
    },
    InactivityDays = 28,
    InactivityDaysForRent = 28,
    MaxPropertiesPerPlayer = false,
    PropertyLimitOverrides = {},
    MaxRentsPerPlayer = false,
    PropertyRentLimitOverrides = {},
    YardZoneRadius = 10,
    MaxFurnitureInside = false,
    MaxFurnitureOutside = false,
    DefaultFurnitureWeight = 1000,
    AllowSelfAsKeyholder = false,
    SecurityCamFilter = "secret_camera",
    SecurityCamFilterStrength = 1,
    SecurityCamNightVision = true,
    SecurityCamNightVisionFilter = "MP_heli_cam",
    SecurityCamNightVisionStrength = 1,
    MaxSecurityCameras = false,
    MaxSecurityCamerasInside = false,
    MaxSecurityCamerasOutside = false,
    UtilityBills = {
        Enabled = true,
        BillingPeriod = 7,
        GratisPeriod = 3,
        Prices = {
            Electricity = 100,
            Water = 50,
            Internet = 75,
        },
    },
    UtilityConsumption = {
        Enabled = true,
        Electricity = {
            Enabled = true,
            CostPerMinute = 0.5,
            TrackingInterval = 60,
        },
        Water = {
            Enabled = true,
            ShowerCost = 2,
            SinkCost = 0.5,
            ShowerDuration = 10000,
            SinkDuration = 5000,
        },
        OnWashComplete = function(washType, property)
            -- Example: Clear gunpowder residue after washing
            -- if washType == 'shower' then
            --     TriggerEvent('evidence:clearGunpowder')
            --     TriggerEvent('evidence:clearBlood')
            -- elseif washType == 'sink_handwash' or washType == 'sink_facewash' then
            --     TriggerEvent('evidence:clearGunpowder')
            -- end
            lib.print.debug('Wash complete: ' .. washType .. ' in property #' .. property.id)
        end,
    },
    SellPercentage = 70,
    DefaultBuyerType = "society",
    StarterApartment = {
        Enabled = true,
        DisableForceSale = true,
        DisableSell = true,
        DisableRent = true,
        DisableInactivity = true,
        DisableFurniture = false,
        BuildingId = 2,
        Address = "Strawberry Ave 2",
        Name = "Alesandro Hotel",
        UniqueName = true,
        RentedInstead = true,
        InitialRentDays = 14,
        FutureRentPrice = 500,
        Interior = {
            type = "shell",
            name = "starter_apartments",
        },
        Inventory = {
            slots = 10,
            weight = 10000,
        },
        InteractablePoints = {
            OpenInventory = true,
            ClothingMenu = true,
        },
    },
    Building = {
        OwnerDisplay = true,
        OwnerDisplayType = "name",
    },
    EnableMap = true,
    DefaultBuyerIdentifier = "realestate",
    RequireDefaultSellToBuy = false,
    SellPercentageForTheGovernment = 100,
    ResetPropertyPriceOnSell = true,
    BuyPropertyOnCreation = false,
    CreatePropertyAsSociety = true,
    DisableSocietyBuying = false,
    DisableSocietyRenting = false,
    RequireBossGradeForSocietyBuying = false,
    RequireBossGradeForSocietyRenting = false,
    ProcessPropertiesCron = "*/30 * * * *",
    OwnerCanCancelRent = false,
    EnableRenting = true,
    EnableForceSale = true,
    RentPercentage = 90,
    MaxRentDays = 28,
    RemoveAllKeysOnRentCancel = true,
    LockDoorsOnForceSale = true,
    EnableSellProperty = true,
    IplPrice = {
        1,
        1000000,
    },
    PaidIplChanges = false,
    IplDistanceToCheck = 50,
    IplsUseRoutingBuckets = false,
    ShellZLevel = 2000,
    ShellPrice = {
        1,
        1000000,
    },
    ShellUseRoutingBuckets = true,
    ShellDistanceToCheck = 50,
    MloPriceBasedOnArea = false,
    MloInventoryData = {
        Slots = {
            1,
            100,
        },
        Weight = {
            1,
            1000000,
        },
    },
    PricePerSquare = {
        1,
        200,
    },
    MloPrice = {
        1,
        1000000,
    },
    LimitFreeCam = true,
    LimitFreeCamDistance = 100,
    RestrictFreecamToZone = false,
    DefaultSlots = 50,
    DefaultWeight = 10000,
    Keybinds = {
        Interact = "E",
        PropertyMenu = "F5",
        DeleteShell = "BACK",
        CopyOffset = "RETURN",
    },
    Trash = {
        Enabled = true,
        TrashCreatedOnCron = true,
        TrashCreatedOnCronCount = 1,
        Objects = {
            `proc_litter_01`,
            `proc_litter_02`,
            `prop_rub_litter_01`,
            `prop_rub_litter_02`,
            `prop_rub_litter_03`,
            `prop_rub_litter_04`,
            `prop_rub_litter_05`,
            `prop_rub_litter_06`,
            `prop_rub_litter_07`,
            `prop_rub_flotsam_01`,
            `prop_rub_flotsam_03`,
        },
    },
    InteractDistance = 1.5,
    InteractRadius = 1.5,
    Blips = {
        ipl = {
            default = {
                Color = 3,
                Sprite = 40,
                Scale = 0.8,
                Category = 55,
                Display = 2,
                ShortRange = false,
                Disabled = true,
            },
            owner = {
                Color = 3,
                Sprite = 40,
                Scale = 0.8,
                Category = 50,
                Display = 2,
                ShortRange = false,
                Disabled = false,
            },
            forSale = {
                Color = 69,
                Sprite = 374,
                Scale = 0.8,
                Category = 52,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            forRent = {
                Color = 69,
                Sprite = 374,
                Scale = 0.8,
                Category = 53,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            renter = {
                Color = 5,
                Sprite = 40,
                Scale = 0.8,
                Category = 51,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            keyholder = {
                Color = 9,
                Sprite = 40,
                Scale = 0.8,
                Category = 54,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
        },
        shell = {
            default = {
                Color = 3,
                Sprite = 40,
                Scale = 0.8,
                Category = 55,
                Display = 2,
                ShortRange = false,
                Disabled = true,
            },
            owner = {
                Color = 3,
                Sprite = 40,
                Scale = 0.8,
                Category = 50,
                Display = 2,
                ShortRange = false,
                Disabled = false,
            },
            forSale = {
                Color = 69,
                Sprite = 374,
                Scale = 0.8,
                Category = 52,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            forRent = {
                Color = 69,
                Sprite = 374,
                Scale = 0.8,
                Category = 53,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            renter = {
                Color = 5,
                Sprite = 40,
                Scale = 0.8,
                Category = 51,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            keyholder = {
                Color = 9,
                Sprite = 40,
                Scale = 0.8,
                Category = 54,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
        },
        mlo = {
            default = {
                Color = 3,
                Sprite = 492,
                Scale = 0.8,
                Category = 55,
                Display = 2,
                ShortRange = false,
                Disabled = true,
            },
            owner = {
                Color = 3,
                Sprite = 492,
                Scale = 0.8,
                Category = 50,
                Display = 2,
                ShortRange = false,
                Disabled = false,
            },
            forSale = {
                Color = 69,
                Sprite = 374,
                Scale = 0.8,
                Category = 52,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            forRent = {
                Color = 69,
                Sprite = 374,
                Scale = 0.8,
                Category = 53,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            renter = {
                Color = 5,
                Sprite = 492,
                Scale = 0.8,
                Category = 51,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            keyholder = {
                Color = 9,
                Sprite = 492,
                Scale = 0.8,
                Category = 54,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
        },
        building = {
            default = {
                Color = 3,
                Sprite = 475,
                Scale = 0.8,
                Category = 55,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            ownProperty = {
                Color = 3,
                Sprite = 475,
                Scale = 0.8,
                Category = 50,
                Display = 2,
                ShortRange = false,
                Disabled = false,
            },
            forSale = {
                Color = 69,
                Sprite = 374,
                Scale = 0.8,
                Category = 52,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            forRent = {
                Color = 69,
                Sprite = 374,
                Scale = 0.8,
                Category = 53,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            renter = {
                Color = 5,
                Sprite = 475,
                Scale = 0.8,
                Category = 51,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
            keyholder = {
                Color = 9,
                Sprite = 475,
                Scale = 0.8,
                Category = 54,
                Display = 2,
                ShortRange = true,
                Disabled = false,
            },
        },
        DefaultVisibility = {
            all = true,
            owned = true,
            forSale = true,
            forRent = true,
            renter = true,
            keyholder = true,
        },
    },
    Tags = {
        "🪑 Furnished",
        "🚗 Garage",
        "🏊 Pool",
        "🌳 Yard",
        "🌷 Garden",
        "🪟 Balcony",
        "🌇 Terrace",
        "🌊 Sea view",
        "🏔️ Mountain view",
        "🏙️ City view",
        "🌲 Forest view",
        "🏞️ Lake view",
        "🏞️ River view",
        "🅿️ Parking",
        "🏋️ Gym",
        "🧖 Sauna",
        "🛀 Jacuzzi",
        "🍺 Bar",
        "🎥 Cinema",
        "📚 Library",
        "🏢 Office",
        "🔥 Fireplace",
        "🌡️ Heating",
        "❄️ Air conditioning",
    },
    PropertiesPerPage = 10,
    Functions = {
        UseShower = {
            type = "inside",
            maxPerProperty = 10,
            label = locale("use_shower") or "Use Shower",
            icon = "fas fa-shower",
            radius = 0.5,
            onSelect = function(property, data)
                if not Config.UtilityConsumption.Enabled or not Config.UtilityConsumption.Water.Enabled then
                    Framework.Notify({
                        description = locale("water_system_disabled") or "Water system is disabled",
                        type = "error"
                    })
                    return
                end

                -- Check if water is cut off
                if property.utilities and property.utilities.water and property.utilities.water.cutOff then
                    Framework.Notify({
                        description = locale("property_no_water") or "No water supply - bill unpaid",
                        type = "error"
                    })
                    return
                end

                local success = lib.callback.await('nolag_properties:server:property:useWater', false, property.id, 'shower')
                if not success then
                    Framework.Notify({
                        description = locale("water_use_failed") or "Failed to use water",
                        type = "error"
                    })
                    return
                end

                -- Play shower animation
                local player = cache.ped
                local duration = Config.UtilityConsumption.Water.ShowerDuration or 10000

                -- Face the correct direction if offset has heading
                if data and data.coords and data.coords.w and data.coords.w ~= 0 then
                    SetEntityHeading(player, data.coords.w)
                end

                if lib.progressCircle({
                        duration = duration,
                        label = locale("showering") or "Showering...",
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            car = true,
                            move = true,
                            combat = true,
                        },
                        anim = {
                            dict = 'mp_safehouseshower@male@',
                            clip = 'male_shower_idle_a',
                            blendIn = 8.0,
                            blendOut = 8.0,
                            flag = 1,
                            lockX = true,
                            lockY = true,
                            lockZ = false,
                        }
                    }) then
                    -- Call the wash complete callback
                    if Config.UtilityConsumption.OnWashComplete then
                        Config.UtilityConsumption.OnWashComplete('shower', property)
                    end
                    Framework.Notify({
                        description = locale("shower_complete") or "You feel refreshed!",
                        type = "success"
                    })
                end
            end,
        },
        UseSink = {
            type = "inside",
            maxPerProperty = 10,
            label = locale("use_sink") or "Use Sink",
            icon = "fas fa-faucet",
            radius = 0.5,
            onSelect = function(property, data)
                if not Config.UtilityConsumption.Enabled or not Config.UtilityConsumption.Water.Enabled then
                    Framework.Notify({
                        description = locale("water_system_disabled") or "Water system is disabled",
                        type = "error"
                    })
                    return
                end

                -- Check if water is cut off
                if property.utilities and property.utilities.water and property.utilities.water.cutOff then
                    Framework.Notify({
                        description = locale("property_no_water") or "No water supply - bill unpaid",
                        type = "error"
                    })
                    return
                end

                -- Show context menu for wash type selection
                lib.registerContext({
                    id = 'sink_wash_menu',
                    title = locale("sink_menu_title") or "Sink",
                    options = {
                        {
                            title = locale("wash_hands") or "Wash Hands",
                            icon = "fas fa-hands-wash",
                            onSelect = function()
                                local success = lib.callback.await('nolag_properties:server:property:useWater', false, property.id, 'sink')
                                if not success then
                                    Framework.Notify({
                                        description = locale("water_use_failed") or "Failed to use water",
                                        type = "error"
                                    })
                                    return
                                end

                                local player = cache.ped
                                local duration = Config.UtilityConsumption.Water.SinkDuration or 5000

                                if data and data.coords and data.coords.w and data.coords.w ~= 0 then
                                    SetEntityHeading(player, data.coords.w)
                                end

                                if lib.progressCircle({
                                        duration = duration,
                                        label = locale("washing_hands") or "Washing hands...",
                                        useWhileDead = false,
                                        canCancel = true,
                                        disable = {
                                            car = true,
                                            move = true,
                                            combat = true,
                                        },
                                        anim = {
                                            dict = 'missheist_agency3aig_23',
                                            clip = 'urinal_sink_loop',
                                            blendIn = 8.0,
                                            blendOut = 8.0,
                                            flag = 1,
                                            lockX = true,
                                            lockY = true,
                                            lockZ = false,
                                        }
                                    }) then
                                    if Config.UtilityConsumption.OnWashComplete then
                                        Config.UtilityConsumption.OnWashComplete('sink_handwash', property)
                                    end
                                    Framework.Notify({
                                        description = locale("hands_clean") or "Your hands are clean!",
                                        type = "success"
                                    })
                                end
                            end
                        },
                        {
                            title = locale("wash_face") or "Wash Face",
                            icon = "fas fa-head-side-mask",
                            onSelect = function()
                                local success = lib.callback.await('nolag_properties:server:property:useWater', false, property.id, 'sink')
                                if not success then
                                    Framework.Notify({
                                        description = locale("water_use_failed") or "Failed to use water",
                                        type = "error"
                                    })
                                    return
                                end

                                local player = cache.ped
                                local duration = Config.UtilityConsumption.Water.SinkDuration or 5000

                                if data and data.coords and data.coords.w and data.coords.w ~= 0 then
                                    SetEntityHeading(player, data.coords.w)
                                end

                                if lib.progressCircle({
                                        duration = duration,
                                        label = locale("washing_face") or "Washing face...",
                                        useWhileDead = false,
                                        canCancel = true,
                                        disable = {
                                            car = true,
                                            move = true,
                                            combat = true,
                                        },
                                        anim = {
                                            dict = 'missmic2_washing_face',
                                            clip = 'michael_washing_face',
                                            blendIn = 8.0,
                                            blendOut = -8.0,
                                            flag = 0,
                                            lockX = false,
                                            lockY = false,
                                            lockZ = false,
                                        }
                                    }) then
                                    if Config.UtilityConsumption.OnWashComplete then
                                        Config.UtilityConsumption.OnWashComplete('sink_facewash', property)
                                    end
                                    Framework.Notify({
                                        description = locale("face_clean") or "Your face is clean!",
                                        type = "success"
                                    })
                                end
                            end
                        },
                    }
                })
                lib.showContext('sink_wash_menu')
            end,
        },
        LightSwitch = {
            type = "inside",
            maxPerProperty = 10,
            label = locale("light_switch") or "Light Switch",
            icon = "fas fa-lightbulb",
            radius = 0.5,
            onSelect = function(property)
                property:toggleLights(nil, true)
            end,
        },
    },
    InteractableProps = {
        reh_prop_reh_switch_01a = {
            label = locale("light_switch") or "Light Switch",
            icon = "fas fa-lightbulb",
            radius = 1.5,
            maxPerProperty = 10,
            breakable = true,
            onSelect = function(property)
                lib.print.debug("Toggle lights for property #" .. property.id)
                property:toggleLights(nil, true)
            end,
        },
    },
    WardrobeObjects = {
        "ch_prop_ch_service_locker_01a",
        "ch_prop_ch_service_locker_02a",
        "apa_mp_h_str_shelffloorm_02",
        "apa_mp_h_str_shelffreel_01",
        "bkr_prop_gunlocker_01a",
        "apa_mp_h_str_shelfwallm_01",
        "v_serv_cupboard_01",
    },
    InventoryObjects = {
        p_v_43_safe_s = {
            slots = 35,
            weight = 100000,
        },
    },
    Bell = {
        Cooldown = 5000,
    },
    PhysicalKeys = {
        Enabled = true,
        ItemName = "housing_key",
        BittingCodeLength = 5,
        KeyTypes = {
            MainEntrance = true,
            InteractablePoints = false,
            Doors = true,
            MasterKey = true,
        },
        AllowRekey = true,
        RekeyPrice = 5000,
        KeyWax = {
            Enabled = true,
            BlankItemName = "key_wax",
            UsedItemName = "key_wax_used",
        },
        LockSmiths = {
            {
                Enabled = true,
                CreateInvalidKeys = true,
                CreateKeyByBittingCode = true,
                KeyByBittingCodePrice = 1000,
                KeyPrice = 1000,
                Model = "IG_Benny_02",
                Coords = vector4(169.9714, -1799.5154, 29.3159, 318.0738),
            },
            {
                Enabled = true,
                CreateInvalidKeys = false,
                CreateKeyByBittingCode = true,
                KeyByBittingCodePrice = 1500,
                KeyPrice = 800,
                Model = "s_m_m_autoshop_02",
                Coords = vector4(-401.3177, -450.8532, 37.3349, 194.9187),
            },
        },
        EnableKeyWax = true,
        EnableLocksmiths = true,
        Locksmiths = {},
    },
    Marketplace = {
        Enabled = true,
        AllowTransactionFromMenu = true,
        PriceFilter = {
            Max = 1000000,
            Step = 5000,
        },
        Blip = {
            Enabled = true,
            Sprite = 476,
            Scale = 0.8,
            Color = 43,
            Display = 4,
            ShortRange = true,
            Category = 1,
            Label = "Property Marketplace",
        },
        BlipCoords = vector3(-1082.4330, -247.6247, 37.7633),
        TargetCoords = vector4(-1083.1598, -245.97, 37.6632, 208.5247),
        TargetRadius = 3,
        Ped = {
            Enabled = true,
            Model = "ig_drfriedlander",
            Coords = vector4(-1083.1598, -245.97, 37.6632, 208.5247),
            InteractDistance = 2.5,
        },
    },
    DoorLock = {
        DrawTextUI = false,
        Notify = true,
        SpriteIcons = {
            unlocked = {
                dict = "mpsafecracking",
                texture = "lock_open_dark",
                x = 0,
                y = 0,
                width = 0.018,
                height = 0.018,
            },
            locked = {
                dict = "mpsafecracking",
                texture = "lock_closed_dark",
                x = 0,
                y = 0,
                width = 0.018,
                height = 0.018,
            },
        },
    },
    CreationMenu = {
        PhotoFreecam = true,
        ipl = {
            label = "IPL",
            enabled = false,
            image = "https://r2.fivemanage.com/acP9u7gLziIbHCwCT6NVX/57CYSM.jpg",
        },
        shell = {
            label = "Shell",
            enabled = true,
            image = "https://r2.fivemanage.com/acP9u7gLziIbHCwCT6NVX/Rm30eg.jpg",
        },
        mlo = {
            label = "MLO",
            enabled = false,
            image = "https://r2.fivemanage.com/acP9u7gLziIbHCwCT6NVX/kddbLu.png",
        },
        building = {
            label = "Building",
            enabled = true,
            image = "https://r2.fivemanage.com/acP9u7gLziIbHCwCT6NVX/HTu5AH.jpg",
        },
    },
    ToggleHud = function(toggle)
        if GetResourceState("tgg-hud") == "started" then
            exports["tgg-hud"]:ToggleHud(toggle)
            return
        end

        DisplayHud(toggle)
        DisplayRadar(toggle)
    end,
    RaidProperty = function()
        local result = false

        local success = lib.skillCheck({ 'easy', 'easy' }, { 'w', 'a', 's', 'd' })
        if success then
            success = lib.progressCircle({
                duration = math.random(10000, 20000),
                label = 'Breaching the door..',
                disable = {
                    car = true,
                    combat = true,
                    move = true
                },
                anim = {
                    dict = "missheistfbi3b_ig7",
                    clip = 'lift_fibagent_loop'
                }
            })
            if success then
                result = true
            end
        end

        return result
    end,
    Debug = false,
    ManualSQLInjection = false,
    CheckForUpdates = true,
}


if Config.Framework == 'auto' then
    lib.print.debug('Detecting framework...')

    if GetResourceState('qbx_core'):find('start') then
        Config.Framework = 'qbox'
    elseif GetResourceState('qb-core'):find('start') then
        Config.Framework = 'qbcore'
    elseif GetResourceState('es_extended'):find('start') then
        Config.Framework = 'esx'
    elseif GetResourceState('ox_core'):find('start') then
        Config.Framework = 'ox_core'
    else
        Config.Framework = 'standalone'
    end

    lib.print.debug('Detected framework: ' .. Config.Framework)
end

if Config.InteractOption == 'auto' then
    lib.print.debug('Detecting interact option...')

    local interactOptions = {
        'ox_target',
        'interact',
        'sleepless_interact',
        'bl_sprites',
    }

    for i = 1, #interactOptions do
        if GetResourceState(interactOptions[i]):find('start') then
            if interactOptions[i] == 'sleepless_interact' then
                local version = GetResourceMetadata('sleepless_interact', 'version', 0)
                if version and tonumber(string.sub(version, 1, 1)) >= 2 then
                    Config.InteractOption = 'sleepless_interactv2'
                else
                    Config.InteractOption = 'sleepless_interact'
                end
            else
                Config.InteractOption = interactOptions[i]
            end
            break
        end
    end

    if Config.InteractOption == 'auto' then
        Config.InteractOption = 'lib.zones'
    end

    lib.print.debug('Detected interact option: ' .. Config.InteractOption)
end

if Config.Inventory == 'auto' then
    lib.print.debug('Detecting inventory...')

    local inventories = {
        'ox_inventory',
        'qb-inventory',
        'core_inventory',
        'mf-inventory',
        'qs-inventory',
        'inventory',
        'tgiann-inventory',
    }

    for i = 1, #inventories do
        if GetResourceState(inventories[i]):find('start') then
            if inventories[i] == 'qb-inventory' then
                local version = GetResourceMetadata('qb-inventory', 'version', 0)
                if version and tonumber(string.sub(version, 1, 1)) >= 2 then
                    Config.Inventory = 'qb-inventory-v2'
                else
                    Config.Inventory = 'qb-inventory-v1'
                end
            else
                Config.Inventory = inventories[i]
            end
            break
        end
    end

    lib.print.debug('Detected inventory: ' .. Config.Inventory)
end

if Config.Clothes == 'auto' then
    lib.print.debug('Detecting clothes...')

    local clothes = {
        'illenium-appearance',
        'qb-clothing',
        'fivem-appearance',
        'rcore_clothing',
        'rcore_clothes',
        'vms_clothestore',
        '17mov_CharacterSystem',
        'crm-appearance',
        'bl_appearance',
        'codem-appearance',
    }

    for i = 1, #clothes do
        if GetResourceState(clothes[i]):find('start') then
            Config.Clothes = clothes[i]
            break
        end
    end

    lib.print.debug('Detected clothes: ' .. Config.Clothes)
end

if Config.Weather == 'auto' then
    lib.print.debug('Detecting weather...')

    local weathers = {
        'Renewed-Weathersync',
        'randol_weather',
        'qb-weathersync',
        'av_weather',
        'cd_easytime',
        'vSync',
        'night_natural_disasters',
    }

    for i = 1, #weathers do
        if GetResourceState(weathers[i]):find('start') then
            Config.Weather = weathers[i]
            break
        end
    end

    lib.print.debug('Detected weather: ' .. Config.Weather)
end

if Config.Banking == 'auto' then
    lib.print.debug('Detecting banking...')

    local bankings = {
        'tgg-banking',
        'Renewed-Banking',
        'snipe-banking',
        'okokBanking',
        'fd_banking',
        'LGMods_Banking',
        'qb-banking',
        'qb-management',
        'esx_addonaccount',
    }

    for i = 1, #bankings do
        if GetResourceState(bankings[i]):find('start') then
            if bankings[i] == 'qb-banking' and tonumber(string.sub(GetResourceMetadata('qb-banking', 'version', 0), 1, 3)) < 2 then
                goto skip
            end

            Config.Banking = bankings[i]
            break
        end
        ::skip::
    end

    lib.print.debug('Detected banking: ' .. Config.Banking)
end

if Config.Garage == 'auto' then
    lib.print.debug('Detecting garage...')

    local garages = {
        'nolag_garages',
        'cd_garage',
        'qb-garages',
        'jg-advancedgarages',
        'qbx_garages',
        'loaf_garage',
        'okokGarage',
        'rcore_garage',
        'zerio-garage',
        'rx_garages',
        'vms_garagesv2',
    }

    for i = 1, #garages do
        if GetResourceState(garages[i]):find('start') then
            Config.Garage = garages[i]
            break
        end
    end

    lib.print.debug('Detected garage: ' .. Config.Garage)
end
