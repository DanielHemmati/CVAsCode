# Terraform

![Terraform folder structure hero](../assets/terraform-hero-page.png)

This folder separates reusable Terraform code from live infrastructure configuration and tests.

## Folder Structure

```text
terraform/
├── modules/
├── live/
└── test/
```

## `modules/`

Reusable Terraform modules live here. A module should define one clear piece of infrastructure, such as networking, a database, or an application service.

Typical module layout:

```text
modules/<module-name>/
├── main.tf
├── variables.tf
├── outputs.tf
└── tests/
    └── basic.tftest.hcl
```

Native Terraform tests belong close to the module they validate, usually under `modules/<module-name>/tests/`.

## `live/`

Live environment configuration goes here. These folders represent real deployable environments such as `dev`, `stage`, or `prod`.

Each live folder should call modules from `modules/` and configure environment-specific values, providers, and remote state.

Example:

```text
live/
├── dev/
├── stage/
└── prod/
```

Keep each deployable unit small enough to have its own state file. Avoid putting all infrastructure for every environment into one large Terraform state.

## `test/`

Terratest tests live here. These are Go tests that can deploy real infrastructure, inspect it, and then tear it down.

Example:

```text
test/
└── networking_test.go
```

Use Terratest for higher-level integration tests and native Terraform tests for module-level validation.
