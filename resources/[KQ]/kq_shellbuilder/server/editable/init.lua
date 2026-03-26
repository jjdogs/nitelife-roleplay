local function EnsureShellbuilderTableExists()
    local query = [[
        SELECT COUNT(*) as count
        FROM information_schema.tables
        WHERE table_name = 'kq_shellbuilder'
    ]]
    
    local result = DB.SqlQuery(query)
    if result and result[1] and result[1].count == 0 then
        -- Table does not exist, create it
        local createQuery = [[
            CREATE TABLE IF NOT EXISTS `kq_shellbuilder` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `title` text NOT NULL,
              `user` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`user`)),
              `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`coords`)),
              `settings` longtext DEFAULT NULL,
              `builder_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`builder_data`)),
              `spawn_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`spawn_data`)),
              `thumbnail` longtext DEFAULT NULL,
              `created_at` datetime NOT NULL DEFAULT current_timestamp(),
              `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
              `deleted_at` datetime DEFAULT NULL,
              PRIMARY KEY (`id`)
            ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
        ]]
        
        DB.SqlMutate(createQuery)
        print("^2kq_shellbuilder table created successfully.")
    end
end

Citizen.CreateThread(function()
    -- Call the function to ensure the table exists
    Citizen.SetTimeout(500, EnsureShellbuilderTableExists)
end)

-- Fallback for dynamic door creation allowance
SetConvarReplicated('game_enableDynamicDoorCreation', true)
