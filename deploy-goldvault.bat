@echo off
echo ========================================
echo  Deploy GoldVault
echo ========================================
echo.

REM Load environment variables
if exist .env (
    for /f "delims=" %%x in (.env) do (set "%%x")
) else (
    echo ERROR: .env file not found
    exit /b 1
)

echo Deploying GoldVault to Mantle Sepolia...
echo.
forge script script/DeployGoldVault.s.sol:DeployGoldVault ^
    --rpc-url %MANTLE_SEPOLIA_RPC_URL% ^
    --broadcast ^
    --verify ^
    -vvvv

if errorlevel 1 (
    echo.
    echo ERROR: Deployment failed!
    exit /b 1
)

echo.
echo ========================================
echo  GoldVault Deployed Successfully!
echo ========================================
echo.
echo Copy the address above and update:
echo - script/SetupVaultRouter.s.sol (GOLD_VAULT)
echo - script/VerifyVaultRouter.s.sol (GOLD_VAULT)
echo - deployments/auroom-mantle-sepolia.json
echo.
pause
