@echo off
echo ========================================
echo  AuRoom Protocol - Verify Vault Router
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
echo - script/VerifyVaultRouter.s.sol
echo.

echo Running verification...
echo.
forge script script/VerifyVaultRouter.s.sol:VerifyVaultRouter ^
    --rpc-url %MANTLE_SEPOLIA_RPC_URL% ^
    -vvvv

echo.
pause
