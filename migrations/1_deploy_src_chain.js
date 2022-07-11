/**
 * Deploy source chain contracts
 */
const Openstore = artifacts.require("AssetContractShared");
const Openstore_Gateway = artifacts.require("ERC1155Gateway_LILO");
const anycall = "0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02"; // anycall on rinkeby
const uri = `https://api.opensea.io/api/v2/metadata/matic/0x2953399124F0cBB46d2CbACD8A89cF0599974963/0x{id}`

module.exports = function (deployer) {
  let token = await deployer.deploy(Openstore, ["OPENSTORE TEST", "OPENSTORE TEST", "0x0000000000000000000000000000000000000000", uri, "0x0000000000000000000000000000000000000000"]);
  let gateway = await deployer.deploy(Openstore_Gateway, [anycall, token.address]);
  console.log(token.address);
  console.log(gateway.address);
};
