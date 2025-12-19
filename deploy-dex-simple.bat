@echo off
REM Simple Uniswap V2 Deployment Script for Windows
REM Run this in Command Prompt (not PowerShell)

echo ================================================
echo Uniswap V2 Deployment - Mantle Sepolia
echo ================================================
echo.

REM Check if .env exists
if not exist .env (
    echo ERROR: .env file not found
    echo Please create .env file with PRIVATE_KEY
    pause
    exit /b 1
)

REM Load .env (basic version)
for /f "tokens=*" %%a in (.env) do set %%a

if "%PRIVATE_KEY%"=="" (
    echo ERROR: PRIVATE_KEY not set in .env
    pause
    exit /b 1
)

echo Step 1: Deploying Mock Uniswap V2...
echo This will deploy WMNT, MockFactory, and MockRouter
echo.

forge script script/DeployMockUniswapV2.s.sol:DeployMockUniswapV2 --rpc-url https://rpc.sepolia.mantle.xyz --private-key %PRIVATE_KEY% --broadcast -vvvv

echo.
echo ================================================
echo Deployment Complete!
echo ================================================
echo.
echo IMPORTANT:
echo 1. Copy the deployed addresses from output above
echo 2. Update your .env file with:
echo    WMNT=0x...
echo    UNISWAP_FACTORY=0x...
echo    UNISWAP_ROUTER=0x...
echo 3. Save the INIT_CODE_HASH
echo.
echo Next step: Run setup-dex-pairs.bat
echo.
pause
