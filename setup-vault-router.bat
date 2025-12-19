@echo off
echo ========================================
echo  AuRoom Protocol - Setup Vault Router
echo ========================================
echo.

REM Load environment variables
if exist .env (
    for /f "delims=" %%x in (.env) do (set "%%x")
) else (
    echo ERROR: .env file not found
    exit /b 1
)

echo Make sure you have updated the addresses in:
echo - script/SetupVaultRouter.s.sol
echo.
set /p confirm="Continue? (y/n): "
if /i not "%confirm%"=="y" (
    echo Setup cancelled.
    exit /b 0
)

echo.
echo [1/1] Registering GoldVault and SwapRouter in IdentityRegistry...
echo.
forge script script/SetupVaultRouter.s.sol:SetupVaultRouter ^
    --rpc-url %MANTLE_SEPOLIA_RPC_URL% ^
    --broadcast ^
    -vvvv

if errorlevel 1 (
    echo.
    echo ERROR: Setup failed!
    exit /b 1
)

echo.
echo ========================================
echo  Setup Complete!
echo ========================================
echo.
echo Your contracts are now ready to use:
echo - Users can deposit XAUT into GoldVault
echo - Users can swap IDRX ^<-^> XAUT via SwapRouter
echo.
pause
