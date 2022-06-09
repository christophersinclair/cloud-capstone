# Fauna (Cloud Capstone Project)
Capstone project for Purdue University Bachelor's in Cloud Computing and Solutions program.

Steps:
- Fill in values for AWS credentials in `cli.ini`. Alternatively, Terraform will automatically pick these up from `~/.aws/credentials` if not supplied
- Run `./deploy.sh` to build the entire infrastructure with Terraform and deploy the application code.
- Each AWS service's deployment code is located in the `services` folder