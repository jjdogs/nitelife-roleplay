return {

-- ── Documents & ID ────────────────────────────────────────────────────────────

    ['id_card'] = {
        label = 'Identification Card',
        description = 'Card used to indentify who you are.',
        weight = 10,
    },

    ['driver_license'] = {
        label = 'Drivers License',
        description = 'You need this to legally operate a vehicle in Los Santos.',
        weight = 10,
    },

    ['weaponlicense'] = {
        label = 'Weapon License',
        description = 'License that gives you the ability to buy guns legally. Ask a police officer about one!',
        weight = 10,
    },

    ['lawyerpass'] = {
        label = 'Lawyer Pass',
        description = 'This is used by Lawyers to verify they can represent someone.',
        weight = 10,
    },

-- ── Currency ──────────────────────────────────────────────────────────────────

    ['money'] = {
        label = 'Money',
        description = 'Buy things with this!',
        weight = 5,
    },

    ['black_money'] = {
        label = 'Dirty Money',
        description = 'Usually used to purchase items that might be illegal. *Marked for Police Seizure*',
        weight = 10,
    },

-- ── Food & Drink ──────────────────────────────────────────────────────────────

    ['burger'] = {
        label = 'Cheese Burger',
        description = 'Yummy Burger plain with cheese.',
        weight = 100,
        -- client = {
        --     status = { hunger = 200000 },
        --     anim = 'eating',
        --     prop = 'burger',
        --     usetime = 2500,
        --     notification = 'You ate a delicious burger'
        -- },
    },

    ['sandwich'] = {
        label = 'Sandwich',
        description = 'A yummy turkey & ham Sandwich!',
        weight = 100,
    },

    ['coffee'] = {
        label = 'Coffee',
        description = 'Nice hot coffee helps you wake up.',
        weight = 200,
    },

    ['wine'] = {
        label = 'Wine',
        description = 'A glass of red wine. Goes well with a fancy dinner.',
        weight = 500,
    },

    ['vodka'] = {
        label = 'Vodka',
        description = 'A bottle of vodka. Strong stuff, drink responsibly.',
        weight = 500,
    },

    ['whiskey'] = {
        label = 'Whiskey',
        description = 'A smooth glass of whiskey. Perfect for unwinding after a long day.',
        weight = 200,
    },

    ['beer'] = {
        label = 'Beer',
        description = 'A cold bottle of beer. Nothing beats this after a hard shift.',
        weight = 200,
    },

    ['water'] = {
        label = 'Water',
        description = 'Fresh bottled water. Stay hydrated out there.',
        weight = 500,
        -- client = {
        --     status = { thirst = 200000 },
        --     anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        --     prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
        --     usetime = 2500,
        --     cancel = true,
        --     notification = 'You drank some refreshing water'
        -- }
    },

    ['sprunk'] = {
        label = 'Sprunk',
        description = 'A fan-favorite soda from Los Santos. Cold and refreshing!',
        weight = 350,
        -- client = {
        --     status = { thirst = 200000 },
        --     anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        --     prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
        --     usetime = 2500,
        --     notification = 'You quenched your thirst with a sprunk'
        -- }
    },

-- ── Medical ───────────────────────────────────────────────────────────────────

    ['bandage'] = {
        label = 'Bandage',
        description = 'A basic cloth bandage for patching up minor wounds.',
        weight = 115,
    },

    ['painkillers'] = {
        label = 'Painkillers',
        description = 'Over-the-counter painkillers to help manage pain.',
        weight = 400,
    },

-- ── Clothing & Equipment ──────────────────────────────────────────────────────

    ['armour'] = {
        label = 'Bulletproof Vest',
        description = 'A bulletproof vest that provides protection against gunfire.',
        weight = 3000,
        stack = false,
        -- client = {
        --     anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
        --     usetime = 3500
        -- }
    },

    ['clothing'] = {
        label = 'Clothing',
        description = 'An article of clothing.',
        weight = 0,
        consume = 0,
    },

    ['parachute'] = {
        label = 'Parachute',
        description = 'A parachute for safely landing after a high altitude jump.',
        weight = 8000,
        stack = false,
        -- client = {
        --     anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
        --     usetime = 1500
        -- }
    },

    ['harness'] = {
        label = 'Harness',
        description = 'A safety harness for working at heights or extreme activities.',
        weight = 200,
    },

    ['diving_gear'] = {
        label = 'Diving Gear',
        description = 'Full diving equipment for underwater exploration.',
        weight = 30000,
    },

    ['diving_fill'] = {
        label = 'Diving Tube',
        description = 'An air tube used to refill diving gear tanks.',
        weight = 3000,
    },

-- ── Tools & Crafting ──────────────────────────────────────────────────────────

    ['repairkit'] = {
        label = 'Repair Kit',
        description = 'A basic kit for repairing vehicle damage.',
        weight = 2500,
    },

    ['screwdriverset'] = {
        label = 'Screwdriver Set',
        description = 'A full set of screwdrivers for all kinds of mechanical work.',
        weight = 500,
    },

    ['electronickit'] = {
        label = 'Electronic Kit',
        description = 'A kit for working with electronic components and circuitry.',
        weight = 500,
    },

    ['cleaningkit'] = {
        label = 'Cleaning Kit',
        description = 'A cleaning kit for maintaining tools and equipment.',
        weight = 500,
    },

    ['drill'] = {
        label = 'Drill',
        description = 'A heavy-duty power drill. Good for getting through just about anything.',
        weight = 5000,
    },

    ['thermite'] = {
        label = 'Thermite',
        description = 'A highly reactive compound used to burn through reinforced materials. Handle with extreme care.',
        weight = 1000,
    },

    ['jerry_can'] = {
        label = 'Jerrycan',
        description = 'A portable fuel container. Useful for long drives off the beaten path.',
        weight = 3000,
    },

    ['nitrous'] = {
        label = 'Nitrous',
        description = 'Nitrous oxide for a burst of speed. Use it wisely.',
        weight = 1000,
    },

    ['lighter'] = {
        label = 'Lighter',
        description = 'A simple pocket lighter. Always keep one handy.',
        weight = 200,
    },

    ['toaster'] = {
        label = 'Toaster',
        description = 'A household toaster. Bread goes in, toast comes out.',
        weight = 5000,
    },

    ['small_tv'] = {
        label = 'Small TV',
        description = 'A small portable television. Entertainment on the go.',
        weight = 100,
    },

    ['walking_stick'] = {
        label = 'Walking Stick',
        description = 'A sturdy walking stick, great for rough terrain.',
        weight = 1000,
    },

    ['binoculars'] = {
        label = 'Binoculars',
        description = 'High-powered binoculars for keeping an eye on things from a distance.',
        weight = 800,
    },

    ['stickynote'] = {
        label = 'Sticky Note',
        description = 'A small sticky note for leaving reminders or messages.',
        weight = 0,
    },

    ['paperbag'] = {
        label = 'Paper Bag',
        description = 'A plain paper bag. Useful for carrying small items discreetly.',
        weight = 1,
        stack = false,
        close = false,
        consume = 0,
    },

    ['garbage'] = {
        label = 'Garbage',
        description = 'Just trash. Someone should really clean this up.',
        weight = 0,
    },

    ['workbench'] = {
        label = 'Workbench',
        description = 'A portable workbench for basic crafting.',
        weight = 10000,
        stack = false,
        close = true,
        consume = 0,
        client = {
            image = 'workbench.png',
        },
        server = {
            export = 'sd-crafting.useWorkbench',
        }
    },

    ['advanced_workbench'] = {
        label = 'Advanced Workbench',
        description = 'A high-tech workbench with advanced crafting capabilities.',
        weight = 15000,
        stack = false,
        close = true,
        consume = 0,
        client = {
            image = 'advanced_workbench.png',
        },
        server = {
            export = 'sd-crafting.useAdvanced_workbench',
        }
    },

-- ── Materials ─────────────────────────────────────────────────────────────────

    ['wood'] = {
        label = 'Wood',
        description = 'Wood from a tree. A core crafting material.',
        weight = 100,
    },

    ['wood_planks'] = {
        label = 'Wood Planks',
        description = 'Refined wood, useful for flooring or other items. A core crafting material.',
        weight = 100,
    },

    ['steel'] = {
        label = 'Steel',
        description = 'Refined steel. A core crafting material.',
        weight = 100,
    },

    ['rubber'] = {
        label = 'Rubber',
        description = 'Raw rubber material. Used in various crafting recipes.',
        weight = 100,
    },

    ['metalscrap'] = {
        label = 'Metal Scrap',
        description = 'Scraps of metal salvaged from various sources.',
        weight = 100,
    },

    ['iron'] = {
        label = 'Iron',
        description = 'Raw iron ore. A basic crafting material.',
        weight = 100,
    },

    ['copper'] = {
        label = 'Copper',
        description = 'Copper wire and fragments. Used in electronics and crafting.',
        weight = 100,
    },

    ['aluminum'] = {
        label = 'Aluminium',
        description = 'Lightweight aluminium material. Useful for a variety of crafts.',
        weight = 100,
    },

    ['plastic'] = {
        label = 'Plastic',
        description = 'Raw plastic pieces for use in various crafting recipes.',
        weight = 100,
    },

    ['glass'] = {
        label = 'Glass',
        description = 'A piece of glass. Handle with care.',
        weight = 100,
    },

    ['oilbarrel'] = {
        label = 'Oil Barrel',
        description = 'A barrel of crude oil. Heavy and highly flammable.',
        weight = 0,
        stack = false,
    },

    ['driveshaft'] = {
        label = 'Drive Shaft',
        description = 'A vehicle drive shaft. Used in mechanical repairs.',
        weight = 1000,
        stack = false,
    },

    ['oilfilter'] = {
        label = 'Oil Filter',
        description = 'A vehicle oil filter. Essential for regular maintenance.',
        weight = 1000,
        stack = false,
    },

    ['reliefstring'] = {
        label = 'Relief String',
        description = 'A relief string used in vehicle repair work.',
        weight = 1000,
        stack = false,
    },

    ['skewgear'] = {
        label = 'Skew Gear',
        description = 'A precision-cut skew gear for mechanical repairs.',
        weight = 1000,
        stack = false,
    },

    ['timingchain'] = {
        label = 'Timing Chain',
        description = 'A vehicle timing chain. Essential for proper engine function.',
        weight = 1000,
        stack = false,
    },

-- ── Jewelry & Valuables ───────────────────────────────────────────────────────

    ['rolex'] = {
        label = 'Golden Watch',
        description = 'A genuine golden Rolex watch. Very luxurious.',
        weight = 1500,
    },

    ['goldchain'] = {
        label = 'Golden Chain',
        description = 'A thick golden chain. Flashy and expensive.',
        weight = 1500,
    },

-- ── Crime & Heist ─────────────────────────────────────────────────────────────

    ['gatecrack'] = {
        label = 'Gatecrack',
        description = 'A device used to crack gate security systems.',
        weight = 1000,
    },

    ['cryptostick'] = {
        label = 'Crypto Stick',
        description = 'An encrypted USB stick for transferring sensitive data.',
        weight = 100,
    },

    ['trojan_usb'] = {
        label = 'Trojan USB',
        description = 'A USB loaded with malicious software. *Handle with care.*',
        weight = 100,
    },

    ['security_card_01'] = {
        label = 'Security Card A',
        description = 'A level A security access card.',
        weight = 100,
    },

    ['security_card_02'] = {
        label = 'Security Card B',
        description = 'A level B security access card.',
        weight = 100,
    },

    ['antipatharia_coral'] = {
        label = 'Antipatharia',
        description = 'A rare deep-sea antipatharia coral specimen. Highly valuable.',
        weight = 1000,
    },

    ['dendrogyra_coral'] = {
        label = 'Dendrogyra',
        description = 'A rare dendrogyra coral specimen. Highly valuable.',
        weight = 1000,
    },

-- ── Communication ─────────────────────────────────────────────────────────────

    ['phone'] = {
        label = 'Phone',
        description = 'Your personal smartphone. Stay connected in Los Santos.',
        weight = 190,
        stack = false,
        consume = 0,
    },

    ['phone_green'] = {
        label = 'Phone',
        description = 'Your personal smartphone. Stay connected in Los Santos.',
        weight = 190,
        stack = false,
        consume = 0,
    },

    ['phone_orange'] = {
        label = 'Phone',
        description = 'Your personal smartphone. Stay connected in Los Santos.',
        weight = 190,
        stack = false,
        consume = 0,
    },

    ['radio'] = {
        label = 'Radio',
        description = 'A portable radio for encrypted communications. Keep it on at all times.',
        weight = 1000,
        allowArmed = true,
        consume = 0,
        client = {
            event = 'mm_radio:client:use'
        }
    },

    ['jammer'] = {
        label = 'Radio Jammer',
        description = 'A device that disrupts radio communications in the surrounding area.',
        weight = 10000,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:usejammer'
        }
    },

    ['radiocell'] = {
        label = 'AAA Cells',
        description = 'AAA batteries used to recharge radio equipment.',
        weight = 1000,
        stack = true,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:recharge'
        }
    },

