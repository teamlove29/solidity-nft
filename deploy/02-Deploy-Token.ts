import chalk from 'chalk'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, network } = hre
  const { deploy, execute, log, get } = deployments
  const { deployer } = await getNamedAccounts()

  log(`Deploying contracts with the account: ${deployer}`)
  log(chalk.yellow(`Network Name: ${network.name}`))
  log('----------------------------------------------------')

  const contractAll: { [key: string]: any } = {}

  let nounsSeeder: String
  let nounsDescriptor: string

  nounsSeeder = (await get('NounsSeeder')).address
  nounsDescriptor = (await get('NounsDescriptor')).address
  const WyvernProxyRegistry = "0xeCeAa7453a77bFE339B25D9D9E91009CdE71c768"

  contractAll[`_noundersDAO`] = deployer;
  contractAll[`_minter`] = deployer;
  contractAll[`_descriptor`] = nounsDescriptor;
  contractAll[`_seeder`] = nounsSeeder;
  contractAll[`_proxyRegistry`] = WyvernProxyRegistry;

  const deploymentName = 'NounsToken'
  const NounsToken = await deploy(deploymentName, {
    from: deployer,
    args :Object.values(contractAll),
    log: true,
    skipIfAlreadyDeployed: true,
  })
  log(`You have deployed an NounsToken contract to ${NounsToken.address}`)

  log(`Could be found at ....`)
  log(chalk.yellow(`/deployment/${network.name}/${deploymentName}.json`))

  for (const i in contractAll) {
    log(chalk.yellow(`Argument: ${i} - value: ${contractAll[i]}`))
  }

  //   if (NounsToken.newlyDeployed) {
  try {
    await hre.run('verify:verify', {
      address: NounsToken.address,
      constructorArguments: Object.values(contractAll),
    })
  } catch (err) {
    console.log(err)
  }
  //   }

  log(chalk.cyan(`Ending Script.....`))
  log(chalk.cyan(`.....`))
}
export default func
func.tags = ['all', 'NounsToken']