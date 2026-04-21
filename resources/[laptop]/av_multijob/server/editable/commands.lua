lib.addCommand('setjob', {
    help = 'Set a player current job and grade',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
        {
            name = 'job',
            type = 'string',
            help = 'Job name',
        },
        {
            name = 'grade',
            type = 'number',
            help = 'Job grade',
            optional = true,
        },
    },
    restricted = Config.AdminGroups
}, function(_, args)
    local target = args and args['target'] or false
    local name = args and args['job'] or false
    local grade = args and args['grade'] or false
    dbug("command setJob(target,name,grade)", target, name, grade)
    setJob(target, name, grade)
end)

lib.addCommand('addjob', {
    help = 'Add job to player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
        {
            name = 'job',
            type = 'string',
            help = 'Job name',
        },
        {
            name = 'grade',
            type = 'number',
            help = 'Job grade',
            optional = true,
        },
    },
    restricted = Config.AdminGroups
}, function(source, args)
    local target = args and args['target'] or false
    local name = args and args['job'] or false
    local grade = args and args['grade'] or false
    dbug("command addJob(target,name,grade)", target, name, grade)
    local success = addJob(target, name, grade)
    TriggerClientEvent("av_multijob:notification", source, Lang['title'], success and Lang['add_job_success'] or Lang['add_job_error'], success and "success" or "error")
end)

lib.addCommand('removejob', {
    help = 'Removes a job from player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
        {
            name = 'job',
            type = 'string',
            help = 'Job name',
        },
    },
    restricted = Config.AdminGroups
}, function(source, args)
    local target = args and args['target'] or false
    local name = args and args['job'] or false
    dbug("command removeJob(target,name,grade)", target, name)
    local success = removeJob(target, name)
    TriggerClientEvent("av_multijob:notification", source, Lang['title'], success and Lang['remove_job_success'] or Lang['remove_job_error'], success and "success" or "error")
end)