-- ── Properties (nolag_properties) ────────────────────────────────────────────

    ['housing_key'] = {
        label = 'Property Key',
        description = 'A key to a personal property. Keep it somewhere safe.',
        weight = 50,
        stack = false,
        close = true,
        consume = 0,
    },

    ['key_wax'] = {
        label = 'Key Impressioning Wax',
        description = 'Use this to take an impression of a key. Pressing the key into the wax creates a copy pattern.',
        weight = 10,
        consume = 0,
        unique = true,
        -- client = {
        --     image = 'key_wax.png',
        -- }
    },

    ['key_wax_used'] = {
        label = 'Used Key Impressioning Wax',
        description = 'Wax that already has a key impression in it. Use it to get the bitting code.',
        weight = 10,
        consume = 0,
        unique = true,
        client = {
            export = 'nolag_properties.getBittingCode',
            image = 'key_wax.png',
        }
    },

    ['furniture'] = {
        label = 'Furniture',
        description = 'A piece of furniture from a property.',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
        client = {
            export = 'nolag_properties.UseFurniture',
        },
    },

    ['lockpick'] = {
        label = 'Lockpick',
        description = 'A standard lockpick for getting past basic property locks.',
        weight = 160,
        client = {
            export = 'nolag_properties.UseLockpick',
        }
    },

