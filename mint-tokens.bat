@echo off
REM Mint tokens for DEX liquidity

echo ================================================
echo Minting Tokens for DEX Liquidity
echo ================================================
echo.

REM Load .env
for /f "tokens=*" %%a in (.env) do set %%a

if "%PRIVATE_KEY%"=="" (
    echo ERROR: PRIVATE_KEY not set in .env
    pause
    exit /b 1
)

set DEPLOYER=0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1
set RPC=https://rpc.sepolia.mantle.xyz

set IDRX=0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05
set USDC=0x96ABff3a2668B811371d7d763f06B3832CEdf38d
set XAUT=0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78

echo Minting tokens to: %DEPLOYER%
echo.

echo 1. Minting 1,000,000 IDRX...
cast send %IDRX% "mint(address,uint256)" %DEPLOYER% 100000000 --private-key %PRIVATE_KEY% --rpc-url %RPC%

echo.
echo 2. Minting 335,000 USDC...
cast send %USDC% "mint(address,uint256)" %DEPLOYER% 335000000000 --private-key %PRIVATE_KEY% --rpc-url %RPC%

echo.
echo 3. Minting 100 XAUT...
cast send %XAUT% "mint(address,uint256)" %DEPLOYER% 100000000 --private-key %PRIVATE_KEY% --rpc-url %RPC%

echo.
echo ================================================
echo Minting Complete!
echo ================================================
echo.
echo Token Balances:
echo   IDRX: 1,000,000 (100000000)
echo   USDC: 335,000 (335000000000)
echo   XAUT: 100 (100000000)
echo.
echo Next step: Run setup-dex-pairs.bat
echo.
pause
