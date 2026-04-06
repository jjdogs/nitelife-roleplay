return {
	OilRigsStorage = 5000, -- By default this is 5000 gallons of crudeoil change it if you wish
	OilRigUpgrades = {
		oilfilter = {
			upgMtp = 0.30, -- 30%
			upgType = 'filter',
		},
		skewgear = {
			upgMtp = 0.15, -- 15%
			upgType = 'extraction',
		},
		reliefstring = {
			upgMtp = 0.15, -- 15%
			upgType = 'extraction',
		},
		timingchain = {
			upgMtp = 0.15, -- 15%
			upgType = 'extraction',
		},
		driveshaft = {
			upgMtp = 0.15, -- 15%
			upgType = 'extraction',
		},
	},

	MaxOutPut = 9, -- max 9 gallons a every 30 seconds on 100% speed


	-- Speed to heat levels, once it hits max heat it will slow down production by 30-50%
	SpeedHeatValues = {
		{
			Speeds = {min = 0, max = 10},
			Heat = {min = 0, max = 25},
			HeatIncrease = {min = 0, max = 1},
		},
		{
			Speeds = {min = 11, max = 20},
			Heat = {min = 5, max = 50},
			HeatIncrease = {min = 0, max = 1},
		},
		{
			Speeds = {min = 21, max = 30},
			Heat = {min = 15, max = 75},
			HeatIncrease = {min = 0, max = 2},
		},
		{
			Speeds = {min = 31, max = 40},
			Heat = {min = 15, max = 100},
			HeatIncrease = {min = 0, max = 2},
		},
		{
			Speeds = {min = 41, max = 50},
			Heat = {min = 25, max = 125},
			HeatIncrease = {min = 0, max = 3},
		},
		{
			Speeds = {min = 51, max = 60},
			Heat = {min = 30, max = 150},
			HeatIncrease = {min = 0, max = 3},
		},
		{
			Speeds = {min = 61, max = 70},
			Heat = {min = 35, max = 175},
			HeatIncrease = {min = 0, max = 4},
		},
		{
			Speeds = {min = 71, max = 80},
			Heat = {min = 40, max = 200},
			HeatIncrease = {min = 0, max = 4},
		},
		{
			Speeds = {min = 81, max = 90},
			Heat = {min = 45, max = 225},
			HeatIncrease = {min = 1, max = 5},
		},
		{
			Speeds = {min = 91, max = 100},
			Heat = {min = 65, max = 250},
			HeatIncrease = {min = 1, max = 5},
		},
	}
}