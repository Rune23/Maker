Make sure your dapp is ready for eDollar! Dev support is available.

---

What?
eDollar is a stablecoin designed to be lightweight and easy to integrate into both dapps and traditional applications. Provable purchasing power, liquidity + on/off ramps, and ease of use are the top priorities in our design. You can learn more and keep up-to-date at MakerDAO.com

Why?
The most obvious benefit of eDollar integartion is the ability to have dollar denominated balances and prices.
You can also monetize your contract system's eDollar float by collecting interest on user deposits. Better yet, pass the interest along to your users if you need a competitive edge.


How?

eDollar is a service of Maker DAO. Maker is defined by a root contract which has a registry of various interfaces.
The eDollar interface implements MakerAssetInterface as defined here TODO

The actual contract you interact with will change until it is locked in at an unknown time in the future. It is just a "frontend" for a more complex permissioned contract system managed by Maker.
This means it is important that you do not hard-code the eUSD interface address, but instead always get the currrent implementation from the root contract like so:

    var maker = 0xMAKER_ROOT_ADDRESS;
    var eUSD = MakerAssetInterface(maker.call("eUSD"))   // .call on raw address will query the services registry
    eUSD.transfer(to_recipient, 1000);

    
    contract MakerAssetAware {
        address                                     maker;
        mapping( address => uint )                  _unprocessed_balances;

        function MakerAssetAware() {
            maker = 0xINITIALIZED_MAKER_ADDRESS;
        }
        function process_deposit( address to, uint amount ) {   // to be defined as part of the Standard Asset hierarchy
            if( msg.sender != maker.call("asset/eUSD") ) {
                _unprocessed_balances[to] += amount;
            }         
        }
    }

/// P.S.  MakerAssetHolder compatability is a requirement to use your asset as collateral
contract MyContract is MakerAssetHolder {
    function process_deposit(bytes32 asset, address from, uint amount) returns (bool accept) {
    }
        _asset_debts[asset][from] = amount;
        return true;
    }
    function withdraw(address to, uint amount) retuns (bool succeess) {
        _asset_controllers.transfer(addres(this), uint amount);
    }
    /* 
    function internal
}


Pro tip: disregard the additional entry points added to your program because of extending our unpublished code. They are part of a Secure System.
