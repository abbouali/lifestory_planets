const LifePlanetNFT = artifacts.require("LifePlanetNFT")

module.exports = async function (deployer, network, accounts) {

  // OpenSea proxy registry addresses for rinkeby and mainnet.
  let proxyRegistryAddress = "";
  if (network === 'rinkeby') {
    proxyRegistryAddress = "0x1E525EEAF261cA41b809884CBDE9DD9E1619573A";
  } else {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  }
  paymentsAddress = "0xF4104Bf8FDD7a7c4d2e1aa7A27158020d2Dd86f3";

  await deployer.deploy(LifePlanetNFT, proxyRegistryAddress, paymentsAddress, 500); // 1000/10000 == 10%
  lifePlanetNFT = await LifePlanetNFT.deployed();
}