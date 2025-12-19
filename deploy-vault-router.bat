@echo off
echo ========================================
echo  AuRoom Protocol - Deploy Vault Router
echo ========================================
echo.

REM Load environment variables
if exist .env (
    for /f "delims=" %%x in (.env) do (set "%%x")
) else (
    echo ERROR: .env file not found
    exit /b 1
)

echo [1/3] Deploying GoldVault and SwapRouter...
echo.
forge script script/DeployVaultRouter.s.sol:DeployVaultRouter ^
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
echo  Deployment Successful!
echo ========================================
echo.
echo Please update the addresses in:
echo - script/SetupVaultRouter.s.sol
echo - deployments/auroom-mantle-sepolia.json
echo.
echo Then run: setup-vault-router.bat
echo.
pause
