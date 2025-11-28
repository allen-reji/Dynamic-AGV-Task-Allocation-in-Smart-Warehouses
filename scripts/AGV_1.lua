-- AGV_1 script ? fixed docking (no looping at WP_13)

function sysCall_init()
    agvName = "AGV_1"

    robot = sim.getObject('.')
    leftMotor = sim.getObject("../leftMotor")
    rightMotor = sim.getObject("../rightMotor")
    
    state = "idle" 
    currentTask = nil
    
    dockHandle = sim.getObjectHandle("WP_13") -- dock for AGV_1
    lastDrop = nil -- to remember last drop zone
    returningToDock = false -- tracks whether AGV is on a dock route
    docked = false -- NEW: true when AGV has reached and parked at dock
    
    fullRoute = {}
    currentTarget = 1
    targetThreshold = 0.3
    attachedPackage = nil

    wp1 = sim.getObjectHandle("WP_1")
    wp2 = sim.getObjectHandle("WP_2")
    wp3 = sim.getObjectHandle("WP_3")
    wp4 = sim.getObjectHandle("WP_4")
    wp5 = sim.getObjectHandle("WP_5")
    wp6 = sim.getObjectHandle("WP_6")
    wp7 = sim.getObjectHandle("WP_7")
    wp8 = sim.getObjectHandle("WP_8")
    wp9 = sim.getObjectHandle("WP_9")
    wp10 = sim.getObjectHandle("WP_10")
    wp11= sim.getObjectHandle("WP_11")
    wp12= sim.getObjectHandle("WP_12")
    wp13= sim.getObjectHandle("WP_13")
    wp16= sim.getObjectHandle("WP_16")

    routes = {
     {"Pickup_1", "Drop_1", {wp1}},
     {"Pickup_1", "Drop_2", {wp5, wp6}},
     {"Pickup_1", "Drop_3", {wp1, wp3}},
     {"Pickup_1", "Drop_4", {wp1, wp4}},
     
     {"Pickup_2", "Drop_1", {wp10, wp9, wp1,wp5}},
     {"Pickup_2", "Drop_2", {wp2}},
     {"Pickup_2", "Drop_3", {wp10, wp11,wp3,wp7}},
     {"Pickup_2", "Drop_4", {wp2, wp4}},
     
     {"Pickup_3", "Drop_1", {wp3, wp2, wp1}},
     {"Pickup_3", "Drop_2", {wp3, wp2}},
     {"Pickup_3", "Drop_3", {wp3}},
     {"Pickup_3", "Drop_4", {wp3, wp4}},
     
     {"Pickup_4", "Drop_1", {wp4, wp3, wp2, wp1}},
     {"Pickup_4", "Drop_2", {wp12, wp11, wp10,wp2,wp6}},
     {"Pickup_4", "Drop_3", {wp4, wp3}},
     {"Pickup_4", "Drop_4", {wp4}},
     
     {"Drop_1", "Pickup_1", {wp1}},
     {"Drop_1", "Pickup_2", {wp1, wp2}},
     {"Drop_1", "Pickup_3", {wp1, wp2, wp3}},
     {"Drop_1", "Pickup_4", {wp1, wp2, wp3, wp4}},
     
     {"Drop_2", "Pickup_1", {wp2, wp1}},
     {"Drop_2", "Pickup_2", {wp2}},
     {"Drop_2", "Pickup_3", {wp2, wp3}},
     {"Drop_2", "Pickup_4", {wp6, wp7, wp11, wp12}},
     
     {"Drop_3", "Pickup_1", {wp3, wp2, wp1}},
     {"Drop_3", "Pickup_2", {wp3, wp2}},
     {"Drop_3", "Pickup_3", {wp3}},
     {"Drop_3", "Pickup_4", {wp3, wp4}},
     
     {"Drop_4", "Pickup_1", {wp4, wp3, wp2, wp1}},
     {"Drop_4", "Pickup_2", {wp4, wp3, wp2}},
     {"Drop_4", "Pickup_3", {wp4, wp3}},
     {"Drop_4", "Pickup_4", {wp4}},

     -- Docking routes for AGV_1 (Drop -> WP_13)
     -- NOTE: wp13 included here so goToDock() does NOT need to append dockHandle
     {"Drop_1", "WP_13", {wp5, wp6, wp7, wp8, wp13}},
     {"Drop_2", "WP_13", {wp6, wp7, wp8, wp13}},
     {"Drop_3", "WP_13", {wp7, wp8, wp13}},
     {"Drop_4", "WP_13", {wp8, wp16, wp13}}
    }

    routeDict = {}
    for _, entry in ipairs(routes) do
        local from, to, wps = entry[1], entry[2], entry[3]
        routeDict[from.."|"..to] = wps
    end
end

