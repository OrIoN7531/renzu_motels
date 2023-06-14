config = {}
config.wardrobe = 'illenium-appearance' -- choose your skin menu
config.target = true -- false = markers zones type. true = ox_target, qb-target
config.business = true -- allowed players to purchase the motel
config.autokickIfExpire = true -- auto kick occupants if rent is due. if false owner of motel must kick the occupants
config.breakinJobs = { -- jobs can break in to door using gunfire in doors
	['lspd'] = true,
	['bcso'] = true,
	['sasp'] = true,
	['sapr'] = true,
}
config.wardrobes = { -- skin menus
	['renzu_clothes'] = function()
		exports.renzu_clothes:OpenClotheInventory()
	end,
	['fivem-appearance'] = function()
		return exports['fivem-appearance']:startPlayerCustomization() -- you could replace this with outfits events
	end,
	['illenium-appearance'] = function()
		return TriggerEvent('illenium-appearance:client:openOutfitMenu')
	end,
	['qb-clothing'] = function()
		return TriggerEvent('qb-clothing:client:openOutfitMenu')
	end,
	['esx_skin'] = function()
		TriggerEvent('esx_skin:openSaveableMenu')
	end,
}

-- Shells Offsets and model name
config.shells = {
	['standard'] = {
		shell = `standardmotel_shell`, -- kambi shell
		offsets = {
			exit = vec3(-0.43,-2.51,1.16),
			stash = vec3(1.368164, -3.134506, 1.16),
			wardrobe = vec3(1.643646, 2.551102, 1.16),
		}
	},
	['modern'] = {
		shell = `modernhotel_shell`, -- kambi shell
		offsets = {
			exit = vec3(5.410095, 4.299301, 0.9),
			stash = vec3(-4.068207, 4.046188, 0.9),
			wardrobe = vec3(2.811829, -3.619385, 0.9),
		}
	},
}

config.messageApi = function(data) -- {title,message,motel}
	local motel = GlobalState.Motels[data.motel]
	local identifier = motel.owned -- owner identifier
	-- add your custom message here. ex. SMS phone 
	local mailData = {
		sender = data.motel,
		subject = data.title,
		message = data.message,
	}
	exports["qb-phone"]:sendNewMailToOffline(identifier, mailData)

	-- basic notification (remove this if using your own message system)
	local success = lib.callback.await('renzu_motels:MessageOwner',false,{identifier = identifier, message = data.message, title = data.title, motel = data.motel})
	if success then
		Notify('message has been sent', 'success')
	else
		Notify('message fail  \n  owner is not available yet', 'error')
	end
end

-- @shell string (shell type)
-- @Mlo string ( toggle MLO or shell type)
-- @hour_rate int ( per hour rates)
-- @motel string (Motel Index Name)
-- @rentcoord vec3 (coordinates of Rental Menu)
-- @radius float ( total size radius of motel )
-- @maxoccupants int (total player can rent in each Rooms)
-- @uniquestash bool ( Toggle Non Sharable / Stealable Stash Storage )
-- @doors table ( lists of doors feature coordinates. ex. stash, wardrobe) wardrobe,stash coords are only applicable in Mlo. using shells has offsets for stash and wardrobes.
-- @manual boolean ( accept walk in occupants only )
-- @businessprice int ( value of motel)
-- @door int (door hash or doormodel `model`) for MLO type

