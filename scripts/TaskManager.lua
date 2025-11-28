-- TaskManager Script (Corrected with Signals)

function sysCall_init()
    print("Task Manager Initialized.")

    masterTasks = {
        {id=1, package = "Package_1", pickup = "Pickup_4", drop = "Drop_2", status = "unassigned"},
        {id=2, package = "Package_2", pickup = "Pickup_2", drop = "Drop_1", status = "unassigned"},
        {id=3, package = "Package_3", pickup = "Pickup_3", drop = "Drop_4", status = "unassigned"},
        {id=4, package = "Package_4", pickup = "Pickup_1", drop = "Drop_3", status = "unassigned"},
        {id=5, package = "Package_5", pickup = "Pickup_4", drop = "Drop_2", status = "unassigned"},
        {id=6, package = "Package_6", pickup = "Pickup_2", drop = "Drop_1", status = "unassigned"},
        {id=7, package = "Package_7", pickup = "Pickup_2", drop = "Drop_3", status = "unassigned"},
        {id=8, package = "Package_8", pickup = "Pickup_3", drop = "Drop_4", status = "unassigned"},
        {id=9, package = "Package_9", pickup = "Pickup_1", drop = "Drop_2", status = "unassigned"},
        {id=10, package = "Package_10", pickup = "Pickup_4", drop = "Drop_1", status = "unassigned"}
    }

    agv_states = {
        AGV_1 = {state = "idle", currentTask = nil},
        AGV_2 = {state = "idle", currentTask = nil},
        AGV_3 = {state = "idle", currentTask = nil}
    }
    
    -- CORRECTED LINE: Pack the table and broadcast it as a string signal
    sim.setStringSignal("agv_states", sim.packTable(agv_states))

    objectHandles = {
        AGV_1 = sim.getObjectHandle("AGV_1"),
        AGV_2 = sim.getObjectHandle("AGV_2"),
        AGV_3 = sim.getObjectHandle("AGV_3"),
        Pickup_1 = sim.getObjectHandle("Pickup_1"),
        Pickup_2 = sim.getObjectHandle("Pickup_2"),
        Pickup_3 = sim.getObjectHandle("Pickup_3"),
        Pickup_4 = sim.getObjectHandle("Pickup_4")
    }
end

function getDistance(obj1Handle, obj2Handle)
    local pos1 = sim.getObjectPosition(obj1Handle, -1)
    local pos2 = sim.getObjectPosition(obj2Handle, -1)
    return math.sqrt((pos2[1]-pos1[1])^2 + (pos2[2]-pos1[2])^2)
end

function sysCall_actuation()
    -- CORRECTED LINE: Read the string signal
    local packedStates = sim.getStringSignal("agv_states")
    if not packedStates then return end -- Exit if signal hasn't been set yet
    local current_agv_states = sim.unpackTable(packedStates)

    for i, task in ipairs(masterTasks) do
        if task.status == "unassigned" then
            local closestAgv = nil
            local minDistance = math.huge

            for agvName, agvData in pairs(current_agv_states) do
                if agvData.state == "idle" then
                    local agvHandle = objectHandles[agvName]
                    local pickupHandle = objectHandles[task.pickup]
                    local distance = getDistance(agvHandle, pickupHandle)
                    
                    if distance < minDistance then
                        minDistance = distance
                        closestAgv = agvName
                    end
                end
            end

            if closestAgv then
                print("Assigning Task "..task.id.." to "..closestAgv)
                task.status = "assigned"
                current_agv_states[closestAgv].state = "busy"
                current_agv_states[closestAgv].currentTask = task
                
                -- CORRECTED LINE: Set the string signal with the new data
                sim.setStringSignal("agv_states", sim.packTable(current_agv_states))
                
                return 
            end
        end
    end
end