--
-- created with TexturePacker - https://www.codeandweb.com/texturepacker
--
-- $TexturePacker:SmartUpdate:ebdea7c816e9272c1889a70e67446c3d:e16cd90c3a7bbcc874838cb361992580:cf8ab4992190eb44f97f06311ef326d7$
--

local M = {}

M.sheet = graphics.newImageSheet("assets/sprites/sheet.png", {
    frames = {
    
        {
            -- images/block-1
            x=976,
            y=1,
            width=572,
            height=238,

        },
        {
            -- images/block-2
            x=976,
            y=1249,
            width=488,
            height=197,

        },
        {
            -- images/block-3
            x=976,
            y=241,
            width=492,
            height=200,

            sourceX = 2,
            sourceY = 3,
            sourceWidth = 494,
            sourceHeight = 206
        },
        {
            -- images/block-4
            x=976,
            y=443,
            width=491,
            height=201,

            sourceX = 0,
            sourceY = 2,
            sourceWidth = 491,
            sourceHeight = 203
        },
        {
            -- images/block-5
            x=976,
            y=844,
            width=490,
            height=199,

        },
        {
            -- images/block-6
            x=976,
            y=1045,
            width=489,
            height=202,

        },
        {
            -- images/block-7
            x=976,
            y=646,
            width=491,
            height=196,

        },
        {
            -- images/block-8
            x=1466,
            y=1338,
            width=487,
            height=196,

        },
        {
            -- images/block-9
            x=1470,
            y=350,
            width=484,
            height=199,

        },
        {
            -- images/block-10
            x=1,
            y=1368,
            width=487,
            height=195,

        },
        {
            -- images/block-11
            x=1467,
            y=1140,
            width=487,
            height=196,

        },
        {
            -- images/block-12
            x=318,
            y=646,
            width=484,
            height=193,

        },
        {
            -- images/block-13
            x=1469,
            y=551,
            width=483,
            height=197,

        },
        {
            -- images/block-14
            x=490,
            y=1368,
            width=484,
            height=195,

        },
        {
            -- images/clock
            x=1,
            y=1,
            width=315,
            height=838,

            sourceX = 3,
            sourceY = 0,
            sourceWidth = 321,
            sourceHeight = 838
        },
        {
            -- images/exit
            x=509,
            y=841,
            width=272,
            height=216,

        },
        {
            -- images/heart
            x=570,
            y=390,
            width=249,
            height=246,

        },
        {
            -- images/heart_full
            x=318,
            y=390,
            width=250,
            height=246,

        },
        {
            -- images/lock-icon
            x=804,
            y=1,
            width=146,
            height=186,

            sourceX = 38,
            sourceY = 18,
            sourceWidth = 216,
            sourceHeight = 216
        },
        {
            -- images/logo
            x=735,
            y=1059,
            width=237,
            height=228,

        },
        {
            -- images/lose
            x=1550,
            y=1,
            width=393,
            height=347,

        },
        {
            -- images/lvl-locked
            x=318,
            y=1,
            width=466,
            height=387,

            sourceX = 0,
            sourceY = 0,
            sourceWidth = 466,
            sourceHeight = 391
        },
        {
            -- images/lvl-unlocked
            x=1469,
            y=750,
            width=468,
            height=388,

            sourceX = 0,
            sourceY = 0,
            sourceWidth = 468,
            sourceHeight = 398
        },
        {
            -- images/numbers
            x=1,
            y=841,
            width=506,
            height=525,

            sourceX = 0,
            sourceY = 2,
            sourceWidth = 508,
            sourceHeight = 533
        },
        {
            -- images/win
            x=509,
            y=1059,
            width=224,
            height=256,

        },
    },

    sheetContentWidth = 1955,
    sheetContentHeight = 1564
})

M.frameIndex = {
  ["images/block-1"] = 1,
  ["images/block-2"] = 2,
  ["images/block-3"] = 3,
  ["images/block-4"] = 4,
  ["images/block-5"] = 5,
  ["images/block-6"] = 6,
  ["images/block-7"] = 7,
  ["images/block-8"] = 8,
  ["images/block-9"] = 9,
  ["images/block-10"] = 10,
  ["images/block-11"] = 11,
  ["images/block-12"] = 12,
  ["images/block-13"] = 13,
  ["images/block-14"] = 14,
  ["images/clock"] = 15,
  ["images/exit"] = 16,
  ["images/heart"] = 17,
  ["images/heart_full"] = 18,
  ["images/lock-icon"] = 19,
  ["images/logo"] = 20,
  ["images/lose"] = 21,
  ["images/lvl-locked"] = 22,
  ["images/lvl-unlocked"] = 23,
  ["images/numbers"] = 24,
  ["images/win"] = 25,
}

return M
