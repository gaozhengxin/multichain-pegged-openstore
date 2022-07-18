const Factory = artifacts.require("ERC721Factory");
const MC_Openstore_Gateway = artifacts.require("ERC1155Gateway_MintBurn");
const gateway_addr = "0x5507D87478625c1cDc1a02aD85Fe6AA02F61BC07"; // anycall on fantom testnet
const uri = `https://api.opensea.io/api/v2/metadata/matic/0x2953399124F0cBB46d2CbACD8A89cF0599974963/0x{id}`

module.exports = async function (deployer) {
    let factory = await deployer.deploy(Factory, gateway_addr);
    let gateway = await MC_Openstore_Gateway.at(gateway_addr);
    token.setFactory(factory.address);
  };