config.motels = {
	[1] = { -- index name of motel
		manual = false, -- set the motel to auto accept occupants or false only the owner of motel can accept Occupants
		Mlo = true, -- if MLO you need to configure each doors coordinates,stash etc. if false resource will use shells
		shell = 'standard', -- shell type, configure only if using Mlo = true
		label = 'Pink Cage Motel',
		rental_period = 'day',-- hour, day, month
		rate = 1000, -- cost per period
		businessprice = 1000000,
		motel = 'Pinkcage',
		payment = 'money', -- money, bank
		door = `gabz_pinkcage_doors_front`, -- door hash for MLO type
		rentcoord = vec3(313.38,-225.20,54.212),
		coord = vec3(326.04,-210.47,54.086), -- center of the motel location
		radius = 50.0, -- radius of motel location
		maxoccupants = 1, -- maximum renters per room
		uniquestash = false, -- if true. each players has unique stash ID (non sharable and non stealable). if false stash is shared to all Occupants if maxoccupans is > 1
		doors = { -- doors and other function of each rooms
			[1] = { -- COORDINATES FOR GABZ PINKCAGE
			door = { -- Door config requires when using MLO
				[1] = { -- requested by community. supports multiple door models.
					coord = vec3(307.21499633789,-212.79479980469,54.420265197754), -- exact coordinates of door
					model = `gabz_pinkcage_doors_front` -- model of target door coordinates
				},
				-- [2] = {
				-- 	coord = vec3(306.67614746094,-215.63456726074,54.22175),
				-- 	model = `gabz_pinkcage_doors_front` -- model of target door coordinates
				-- }
				-- support multiple doors just add new line of table 
			},
			stash = vec3(307.01657104492,-207.91079711914,53.758548736572), --  requires when using MLO
			wardrobe = vec3(302.58380126953,-207.71691894531,54.598297119141), --  requires when using MLO
			fridge = vec3(305.00064086914,-206.12855529785,54.544868469238), --  requires when using MLO
			-- luckyme = vec3(0.0,0.0,0.0) -- extra
			},
			[2] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(310.95474243164,-202.91288757324,54.421058654785), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(310.91235351563,-198.10073852539,53.758598327637),
				wardrobe = vec3(306.25433349609,-197.75250244141,54.564342498779),
				fridge = vec3(308.79779052734,-196.23670959473,54.440326690674),
			},
			[3] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(316.28607177734,-194.54536437988,54.391784667969), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(321.10150146484,-194.42211914063,53.758399963379),
				wardrobe = vec3(321.42459106445,-189.79216003418,54.65941619873),
				fridge = vec3(322.92010498047,-192.31481933594,54.600353240967),
			},
			[4] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(314.36087036133,-219.91516113281,58.151386260986), -- exact coordinates of door
						model = -1470537248 -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},			
				stash = vec3(309.6142578125,-220.16128540039,57.557399749756),
				wardrobe = vec3(309.21203613281,-224.6675567627,58.375194549561),
				fridge = vec3(307.6989440918,-222.11755371094,58.293560028076),
			},
			[5] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(307.22616577148,-212.77645874023,58.204700469971), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(306.89093017578,-207.88090515137,57.556159973145),
				wardrobe = vec3(302.57464599609,-207.71339416504,58.440250396729),
				fridge = vec3(305.044921875,-205.99066162109,58.394989013672),
			},
			[6] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(311.00057983398,-202.87718200684,58.148029327393), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(310.88967895508,-198.16856384277,57.556510925293),
				wardrobe = vec3(306.09225463867,-198.40795898438,58.27188873291),
				fridge = vec3(308.73110961914,-196.40968322754,58.407859802246),
			},
			[7] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(316.29287719727,-194.5479888916,58.212650299072), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(321.24801635742,-194.29737854004,57.556739807129),
				wardrobe = vec3(321.46688842773,-189.68632507324,58.422557830811),
				fridge = vec3(322.98544311523,-192.33996582031,58.386581420898),
			},
			[8] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(339.43377685547,-219.99412536621,54.431659698486), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(339.67279052734,-224.8221282959,53.759098052979),
				wardrobe = vec3(344.28637695313,-224.95460510254,54.527130126953),
				fridge = vec3(341.86477661133,-226.15287780762,54.642837524414),
			},
			[9] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(343.23126220703,-210.10203552246,54.410026550293), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(343.47601318359,-214.96635437012,53.758640289307),
				wardrobe = vec3(347.99655151367,-215.08934020996,54.489669799805),
				fridge = vec3(345.53387451172,-216.53938293457,54.698444366455),
			},
			[10] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(347.0237121582,-200.22482299805,54.414268493652), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(347.33102416992,-205.13743591309,53.759078979492),
				wardrobe = vec3(351.68756103516,-205.30010986328,54.674419403076),
				fridge = vec3(349.34033203125,-206.6258392334,54.639694213867),
			},
			[11] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(334.44702148438,-227.61134338379,58.205139160156), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(329.67590332031,-227.8233795166,57.556579589844),
				wardrobe = vec3(329.43222045898,-232.33073425293,58.42276763916),
				fridge = vec3(327.64138793945,-229.79788208008,58.355628967285),
			},
			[12] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(339.44650268555,-219.9709777832,58.177570343018), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(339.79351806641,-224.86245727539,57.55553817749),
				wardrobe = vec3(344.26574707031,-225.00813293457,58.302909851074),
				fridge = vec3(341.6985168457,-226.52975463867,58.367748260498),
			},
			[13] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(343.22320556641,-210.1229095459,58.176639556885), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(343.47412109375,-214.96145629883,57.55553817749),
				wardrobe = vec3(348.07550048828,-215.08416748047,58.288040161133),
				fridge = vec3(345.40502929688,-216.88189697266,58.281555175781),
			},
			[14] = {
				door = { -- Door config requires when using MLO
					[1] = { -- requested by community. supports multiple door models.
						coord = vec3(347.03012084961,-200.20816040039,58.177433013916), -- exact coordinates of door
						model = `gabz_pinkcage_doors_front` -- model of target door coordinates
					},
					-- support multiple doors just add new line of table 
				},
				stash = vec3(347.12841796875,-205.05494689941,57.55553817749),
				wardrobe = vec3(351.77719116211,-205.24267578125,58.351734161377),
				fridge = vec3(349.24819946289,-206.78134155273,58.326892852783),
			},
			
		},
	},

	[2] = {
		manual = false,
		Mlo = true,
		shell = 'standard',
		label = 'Starlite Motel',
		rental_period = 'day',
		rate = 1000,
		businessprice = 1000000,
		motel = 'Starlite',
		payment = 'money',
		door = 597055185,
		rentcoord = vec3(961.637, -193.847, 73.208),
		coord = vec3(959.48468017578, -201.86114501953, 73.132232666016),
		radius = 50.0,
		maxoccupants = 1,
		uniquestash = true,
		doors = {
			[1] = {
			door = {
				[1] = {
					coord = vec3(971.40728759766, -199.32736206055, 73.678688049316),
					model = 597055185
				},
			},
				stash = vec3(975.33288574219, -202.30815124512, 72.877952575684),
				wardrobe = vec3(974.83404541016, -199.15603637695, 73.579978942871),
				fridge = vec3(973.38922119141, -198.57757568359, 73.585090637207),
			},
			[2] = {
			door = {
				[1] = {
					coord = vec3(967.65661621094, -205.49795532227, 73.606285095215),
					model = 597055185
				},
			},
				stash = vec3(972.03594970703, -207.79371643066, 72.714653015137),
				wardrobe = vec3(971.22033691406, -204.79180908203, 73.72004699707),
				fridge = vec3(969.87084960938, -204.15612792969, 73.517417907715),
			},
			[3] = {
			door = {
				[1] = {
					coord = vec3(951.47314453125, -211.04978942871, 73.634780883789),
					model = 597055185
				},
			},
				stash = vec3(948.79132080078, -215.21072387695, 72.682991027832),
				wardrobe = vec3(952.49981689453, -213.83111572266, 73.455390930176),
				fridge = vec3(952.72045898438, -213.16464233398, 73.359466552734),
			},
			[4] = {
			door = {
				[1] = {
					coord = vec3(947.27197265625, -205.63261413574, 73.632331848145),
					model = 597055185
				},
			},
				stash = vec3(943.09350585938, -202.95404052734, 72.700187683105),
				wardrobe = vec3(944.23742675781, -206.45213317871, 73.51049041748),
				fridge = vec3(944.90582275391, -206.79597473145, 73.560691833496),
			},
			[5] = {
			door = {
				[1] = {
					coord = vec3(949.97735595703, -201.09927368164, 73.495895385742),
					model = 597055185
				},
			},
				stash = vec3(945.88610839844, -198.27688598633, 72.799369812012),
				wardrobe = vec3(946.98840332031, -201.77932739258, 73.474411010742),
				fridge = vec3(948.11572265625, -202.27616882324, 73.565315246582),
			},
			[6] = {
			door = {
				[1] = {
					coord = vec3(970.8674926757813, -200.19839477539063, 73.52980041503906),
					model = 597055185
				},
			},
				stash = vec3(948.6259765625, -193.75932312012, 72.867538452148),
				wardrobe = vec3(949.76055908203, -197.13719177246, 73.614677429199),
				fridge = vec3(950.82110595703, -197.59585571289, 73.698806762695),
			},
			[7] = {
			door = {
				[1] = {
					coord = vec3(971.17022705078, -199.63832092285, 76.695861816406),
					model = 597055185
				},
			},
				stash = vec3(974.65417480469, -201.29571533203, 76.576095581055),
				wardrobe = vec3(974.12255859375, -198.8509979248, 76.515090942383),
				fridge = vec3(973.29278564453, -198.53031921387, 76.627555847168),
			},
			[8] = {
			door = {
				[1] = {
					coord = vec3(967.64477539063, -205.47323608398, 76.595626831055),
					model = 597055185
				},
			},
				stash = vec3(971.9609375, -207.88061523438, 75.731307983398),
				wardrobe = vec3(970.59149169922, -204.4263458252, 76.588256835938),
				fridge = vec3(969.92437744141, -204.20211791992, 76.627738952637),
			},
			[9] = {
			door = {
				[1] = {
					coord = vec3(964.91937255859, -209.98188781738, 76.559394836426),
					model = 597055185
				},
			},
				stash = vec3(969.37939453125, -212.52914428711, 75.946830749512),
				wardrobe = vec3(968.45703125, -209.49839782715, 76.607765197754),
				fridge = vec3(966.78161621094, -208.67276000977, 76.532005310059),
			},
			[10] = {
			door = {
				[1] = {
					coord = vec3(962.259765625, -214.35900878906, 76.476020812988),
					model = 597055185
				},
			},
				stash = vec3(966.20056152344, -217.40635681152, 75.584564208984),
				wardrobe = vec3(965.26153564453, -213.87252807617, 76.499649047852),
				fridge = vec3(964.17877197266, -213.40081787109, 76.55054473877),
			},
			[11] = {
			door = {
				[1] = {
					coord = vec3(957.31018066406, -214.79817199707, 76.705223083496),
					model = 597055185
				},
			},
				stash = vec3(954.77996826172, -218.77613830566, 75.558532714844),
				wardrobe = vec3(958.15850830078, -217.77630615234, 76.527374267578),
				fridge = vec3(958.64105224609, -216.67594909668, 76.508972167969),
			},
			[12] = {
			door = {
				[1] = {
					coord = vec3(948.35546875, -209.19184875488, 76.627136230469),
					model = 597055185
				},
			},
				stash = vec3(945.94500732422, -213.50917053223, 75.825233459473),
				wardrobe = vec3(949.20874023438, -212.41854858398, 76.770317077637),
				fridge = vec3(949.55078125, -211.56001281738, 76.583053588867),
			},
			[13] = {
			door = {
				[1] = {
					coord = vec3(947.29357910156, -205.61698913574, 76.53458404541),
					model = 597055185
				},
			},
				stash = vec3(943.02545166016, -203.09826660156, 75.896255493164),
				wardrobe = vec3(944.04962158203, -206.35200500488, 76.714340209961),
				fridge = vec3(945.27081298828, -206.90612792969, 76.714065551758),
			},
			[14] = {
			door = {
				[1] = {
					coord = vec3(949.94274902344, -201.14236450195, 76.441665649414),
					model = 597055185
				},
			},
				stash = vec3(945.64233398438, -198.44741821289, 76.046394348145),
				wardrobe = vec3(946.93127441406, -201.74772644043, 76.472450256348),
				fridge = vec3(947.96765136719, -202.1921081543, 76.48641204834),
			},
			[15] = {
			door = {
				[1] = {
					coord = vec3(971.01239013672, -199.79989624023, 79.694198608398),
					model = 597055185
				},
			},
				stash = vec3(975.29400634766, -202.26635742188, 78.813568115234),
				wardrobe = vec3(974.39935302734, -198.99630737305, 79.58863067627),
				fridge = vec3(972.93450927734, -198.30795288086, 79.832542419434),
			},
			[16] = {
			door = {
				[1] = {
					coord = vec3(967.75421142578, -205.33058166504, 79.671905517578),
					model = 597055185
				},
			},
				stash = vec3(971.90338134766, -208.02128601074, 78.723815917969),
				wardrobe = vec3(970.81817626953, -204.57745361328, 79.641677856445),
				fridge = vec3(969.65869140625, -204.06256103516, 79.689140319824),
			},
			[17] = {
			door = {
				[1] = {
					coord = vec3(965.03686523438, -209.8426361084, 79.580642700195),
					model = 597055185
				},
			},
				stash = vec3(969.06231689453, -212.74583435059, 78.696464538574),
				wardrobe = vec3(967.98956298828, -209.19592285156, 79.70677947998),
				fridge = vec3(966.93762207031, -208.74429321289, 79.75074005127),
			},
			[18] = {
			door = {
				[1] = {
					coord = vec3(962.08801269531, -214.77392578125, 79.592094421387),
					model = 597055185
				},
			},
				stash = vec3(966.34875488281, -217.27565002441, 78.691184997559),
				wardrobe = vec3(965.27868652344, -213.88522338867, 79.549957275391),
				fridge = vec3(964.185546875, -213.40766906738, 79.540016174316),
			},
			[19] = {
			door = {
				[1] = {
					coord = vec3(957.49572753906, -214.68035888672, 79.65202331543),
					model = 597055185
				},
			},
				stash = vec3(954.87756347656, -218.87417602539, 78.715538024902),
				wardrobe = vec3(958.12622070313, -217.8113861084, 79.750907897949),
				fridge = vec3(958.75933837891, -216.44885253906, 79.558364868164),
			},
			[20] = {
			door = {
				[1] = {
					coord = vec3(948.44769287109, -209.22448730469, 79.704551696777),
					model = 597055185
				},
			},
				stash = vec3(945.57849121094, -213.27201843262, 78.609077453613),
				wardrobe = vec3(949.28234863281, -212.29479980469, 79.507026672363),
				fridge = vec3(949.73608398438, -211.24375915527, 79.694564819336),
			},
			[21] = {
			door = {
				[1] = {
					coord = vec3(947.14849853516, -205.79724121094, 79.473808288574),
					model = 597055185
				},
			},
				stash = vec3(943.07775878906, -202.94146728516, 78.830978393555),
				wardrobe = vec3(944.16607666016, -206.40676879883, 79.609115600586),
				fridge = vec3(945.35491943359, -206.93989562988, 79.695732116699),
			},
			[22] = {
			door = {
				[1] = {
					coord = vec3(950.02075195313, -201.04502868652, 79.700607299805),
					model = 597055185
				},
			},
				stash = vec3(945.80688476563, -198.42933654785, 78.833381652832),
				wardrobe = vec3(947.10034179688, -201.85150146484, 79.462692260742),
				fridge = vec3(948.07202148438, -202.25625610352, 79.633483886719),
			},
			[23] = {
			door = {
				[1] = {
					coord = vec3(952.64031982422, -196.72016906738, 79.535690307617),
					model = 597055185
				},
			},
				stash = vec3(948.6650390625, -193.70137023926, 78.82396697998),
				wardrobe = vec3(949.82629394531, -197.16143798828, 79.470352172852),
				fridge = vec3(950.94549560547, -197.65454101563, 79.735717773438),
			},
	},
},

	-- [2] = { -- index name of motel
	-- 	manual = false, -- set the motel to auto accept occupants or false only the owner of motel can accept Occupants
	-- 	Mlo = true, -- if MLO you need to configure each doors coordinates,stash etc. if false resource will use shells
	-- 	shell = 'modern', -- shell type, configure only if using Mlo = true
	-- 	label = 'Yacht Club Motel',
	-- 	rental_period = 'day',-- hour, day, month
	-- 	payment = 'money', -- money, bank
	-- 	rate = 1000, -- cost per period
	-- 	motel = 'yacht',
	-- 	door = `gabz_pinkcage_doors_front`, -- door hash for MLO type
	-- 	businessprice = 1000000,
	-- 	rentcoord = vec3(-916.54,-1302.56,6.2001),
	-- 	coord = vec3(-916.54,-1302.56,6.2001), -- center of the motel location
	-- 	radius = 50.0, -- radius of motel location
	-- 	maxoccupants = 5, -- maximum renters per room
	-- 	uniquestash = true, -- if true. each players has unique stash ID (non sharable and non stealable). if false stash is shared to all Occupants if maxoccupans is > 1
	-- 	doors = { -- doors and other function of each rooms
	-- 		[1] = {
	-- 			door = vec3(-936.25,-1311.38,6.20),
	-- 			stash = vec3(-944.08,-1317.83,6.19),
	-- 			wardrobe = vec3(-941.21,-1324.9,6.19),
	-- 			--fridge = vec3(305.26,-206.43,54.22),
	-- 			-- luckyme = vec3(0.0,0.0,0.0) -- extra shit
	-- 		},
	-- 	},
	-- },

	-- [3] = { -- index name of motel
	-- 	businessprice = 1000000,
	-- 	manual = false, -- set the motel to auto accept occupants or false only the owner of motel can accept Occupants
	-- 	Mlo = false, -- if MLO you need to configure each doors coordinates,stash etc. if false resource will use shells
	-- 	shell = 'modern', -- shell type, configure only if using Mlo = true
	-- 	label = 'Motel Modern', -- hotel label
	-- 	rental_period = 'day',-- hour, day, month
	-- 	payment = 'money', -- money, bank
	-- 	rate = 1000, -- cost per period
	-- 	door = `gabz_pinkcage_doors_front`, -- door hash for MLO type
	-- 	motel = 'hotelmodern3', -- hotel index name
	-- 	rentcoord = vec3(515.21173095703,225.36326599121,104.74),
	-- 	coord = vec3(505.55709838867,213.49201965332,102.89), -- center of the motel location
	-- 	radius = 50.0, -- radius of motel location
	-- 	maxoccupants = 5, -- maximum renters per room
	-- 	uniquestash = true, -- if true. each players has unique stash ID (non sharable and non stealable). if false stash is shared to all Occupants if maxoccupans is > 1
	-- 	doors = { -- doors and other function of each rooms
	-- 		[1] = {
	-- 			door = vec3(496.90872192383,237.74664306641,105.28434753418),
	-- 			-- stash = vec3(-944.08,-1317.83,6.19),
	-- 			-- wardrobe = vec3(-941.21,-1324.9,6.19),
	-- 			--fridge = vec3(305.26,-206.43,54.22),
	-- 			-- luckyme = vec3(0.0,0.0,0.0) -- extra shit
	-- 		},
	-- 	},
	-- }
}
config.extrafunction = {
	['bed'] = function(data,identifier)
		TriggerEvent('luckyme')
	end,
	['fridge'] = function(data,identifier)
		TriggerEvent('ox_inventory:openInventory', 'stash', {id = 'fridge_'..data.motel..'_'..identifier..'_'..data.index, name = 'Fridge', slots = 30, weight = 20000, coords = GetEntityCoords(cache.ped)})
	end,
	['exit'] = function(data)
		local coord = LocalPlayer.state.lastloc or vec3(data.coord.x,data.coord.y,data.coord.z)
		DoScreenFadeOut(500)
		while not IsScreenFadedOut() do
			Wait(10)
		end
		SendNUIMessage({
			type = 'door'
		})
		return Teleport(coord.x,coord.y,coord.z,0.0,true)
	end,
}

config.Text = {
	['stash'] = 'Stash',
	['fridge'] = 'My Fridge',
	['wardrobe'] = 'Wardrobe',
	['bed'] = 'Sleep',
	['door'] = 'Door',
	['exit'] = 'Exit',
}

config.icons = {
	['door'] = 'fas fa-door-open',
	['stash'] = 'fas fa-box',
	['wardrobe'] = 'fas fa-tshirt',
	['fridge'] = 'fas fa-ice-cream',
	['bed'] = 'fas fa-bed',
	['exit'] = 'fas fa-door-open',
}

config.stashblacklist = {
	['stash'] = { -- type of inventory
		blacklist = { -- list of blacklists items
			water = true,
		},
	},
	['fridge'] = { -- type of inventory
		blacklist = { -- list of blacklists items
			WEAPON_PISTOL = true,
		},
	},
}

PlayerData,ESX,QBCORE,zones,shelzones,blips = {},nil,nil,{},{},{}

function import(file)
	local name = ('%s.lua'):format(file)
	local content = LoadResourceFile(GetCurrentResourceName(),name)
	local f, err = load(content)
	return f()
end

if GetResourceState('es_extended') == 'started' then
	ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
	QBCORE = exports['qb-core']:GetCoreObject()
end