-- ── Miscellaneous ─────────────────────────────────────────────────────────────

    ['firework1'] = {
        label = '2Brothers',
        description = 'A 2Brothers firework. Light it up and enjoy the show!',
        weight = 1000,
    },

    ['firework2'] = {
        label = 'Poppelers',
        description = 'A Poppelers firework. Light it up and enjoy the show!',
        weight = 1000,
    },

    ['firework3'] = {
        label = 'WipeOut',
        description = 'A WipeOut firework. Light it up and enjoy the show!',
        weight = 1000,
    },

    ['firework4'] = {
        label = 'Weeping Willow',
        description = 'A Weeping Willow firework. Light it up and enjoy the show!',
        weight = 1000,
    },

    ['flatbed_remote'] = {
        label = 'Flatbed Remote',
        description = 'Remote controller for a flatbed tow truck.',
        weight = 100,
    },

-- ── Av_Laptop, etc. ─────────────────────────────────────────────────────────────

['laptop'] = {
        label = 'Laptop',
        weight = 1,
        stack = false,
        close = true,
        description = '',
        buttons = {
            {
                label = "Devices",
                action = function(slot)
                    exports['av_laptop']:openContainer(slot)
                end,
            }
        }
    },

    ['decrypter'] = {
        label = 'Decrypter',
        weight = 1,
        stack = true,
        close = true,
        description = ''
    },

    ['black_usb'] = {
        label = 'Black USB',
        weight = 1,
        stack = true,
        close = true,
        description = ''
    },
    
    ['pendrive'] = {
        label = 'Pendrive',
        weight = 1,
        stack = false,
        close = false,
        description = 'Can store personal data'
    },
-- ── Food Ingredients ─────────────────────────────────────────────────────────────

    ['pendrive'] = {
        label = 'Pendrive',
        weight = 1,
        stack = false,
        close = false,
        description = 'Can store personal data'
    },




-- ── Food Products ─────────────────────────────────────────────────────────────

}
