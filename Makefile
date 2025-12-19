.PHONY: help install build test clean deploy deploy-dry verify setup

# Load environment variables
include .env
export

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

help: ## Show this help message
	@echo '$(GREEN)AuRoom Protocol - Makefile Commands$(NC)'
	@echo ''
	@echo 'Usage:'
	@echo '  make $(YELLOW)<target>$(NC)'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	@echo "$(GREEN)Installing Foundry dependencies...$(NC)"
	forge install
	@echo "$(GREEN)Done!$(NC)"

build: ## Build all contracts
	@echo "$(GREEN)Building contracts...$(NC)"
	forge build
	@echo "$(GREEN)Build complete!$(NC)"

test: ## Run all tests
	@echo "$(GREEN)Running tests...$(NC)"
	forge test -vvv
	@echo "$(GREEN)Tests complete!$(NC)"

test-gas: ## Run tests with gas reporting
	@echo "$(GREEN)Running tests with gas reporting...$(NC)"
	forge test --gas-report
	@echo "$(GREEN)Tests complete!$(NC)"

clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	forge clean
	rm -rf cache out broadcast
	@echo "$(GREEN)Clean complete!$(NC)"

deploy-dry: ## Dry run deployment (simulation only)
	@echo "$(GREEN)Running deployment simulation...$(NC)"
	forge script script/Deploy.s.sol \
		--rpc-url $(MANTLE_TESTNET_RPC) \
		-vvvv

deploy: ## Deploy to Mantle Testnet
	@echo "$(GREEN)Deploying to Mantle Testnet...$(NC)"
	@echo "$(YELLOW)This will broadcast real transactions!$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		forge script script/Deploy.s.sol \
			--rpc-url $(MANTLE_TESTNET_RPC) \
			--broadcast \
			--verify \
			-vvvv; \
		echo "$(GREEN)Deployment complete!$(NC)"; \
		echo "$(GREEN)Check deployments/mantle-testnet.json for addresses$(NC)"; \
	else \
		echo "$(RED)Deployment cancelled$(NC)"; \
	fi

deploy-force: ## Deploy without confirmation (use with caution)
	@echo "$(GREEN)Deploying to Mantle Testnet...$(NC)"
	forge script script/Deploy.s.sol \
		--rpc-url $(MANTLE_TESTNET_RPC) \
		--broadcast \
		--verify \
		-vvvv
	@echo "$(GREEN)Deployment complete!$(NC)"

deploy-local: ## Deploy to local network
	@echo "$(GREEN)Deploying to local network...$(NC)"
	forge script script/Deploy.s.sol \
		--rpc-url http://localhost:8545 \
		--broadcast \
		-vvvv

verify: ## Verify contracts on block explorer
	@echo "$(GREEN)Verifying contracts...$(NC)"
	forge script script/Verify.s.sol \
		--rpc-url $(MANTLE_TESTNET_RPC) \
		--ffi
	@echo "$(GREEN)Verification complete!$(NC)"

setup: ## Run post-deployment setup
	@echo "$(GREEN)Running post-deployment setup...$(NC)"
	forge script script/PostDeploymentSetup.s.sol \
		--rpc-url $(MANTLE_TESTNET_RPC) \
		--broadcast \
		-vvvv
	@echo "$(GREEN)Setup complete!$(NC)"

status: ## Check deployment status
	@echo "$(GREEN)Checking deployment status...$(NC)"
	@if [ -f "deployments/$(NETWORK).json" ]; then \
		echo "$(GREEN)Deployment found for network: $(NETWORK)$(NC)"; \
		cat deployments/$(NETWORK).json | jq .; \
	else \
		echo "$(RED)No deployment found for network: $(NETWORK)$(NC)"; \
	fi

balance: ## Check deployer balance
	@echo "$(GREEN)Checking deployer balance...$(NC)"
	@DEPLOYER=$$(cast wallet address $(PRIVATE_KEY)); \
	echo "Deployer address: $$DEPLOYER"; \
	cast balance $$DEPLOYER --rpc-url $(MANTLE_TESTNET_RPC)

gas-price: ## Check current gas price
	@echo "$(GREEN)Current gas price:$(NC)"
	@cast gas-price --rpc-url $(MANTLE_TESTNET_RPC)

format: ## Format Solidity code
	@echo "$(GREEN)Formatting code...$(NC)"
	forge fmt
	@echo "$(GREEN)Format complete!$(NC)"

lint: ## Lint Solidity code
	@echo "$(GREEN)Linting code...$(NC)"
	forge fmt --check
	@echo "$(GREEN)Lint complete!$(NC)"

coverage: ## Generate test coverage report
	@echo "$(GREEN)Generating coverage report...$(NC)"
	forge coverage
	@echo "$(GREEN)Coverage report generated!$(NC)"

snapshot: ## Create gas snapshot
	@echo "$(GREEN)Creating gas snapshot...$(NC)"
	forge snapshot
	@echo "$(GREEN)Snapshot created at .gas-snapshot$(NC)"

