#!/usr/bin/python3

from brownie import CTokenMinePool, MonkeyContract, interface , accounts

def main():
    dai = interface.daiInterface('0x6b175474e89094c44da98b954eedeac495271d0f')#DAI mainnet address 
    # dai.mint(accounts[0],5000e18,{'from':'0x9759A6Ac90977b93B58547b4A71c78317f391A28'})
    # dai.mint(accounts[1],5000e18,{'from':'0x9759A6Ac90977b93B58547b4A71c78317f391A28'})
    bal = dai.balanceOf(accounts[0])
    bal1 = dai.balanceOf(accounts[1])
    print(f'\nUser1 has Dai token balance is : {bal/1e18}\n')
    print(f'\nUser2 has Dai token balance is : {bal1/1e18}\n')
    comptrollerAddress = '0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b'#ETH Mainnet address
    # priceFeedAddress = '0x6d2299c48a8dd07a872fdd0f8233924872ad1071'#ETH Mainnet address
    cTokenAddress = '0x5d3a536e4d6dbd6114cc1ead35777bab948e3643'#ETH Mainnet address

    # comptrollerAddress = '0xF28011a55CDE629E20D15BbCF21899c48C679D24'
    # priceFeedAddress = '0xd9554D3f5a68D43c4e4A563ED5C016405ad5b5aC'
    # cTokenAddress = '0x5d036Cd12904958876A1d94FeE50A34202558A3D'
    monkey = MonkeyContract.deploy({'from':accounts[0]})
    print(f'\nMonkeyNFT deployed at :{monkey}\n')    
    tr = CTokenMinePool.deploy(dai.address, comptrollerAddress, cTokenAddress, monkey, {'from':accounts[0]})  
    print(f'\nCTokrnMinePool contract deployed at : {tr.address}\n')
    monkey.transferOwnership(tr,{'from':accounts[0]})


    # Deposit underlying token 5e19
    supplyUnderlying = 5e19
    dai.approve(tr.address, supplyUnderlying,{'from':accounts[0]})
    dai.approve(tr.address, supplyUnderlying,{'from':accounts[1]})
    allo = dai.allowance(accounts[0],tr,{'from':accounts[0]})
    allo1 = dai.allowance(accounts[1],tr,{'from':accounts[1]})
    print(f'\nUser1 would like to supply {allo/1e18} dai to TR contract.\n')
    print(f'\nUser2 would like to supply {allo1/1e18} dai to TR contract.\n')
    result = tr.deposit(allo,{'from':accounts[0]})

    tr.deposit(allo1,{'from':accounts[1]})
    trBal1 = tr.balanceOf(accounts[0])
    trBal2 = tr.balanceOf(accounts[1])
    log = result.logs.args
    print(f'\nUser1 has zToken balance is : {trBal1/1e8}\n')
    print(f'\nUser2 has zToken balance is : {trBal2/1e8}\n')
    print(f'{log}\n')

    # bal01 = dai.balanceOf(accounts[0])
    # print(f'\nUser1 has Dai token balance is : {bal01/1e18}\n')
    # delo = interface.CErc20Delegator(cTokenAddress)
    # deBal = delo.balanceOf(tr)
    # print(f'\nCTokrnMinePool has cToken balance is :{deBal/1e8}\n')
    # baltr0 = dai.balanceOf(tr)
    # print(f'\nCTokrnMinePool has DAI balance is :{baltr0/1e18}\n')

    # # Borrow underlying token liquidity
    # liquidity = supplyUnderlying*0.79
    # print(f'\nUser1 would like to borrow {liquidity/1e18} DAI to mint NFT!\n')
    # tr.enterMarket({'from':accounts[0]})
    # tr.borrowUnderlying(liquidity,{'from':accounts[0]})      
    # baltr = dai.balanceOf(tr)    
    # print(f'\nCTokenMinePool has DAI balance is :{baltr/1e18}\n')
    # detail1 = monkey.getMonkeyDetails(1)    
    # mo =  monkey.balanceOf(accounts[0])
    # print(f'\nCTokenMinePool created {mo} monkey with character {detail1}\n')   

    # # Borrow underlying mint monkeyNFT again!
    # tr.borrowUnderlying(liquidity,{'from':accounts[1]}) 
    # detail2 = monkey.getMonkeyDetails(2)
    # mo =  monkey.totalSupply()
    # print(f'\nCTokenMinePool created {mo} monkey with character {detail2}\n')
    
    # #RepayBorrow
    # print(f'\nUser1 would like to repayBorrow {liquidity/1e18} DAI to cToken contract.\n')
    # tr.repayBorrow(liquidity,{'from':accounts[0]})
    # baltr1 = dai.balanceOf(tr) 
    # print(f'\nCTokrnMinePool has DAI balance is :{baltr1/1e18}\n')
    # detail1 = monkey.getMonkeyDetails(1)
    # print(f'\nMonkey1 with character {detail1}\n')


    # # Withdraw underlying
    # trBal2 = trBal1*0.999999
    # print(f'\nWould like to withdraw fund is :{trBal2/1e8}\n')
    # tr.withdraw(trBal2,{'from':accounts[0]})
    # trBal3 = tr.balanceOf(accounts[0])
    # print(f'\nTR token balance is : {trBal3/1e8}\n')
    # bal2 = dai.balanceOf(accounts[0])
    # print(f'\nDai token balance is : {bal2/1e18}\n')
    # delo = interface.CErc20Delegator(cTokenAddress)
    # deBal = delo.balanceOf(tr)
    # print(f'\nCTokrnMinePool has cToken balance is :{deBal/1e8}\n')
    # balx = bal2 - bal
    # print(f'\nThe change of DAI is :{balx/1e18}\n')

