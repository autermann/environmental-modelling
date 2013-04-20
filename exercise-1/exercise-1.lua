function ro(table)
    return setmetatable({},{
        __index = table,
        __newindex = function(t, n, v)
            error "table is read-only"
        end
    })
end

function tofunc(x)
    return type(x) == "function" and x or function() return x end
end

CONSTANTS = ro({
    START_YEAR = 1950,
    RAINFALLS = ro({ 2.0e9, 1.5e9 }),
    CAPACITY = 5e9,
    CONSUMPTION_CHANGE = 1.05,
    COSTS = 100,
    INITIAL_POPULATION = 1e5,
    INITIAL_CONSUMPTION = 10,
    POPULATION_GROWTH = 1
})

function Model(o)
    o = o or {}
    -- the current year
    o.year = o.year or CONSTANTS.START_YEAR
    -- the month of the year (0..11)
    o.month = 0
    -- the number of inhabitants
    o.population = o.population or CONSTANTS.INITIAL_POPULATION
    -- the energy consumption per inhabitant (in kWh)
    o.cpi = o.cpi or CONSTANTS.INITIAL_CONSUMPTION
    -- the costs of 1kWh (in m^3)
    o.costs = tofunc(o.costs or CONSTANTS.COSTS)
    -- the yearly increase in consumption
    o.consumptionChange = tofunc(o.consumptionChange or CONSTANTS.CONSUMPTION_CHANGE)
    -- the rainfall amount (in m^3)
    o.rainfalls = tofunc(o.rainfalls or CONSTANTS.RAINFALLS)
    -- the maximum water capacity (in m^3)
    o.capacity = tofunc(o.capacity or CONSTANTS.CAPACITY)
    -- the yearly increase in population
    o.populationGrowth = tofunc(o.populationGrowth or CONSTANTS.POPULATION_GROWTH)
    -- the current water level (in m^3)
    o.water = o.water or o:capacity()

    o._energyConsumption = o.population * o.cpi
    o._waterConsumption = o:costs() * o.population * o.cpi

    o.changeWater = o.changeWater or function(self, amount)
        self.water = self.water + amount;
        if self.water > self:capacity() then 
            self.water = self:capacity()
        elseif self.water < 0 then 
            self.water = 0 
        end
    end

    o.run = function(self, years)
        local o1 = Observer{ 
            subject = self, 
            type = "chart",
            title = self.name,
            xLabel = "Month", 
            yLabel = "m^3", 
            attributes = { "water", "_waterConsumption"},
            curveLabels = { "Waterlevel", "Cosumption"}
        }
        local t = Timer{
            -- keeping track of the month
            Event{ action = function(e) self.month = (self.month + 1) % 12 end},
            -- keeping track of the year
            Event{ time = 12, period = 12, 
                   action = function(e) self.year = self.year + 1 end},
            -- let the population change there usage patterns
            Event{ time = 2, action = function(e)
                self.cpi = self.cpi * (self:consumptionChange()^(1/12)) end},
            -- let it rain
            Event{ action = function(e)
                self:changeWater((1/6) * self:rainfalls()[self.month % 12 < 6 and 1 or 2])
            end},
            -- let the population grow/shrink
            Event{ action = function(e) 
                self.population = self.population 
                            * (self:populationGrowth()^(1/12))
            end},
            -- let the population consume energy
            Event{ action = function(e)
                self._energyConsumption = self.population * self.cpi
                self._waterConsumption = self:costs() * self._energyConsumption
                self:changeWater(-self._waterConsumption)
            end},
            -- notify observers
            Event{ time = 0, action = function(e) 
                self:notify(e:getTime())
            end}
        }
        t:execute(years * 12)
    end
    return Cell(o)
end

-- model parameter definitions
local models = {{
    -- model 1
    model = Model{}, 
    runtime = 30 
}, { 
    -- model 2
    model = Model{ costs = 80 }, 
    runtime = 35
}, {
    -- model 3
    model = Model{
        consumptionChange = 1 + .5 * (CONSTANTS.CONSUMPTION_CHANGE - 1)
    }, 
    runtime = 55
}, {
    -- model 4
    model = Model{
        rainfalls = function(self)
            if self.year >= 1970 then
                return { .5 * CONSTANTS.RAINFALLS[1], 
                         .5 * CONSTANTS.RAINFALLS[2] }
            else
                return CONSTANTS.RAINFALLS
            end
        end
    }, 
    runtime = 25
}, {
    -- model 5
    model = Model{
        costs = 80,
        consumptionChange = 1 + .5 * (CONSTANTS.CONSUMPTION_CHANGE - 1),
        rainfalls = function(self)
            if self.year >= 1970 then
                return {  .5 * CONSTANTS.RAINFALLS[1] , 
                          .5 * CONSTANTS.RAINFALLS[2] }
            else
                return CONSTANTS.RAINFALLS
            end
        end
    }, 
    runtime = 40
}, {
    
    model = Model{
        years = function(self) 
            return self.year - CONSTANTS.START_YEAR
        end,
        costs = function(self)
            return CONSTANTS.COSTS * 0.99 ^ self:years()
        end, 
        consumptionChange = function(self)
            return 1.01 ^ self:years()
        end,
        rainfalls = function(self)
            local change = .95 ^ self:years()
            return { CONSTANTS.RAINFALLS[1] * change, 
                     CONSTANTS.RAINFALLS[2] * change }
        end,
        populationGrowth = 1.0001,
        capacity = function(self)
            if self.year < 1980 then
                return CONSTANTS.CAPACITY
            else
                return CONSTANTS.CAPACITY + 2e9
            end
        end
    }, 
    runtime = 17
}}

-- model runs
for i,m in ipairs(models) do
    m.model.name = "Model  " .. i
    m.model:run(m.runtime)
end
