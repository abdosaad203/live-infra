module "vpc" {
  source = "../../modules/vpc"

}

module "runner" {
  source = "../../modules/runner"

  environment = "shared"

  vpc_id = module.vpc.vpc_id

  subnet_ids = [
    module.vpc.public_subnet_1_id,
    module.vpc.public_subnet_2_id
  ]

  key_name = "depi-key"

  runner_count = 4
}

resource "local_file" "ansible_inventory" {
  content = templatefile(
    "${path.root}/../../../ansible/inventory.tpl",
    {
      runner_ips = module.runner.public_ips
    }
  )

  filename = "${path.root}/../../../ansible/inventory.ini"
}