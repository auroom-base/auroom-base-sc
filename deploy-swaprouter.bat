@echo off
echo ========================================
echo  Deploy SwapRouter
echo ========================================
echo.

REM Load environment variables
if exist .env (
    for /f "delims=" %%x in (.env) do (set "%%x")
) else (
    echo ERROR: .env file not found
    exit /b 1
)

echo Deploying SwapRouter to Mantle Sepolia...
echo.
forge script script/DeploySwapRouter.s.sol:DeploySwapRouter ^
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
echo  SwapRouter Deployed Successfully!
echo ========================================
echo.
echo Copy the address above and update:
echo - script/SetupVaultRouter.s.sol (SWAP_ROUTER)
echo - script/VerifyVaultRouter.s.sol (SWAP_ROUTER)
echo - deployments/auroom-mantle-sepolia.json
echo.
pause
