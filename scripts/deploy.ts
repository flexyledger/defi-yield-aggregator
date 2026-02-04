import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);
    console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

    // Configuration - Update these for your deployment
    const UNDERLYING_ASSET = process.env.UNDERLYING_ASSET || "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"; // USDC on mainnet
    const AAVE_POOL = process.env.AAVE_POOL || "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2"; // Aave V3 Pool mainnet
    const COMPOUND_COMET = process.env.COMPOUND_COMET || "0xc3d688B66703497DAA19211EEdff47f25384cdc3"; // cUSDCv3 mainnet
    const COMPOUND_REWARDS = process.env.COMPOUND_REWARDS || "0x1B0e765F6224C21223AeA2af16c1C46E38885a40";
    const COMP_TOKEN = process.env.COMP_TOKEN || "0xc00e94Cb662C3520282E6f5717214004A7f26888";

    // Deploy Vault
    console.log("\n1. Deploying Vault...");
    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(
        UNDERLYING_ASSET,
        "DeFi Yield Aggregator Share",
        "dyaUSDC"
    );
    await vault.waitForDeployment();
    const vaultAddress = await vault.getAddress();
    console.log("   Vault deployed to:", vaultAddress);

    // Deploy StrategyManager
    console.log("\n2. Deploying StrategyManager...");
    const StrategyManager = await ethers.getContractFactory("StrategyManager");
    const strategyManager = await StrategyManager.deploy(vaultAddress, UNDERLYING_ASSET);
    await strategyManager.waitForDeployment();
    const strategyManagerAddress = await strategyManager.getAddress();
    console.log("   StrategyManager deployed to:", strategyManagerAddress);

    // Set StrategyManager in Vault
    console.log("\n3. Configuring Vault...");
    await vault.setStrategyManager(strategyManagerAddress);
    console.log("   StrategyManager set in Vault");

    // Deploy Aave Strategy
    console.log("\n4. Deploying AaveStrategy...");
    const AaveStrategy = await ethers.getContractFactory("AaveStrategy");
    const aaveStrategy = await AaveStrategy.deploy(vaultAddress, UNDERLYING_ASSET, AAVE_POOL);
    await aaveStrategy.waitForDeployment();
    const aaveStrategyAddress = await aaveStrategy.getAddress();
    console.log("   AaveStrategy deployed to:", aaveStrategyAddress);

    // Deploy Compound Strategy
    console.log("\n5. Deploying CompoundStrategy...");
    const CompoundStrategy = await ethers.getContractFactory("CompoundStrategy");
    const compoundStrategy = await CompoundStrategy.deploy(
        vaultAddress,
        COMPOUND_COMET,
        COMPOUND_REWARDS,
        COMP_TOKEN
    );
    await compoundStrategy.waitForDeployment();
    const compoundStrategyAddress = await compoundStrategy.getAddress();
    console.log("   CompoundStrategy deployed to:", compoundStrategyAddress);

    // Add strategies to StrategyManager (50% each)
    console.log("\n6. Adding strategies to StrategyManager...");
    await strategyManager.addStrategy(aaveStrategyAddress, 5000); // 50%
    console.log("   AaveStrategy added with 50% allocation");
    await strategyManager.addStrategy(compoundStrategyAddress, 5000); // 50%
    console.log("   CompoundStrategy added with 50% allocation");

    // Summary
    console.log("\n" + "=".repeat(60));
    console.log("DEPLOYMENT SUMMARY");
    console.log("=".repeat(60));
    console.log(`Vault:            ${vaultAddress}`);
    console.log(`StrategyManager:  ${strategyManagerAddress}`);
    console.log(`AaveStrategy:     ${aaveStrategyAddress}`);
    console.log(`CompoundStrategy: ${compoundStrategyAddress}`);
    console.log("=".repeat(60));

    // Save deployment addresses
    const deploymentInfo = {
        network: (await ethers.provider.getNetwork()).name,
        chainId: (await ethers.provider.getNetwork()).chainId.toString(),
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
        contracts: {
            Vault: vaultAddress,
            StrategyManager: strategyManagerAddress,
            AaveStrategy: aaveStrategyAddress,
            CompoundStrategy: compoundStrategyAddress,
        },
        configuration: {
            underlyingAsset: UNDERLYING_ASSET,
            aavePool: AAVE_POOL,
            compoundComet: COMPOUND_COMET,
        },
    };

    console.log("\nDeployment info:", JSON.stringify(deploymentInfo, null, 2));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
