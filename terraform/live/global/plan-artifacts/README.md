# Bootstrap the private plan bucket

The deployment workflow cannot store plans until this bucket exists. The S3 state bucket in `backend.tf` must already exist. Use the allowed local AWS identity for this one-time bootstrap.

1. Initialize the root module.

   ```bash
   terraform -chdir=terraform/live/global/plan-artifacts init -reconfigure -input=false -lockfile=readonly
   ```

2. Create and review a saved plan.

   ```bash
   terraform -chdir=terraform/live/global/plan-artifacts plan -input=false -lock-timeout=5m -out=terraform.tfplan
   terraform -chdir=terraform/live/global/plan-artifacts show terraform.tfplan
   ```

3. If the plan is correct, apply that exact saved plan.

   ```bash
   terraform -chdir=terraform/live/global/plan-artifacts apply -input=false -lock-timeout=5m terraform.tfplan
   ```

After this bootstrap, use the GitHub workflow for plans and applies. S3 expires uploaded objects after five days.
