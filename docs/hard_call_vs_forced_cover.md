hardCall

Anyone can perform a hard call on any position that has a collateral/debt ratio below 140% (hardCallRate). If the caller has EUSD equal to, or higher, than the debt of the called account the EUSD is burned and the debt is set to zero, while the caller receives the entire locked collateral for the position of the called account.


forcedCover

only Maker can call the forcedCover on a position, and only if the positions collatera/debt ratio is below 270% (forcedCoverRate)

If Maker has enough EUSD to cover the position of the called account, then the EUSD is burned and the debt of the called account is reduced to 0, while Maker receives collateral at the rate of the pricefeed times the modifier parameter (can set the collateral up to 5% lower if the price feed is off)
