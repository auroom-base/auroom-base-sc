@echo off
REM Verify addresses in IdentityRegistry for XAUT transfers

echo ================================================
echo Verifying Addresses in IdentityRegistry
echo ================================================
echo.

REM Load .env
for /f "tokens=*" %%a in (.env) do set %%a

if "%PRIVATE_KEY%"=="" (
    echo ERROR: PRIVATE_KEY not set in .env
    pause
    exit /b 1
)

set IDENTITY_REGISTRY=0x620870d419F6aFca8AFed5B516619aa50900cadc
set DEPLOYER=0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1
set PAIR_XAUT_USDC=0xc2da5178F53f45f604A275a3934979944eB15602
set RPC=https://rpc.sepolia.mantle.xyz

echo IdentityRegistry: %IDENTITY_REGISTRY%
echo.

echo 1. Checking if deployer is admin...
cast call %IDENTITY_REGISTRY% "isAdmin(address)(bool)" %DEPLOYER% --rpc-url %RPC%

echo.
echo 2. Adding deployer as admin (if owner)...
cast send %IDENTITY_REGISTRY% "addAdmin(address)" %DEPLOYER% --private-key %PRIVATE_KEY% --rpc-url %RPC% 2>nul || echo Already admin or not owner

echo.
echo 3. Batch registering addresses...
cast send %IDENTITY_REGISTRY% "batchRegisterIdentity(address[])" "[%DEPLOYER%,%PAIR_XAUT_USDC%]" --private-key %PRIVATE_KEY% --rpc-url %RPC%

echo.
echo ================================================
echo Verification Complete!
echo ================================================
echo.
echo Verified addresses:
echo   - Deployer: %DEPLOYER%
echo   - XAUT/USDC Pair: %PAIR_XAUT_USDC%
echo.
echo Next step: Run setup-dex-pairs.bat again to add XAUT liquidity
echo.
pause
