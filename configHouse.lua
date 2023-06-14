-- Contents of configHouse.lua
-- This file contains the configuration settings for houses in your GTA V modification.

config.house = {
    [1] = {
        mlo = true,
        label = "Luxury House",
        rental_period = "week",
        rate = 1000,
        rentBuyCoord = vector3(100.0, 200.0, 300.0),
        doors = {
            [1] = {
                coord = vector3(105.0, 205.0, 305.0),
                model = GetHashKey("door_model"),
            },
            [2] = {
                coord = vector3(110.0, 210.0, 310.0),
                model = GetHashKey("door_model"),
            },
        },
        stashes = {
            [1] = {
                stash = vector3(115.0, 215.0, 315.0),
                wardrobe = vector3(120.0, 220.0, 320.0),
                fridge = vector3(125.0, 225.0, 325.0),
            },
        },
    },
    [2] = {
        mlo = false,
        label = "Standard House",
        rental_period = "month",
        rate = 2000,
        rentBuyCoord = vector3(150.0, 250.0, 350.0),
        doors = {
            [1] = {
                coord = vector3(155.0, 255.0, 355.0),
                model = GetHashKey("door_model"),
            },
            [2] = {
                coord = vector3(160.0, 260.0, 360.0),
                model = GetHashKey("door_model"),
            },
        },
        stashes = {
            [1] = {
                stash = vector3(165.0, 265.0, 365.0),
                wardrobe = vector3(170.0, 270.0, 370.0),
                fridge = vector3(175.0, 275.0, 375.0),
            },
        },
    },
}