anvil: ## Start local Anvil node
	@echo "$(GREEN)Starting Anvil local node...$(NC)"
	anvil --chain-id 31337

update: ## Update dependencies
	@echo "$(GREEN)Updating dependencies...$(NC)"
	forge update
	@echo "$(GREEN)Dependencies updated!$(NC)"

# Advanced deployment options
deploy-with-gas: ## Deploy with custom gas settings
	@echo "$(GREEN)Deploying with custom gas settings...$(NC)"
	forge script script/Deploy.s.sol \
		--rpc-url $(MANTLE_TESTNET_RPC) \
		--broadcast \
		--verify \
		--gas-estimate-multiplier 120 \
		-vvvv

deploy-resume: ## Resume failed deployment
	@echo "$(GREEN)Resuming deployment...$(NC)"
	forge script script/Deploy.s.sol \
		--rpc-url $(MANTLE_TESTNET_RPC) \
		--broadcast \
		--resume \
		-vvvv

# Uniswap V2 Deployment
deploy-uniswap: ## Deploy Uniswap V2 infrastructure (WMNT, Factory, Router)
	@echo "$(GREEN)Deploying Uniswap V2 to Mantle Sepolia...$(NC)"
	@echo "$(YELLOW)This will deploy: WMNT, Factory, Router$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 \
			--rpc-url https://rpc.sepolia.mantle.xyz \
			--private-key $(PRIVATE_KEY) \
			--broadcast \
			--verify \
			--etherscan-api-key $(MANTLESCAN_API_KEY) \
			-vvvv; \
		echo "$(GREEN)Uniswap V2 deployed!$(NC)"; \
		echo "$(YELLOW)Update .env with WMNT, UNISWAP_FACTORY, UNISWAP_ROUTER$(NC)"; \
	else \
		echo "$(RED)Deployment cancelled$(NC)"; \
	fi

deploy-uniswap-dry: ## Simulate Uniswap V2 deployment (no broadcast)
	@echo "$(GREEN)Simulating Uniswap V2 deployment...$(NC)"
	forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 \
		--rpc-url https://rpc.sepolia.mantle.xyz \
		-vvvv

setup-dex-pairs: ## Create trading pairs and add liquidity
	@echo "$(GREEN)Setting up DEX pairs...$(NC)"
	@if [ -z "$(UNISWAP_FACTORY)" ] || [ -z "$(UNISWAP_ROUTER)" ]; then \
		echo "$(RED)Error: UNISWAP_FACTORY or UNISWAP_ROUTER not set in .env$(NC)"; \
		echo "$(YELLOW)Please deploy Uniswap V2 first: make deploy-uniswap$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)This will create IDRX/USDC and XAUT/USDC pairs$(NC)"
	@echo "$(YELLOW)Initial liquidity: 1M IDRX, 335K USDC, 100 XAUT$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		forge script script/SetupDEXPairs.s.sol:SetupDEXPairs \
			--rpc-url https://rpc.sepolia.mantle.xyz \
			--private-key $(PRIVATE_KEY) \
			--broadcast \
			-vvvv; \
		echo "$(GREEN)DEX pairs setup complete!$(NC)"; \
	else \
		echo "$(RED)Setup cancelled$(NC)"; \
	fi

check-dex: ## Check DEX deployment status
	@echo "$(GREEN)Checking DEX deployment...$(NC)"
	@if [ -z "$(UNISWAP_FACTORY)" ]; then \
		echo "$(RED)UNISWAP_FACTORY not set$(NC)"; \
	else \
		echo "Factory: $(UNISWAP_FACTORY)"; \
		PAIRS=$$(cast call $(UNISWAP_FACTORY) "allPairsLength()(uint256)" --rpc-url https://rpc.sepolia.mantle.xyz); \
		echo "Total pairs: $$PAIRS"; \
	fi
	@if [ -z "$(UNISWAP_ROUTER)" ]; then \
		echo "$(RED)UNISWAP_ROUTER not set$(NC)"; \
	else \
		echo "Router: $(UNISWAP_ROUTER)"; \
	fi

check-pairs: ## Check trading pair addresses
	@echo "$(GREEN)Checking pair addresses...$(NC)"
	@if [ -z "$(UNISWAP_FACTORY)" ]; then \
		echo "$(RED)Error: UNISWAP_FACTORY not set in .env$(NC)"; \
		exit 1; \
	fi
	@echo "IDRX/USDC Pair:"; \
	PAIR=$$(cast call $(UNISWAP_FACTORY) "getPair(address,address)(address)" 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 0x96ABff3a2668B811371d7d763f06B3832CEdf38d --rpc-url https://rpc.sepolia.mantle.xyz); \
	echo "  Address: $$PAIR"
	@echo "XAUT/USDC Pair:"; \
	PAIR=$$(cast call $(UNISWAP_FACTORY) "getPair(address,address)(address)" 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78 0x96ABff3a2668B811371d7d763f06B3832CEdf38d --rpc-url https://rpc.sepolia.mantle.xyz); \
	echo "  Address: $$PAIR"

.DEFAULT_GOAL := help
