import chalk from 'chalk'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, network } = hre
  const { deploy, execute, log } = deployments
  const { deployer } = await getNamedAccounts()

  log(`Deploying contracts with the account: ${deployer}`)
  log(chalk.yellow(`Network Name: ${network.name}`))
  log('----------------------------------------------------')

  const name: { [key: string]: any } = {}

  const deploymentName = 'NounsDescriptor'
  const NounsDescriptor = await deploy(deploymentName, {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: true,
  })
  log(`You have deployed an NounsDescriptor contract to ${NounsDescriptor.address}`)

  log(`Could be found at ....`)
  log(chalk.yellow(`/deployment/${network.name}/${deploymentName}.json`))

  for (const i in name) {
    log(chalk.yellow(`Argument: ${i} - value: ${name[i]}`))
  }

//   if (NounsDescriptor.newlyDeployed) {
    try {
      await hre.run('verify:verify', {
        address: NounsDescriptor.address,
        // constructorArguments: Object.values(name),
      })
    } catch (err) {
      console.log(err)
    }
//   }

  log(chalk.cyan(`Ending Script.....`))
  log(chalk.cyan(`.....`))
}
export default func
func.tags = ['all', 'NounsDescriptor']