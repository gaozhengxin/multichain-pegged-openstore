/**
 * Deploy destination chain contracts
 */
 const MC_Openstore = artifacts.require("MC_AssetContractShared");
 const MC_Openstore_Gateway = artifacts.require("ERC1155Gateway_MintBurn");
 const anycall = "0xD7c295E399CA928A3a14b01D760E794f1AdF8990"; // anycall on fantom testnet
 const uri = `https://api.opensea.io/api/v2/metadata/matic/0x2953399124F0cBB46d2CbACD8A89cF0599974963/0x{id}`
 
 module.exports = function (deployer) {
     let token = await deployer.deploy(MC_Openstore, ["MC OPENSTORE TEST", "MC OPENSTORE TEST", uri, "0x0000000000000000000000000000000000000000"]);
     let gateway = await deployer.deploy(MC_Openstore_Gateway, [anycall, token.address]);
     token.setGateway(gateway.address, { gas: 500000 });
     console.log(token.address);
     console.log(gateway.address);
   };