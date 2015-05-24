Edollar Modules

Core

coin contract

	send and deposit to contract
	deposit several types of collateral
	issue
	full and partial cover
	hard margin call
	keeper functions:
		set feed price
		set risk parameters such as collateral requirement, forced cover rate, hard margin call rate
		set keeper address

Maker contract
	
	send and deposit MakerCoin (MKR). This will clear any voting
	get feed price and set feed on coin contract
	for delegate contracts:
		passthrough functions for coin contracts keeper functions
		change feed source
	start voting event for a new delegate contract for a given keeper function
	start voting event to change the priming delay and voting duration
	start voting event to change the minimum votes parameter
	cast for or against vote for a given voting event
	finalise voting event after voting duration: yes (if majority is yes and above minimum votes) or no (if majority is no, or yes votes are below minimum votes)
	execute voting event finalisation after priming delay

feed source contract

	set feed by centralized feed provider
	(get feed from augur oracle contract)
	create and get feedprice based on centralized and decentralized price feeds

delegate contract

	(unique for each keeper function - vital ones need priming delay - can be multi-user or multisig for vital functions)

coin frontend

	show balance, send/receive with nameReg, send/receive with bitcoin through shapeshift

issue frontend
	
	deposit and withdraw collateral
	issue and cover with specific collateral types

remarketing bot

	get price from hedge market
	put orders on mirror market based no hedge price
	adjust mirror based on hedge price
	hedge whenever mirror order is matched


Extra

coin shuffle contract

	add coins to contract
	add receiver addresses (by shuffler)
	authorize coin send

coin shuffle server

	analyze signed messages through whisper and add their receiver address