function createFullRoute(task)
    local route = {}
    if not task then return route end

    local pickupHandle = sim.getObjectHandle(task.pickup)
    local dropHandle   = sim.getObjectHandle(task.drop)

    -- find nearest zone (Pickup_x or Drop_x)
    local nearestName = nil
    local nearestDist = math.huge
    local robotPos = sim.getObjectPosition(robot, -1)

    local zoneNames = {"Pickup_1","Pickup_2","Pickup_3","Pickup_4",
                       "Drop_1","Drop_2","Drop_3","Drop_4"}
    for _,name in ipairs(zoneNames) do
        local h = sim.getObjectHandle(name)
        local pos = sim.getObjectPosition(h, -1)
        local d = math.sqrt((pos[1]-robotPos[1])^2 + (pos[2]-robotPos[2])^2)
        if d < nearestDist then
            nearestDist = d
            nearestName = name
        end
    end

    local key1 = nearestName .. "|" .. task.pickup
    if routeDict[key1] then
        for _,wp in ipairs(routeDict[key1]) do
            table.insert(route, wp)
        end
    end
    table.insert(route, pickupHandle)

    local key2 = task.pickup .. "|" .. task.drop
    if routeDict[key2] then
        for _,wp in ipairs(routeDict[key2]) do
            table.insert(route, wp)
        end
    end
    table.insert(route, dropHandle)

    return route
end

-- GO TO DOCK: builds fullRoute using routeDict (WP_13 must be in dockRoute)
function goToDock(fromDrop)
    local key = fromDrop .. "|WP_13"
    local dockRoute = routeDict[key]
    if dockRoute then
        fullRoute = {}
        for _,wp in ipairs(dockRoute) do
            table.insert(fullRoute, wp)
        end
        -- do NOT append dockHandle here ? the dock (wp13) should be included in dockRoute
        currentTarget = 1
        returningToDock = true
        docked = false
        state = "busy"
        print(agvName .. " returning to dock from " .. fromDrop)
    else
        print("?? No docking route found for " .. key)
    end
end

function sysCall_actuation()
    if state == "idle" then
        sim.setJointTargetVelocity(leftMotor, 0)
        sim.setJointTargetVelocity(rightMotor, 0)

        local packedStates = sim.getStringSignal("agv_states")
        if packedStates then
            local agv_states = sim.unpackTable(packedStates)
            if agv_states and agv_states[agvName] and agv_states[agvName].state == "busy" and agv_states[agvName].currentTask then
                print(agvName .. " received a new task!")
                currentTask = agv_states[agvName].currentTask
                state = "busy"
                currentTarget = 1
                fullRoute = createFullRoute(currentTask)
                -- if task arrives while docked, allow movement
                docked = false
                returningToDock = false
            else
                -- if idle and no tasks and we have a lastDrop, start dock route
                -- only start docking if not already on dock-route and not already docked
                if lastDrop and not returningToDock and not docked then
                    goToDock(lastDrop)
                end
            end
        end
        return
    end

    if state == "busy" then
        if currentTarget > #fullRoute then
            -- route finished (could be normal task route OR dock route)
            if currentTask then
                -- finished a task route
                print(agvName .. " completed Task " .. currentTask.id)

                -- update shared state to idle
                local packedStates = sim.getStringSignal("agv_states")
                if packedStates then
                    local agv_states = sim.unpackTable(packedStates)
                    if agv_states and agv_states[agvName] then
                        agv_states[agvName].state = "idle"
                        agv_states[agvName].currentTask = nil
                        sim.setStringSignal("agv_states", sim.packTable(agv_states))
                    end
                end

                currentTask = nil
            else
                -- finished a dock route
                if returningToDock then
                    print(agvName .. " reached dock (WP_13) ? stopping and parked")
                    returningToDock = false
                    docked = true            -- now parked
                    lastDrop = nil           -- clear so we don't re-trigger docking
                    -- stop motors and keep parked
                    sim.setJointTargetVelocity(leftMotor, 0)
                    sim.setJointTargetVelocity(rightMotor, 0)
                end
            end

            state = "idle"
            attachedPackage = nil
            fullRoute = {}
            currentTarget = 1
            return
        end

        local target = fullRoute[currentTarget]
        local targetPos = sim.getObjectPosition(target, -1)
        local robotPos = sim.getObjectPosition(robot, -1)
        local dx, dy = targetPos[1]-robotPos[1], targetPos[2]-robotPos[2]
        local distance = math.sqrt(dx*dx + dy*dy)

        local taskPackageHandle, pickupHandle, dropHandle
        if currentTask then
            taskPackageHandle = sim.getObjectHandle(currentTask.package)
            pickupHandle = sim.getObjectHandle(currentTask.pickup)
            dropHandle = sim.getObjectHandle(currentTask.drop)
        end

        if distance < targetThreshold then
            if currentTask and target == pickupHandle and not attachedPackage then
                sim.setObjectParent(taskPackageHandle, robot, true)
                sim.setObjectPosition(taskPackageHandle, robot, {0,0,0.2})
                attachedPackage = taskPackageHandle
            end
            if currentTask and target == dropHandle and attachedPackage == taskPackageHandle then
                sim.setObjectParent(taskPackageHandle, -1, true)
                local dropPos = sim.getObjectPosition(robot, -1)
                sim.setObjectPosition(taskPackageHandle, -1, {dropPos[1], dropPos[2], 0.05})
                attachedPackage = nil
                -- record last drop when the package is actually dropped
                lastDrop = currentTask.drop
            end
            currentTarget = currentTarget + 1
            return
        end

        local angleToTarget = math.atan2(dy, dx)
        local orientation = sim.getObjectOrientation(robot, -1)[3]
        local error = angleToTarget - orientation
        if error > math.pi then error = error - 2*math.pi end
        if error < -math.pi then error = error + 2*math.pi end

        local v, k = 2, 2
        sim.setJointTargetVelocity(leftMotor, v - k*error)
        sim.setJointTargetVelocity(rightMotor, v + k*error)
    end
end
