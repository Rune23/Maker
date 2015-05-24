You can write your dapps to be edollar-ready right away, with a mock implementation (no permission system) available right away. During Frontier there will be test tokens with fake collateral and fake data feeds. The real thing will launch on Homestead, and will be built with the ability to smoothly transition balances onto Serentiy.


The Maker system is defined by the root contract MAKER, deployed at  0x0000000

    var eusd_controller_address = ContractSystem(MAKER).GetContract("eUSD_controller");
    var eUSD = AssetController( eusd_controller_address );

    eUSD.transfer(eth
    eUSD.transfer(eth.coinbase, receiver, false);


    function transfer( address to );
    function transfer( address to, bool pay_miner );
    function transfer( address to, uint amount );
    function transfer( address to, uint amount, bool pay_miner );
    function transfer( address from, address to, uint amount );
    function transfer( address from, address to, uint amount, bool pay_miner );

    function deposit_to_contract( address to, uint amount, bool pay_miner );






