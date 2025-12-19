@echo off
REM Setup DEX Pairs Script for Windows

echo ================================================
echo DEX Pairs Setup - Mantle Sepolia
echo ================================================
echo.

REM Load .env
for /f "tokens=*" %%a in (.env) do set %%a

if "%PRIVATE_KEY%"=="" (
    echo ERROR: PRIVATE_KEY not set in .env
    pause
    exit /b 1
)

if "%UNISWAP_FACTORY%"=="" (
    echo ERROR: UNISWAP_FACTORY not set in .env
    echo Please run deploy-dex-simple.bat first
    pause
    exit /b 1
)

if "%UNISWAP_ROUTER%"=="" (
    echo ERROR: UNISWAP_ROUTER not set in .env
    echo Please run deploy-dex-simple.bat first
    pause
    exit /b 1
)

echo Factory: %UNISWAP_FACTORY%
echo Router: %UNISWAP_ROUTER%
echo.
echo This will:
echo - Create IDRX/USDC pair
echo - Create XAUT/USDC pair
echo - Add initial liquidity
echo.
pause

forge script script/SetupDEXPairs.s.sol:SetupDEXPairs --rpc-url https://rpc.sepolia.mantle.xyz --private-key %PRIVATE_KEY% --broadcast -vvvv

echo.
echo ================================================
echo DEX Setup Complete!
echo ================================================
echo.
pause
