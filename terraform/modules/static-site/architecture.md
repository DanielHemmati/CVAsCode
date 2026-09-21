# Private Static Website Architecture

This module creates a private Amazon S3 bucket and exposes its website files only through Amazon CloudFront. CloudFront uses Origin Access Control (OAC) to sign each request to S3.

## Request Flow

Start at **1. Visitor** and follow the numbered arrows.

```mermaid
flowchart LR
    visitor(["1. Visitor opens<br/>the website"])
    cloudfront["2. CloudFront distribution<br/>Public HTTPS endpoint"]
    oac["3. Origin Access Control<br/>Signs request with SigV4"]
    s3[("4. Private S3 bucket<br/>Returns index.html/assets")]

    visitor -->|"HTTPS request"| cloudfront
    cloudfront -->|"Uses"| oac
    oac -->|"Signed HTTPS request"| s3
    s3 -->|"Private object response"| cloudfront
    cloudfront -->|"Cached HTTPS response"| visitor

    public_block["S3 public access block<br/>All settings enabled"]
    bucket_policy["S3 bucket policy<br/>Allows only this distribution"]
    encryption["S3 encryption<br/>AES-256"]
    versioning["S3 versioning<br/>Enabled"]

    public_block -.->|"Protects"| s3
    bucket_policy -.->|"Authorizes CloudFront"| s3
    encryption -.->|"Encrypts objects"| s3
    versioning -.->|"Keeps object versions"| s3

    classDef start fill:#d9f2d9,stroke:#237a3b,stroke-width:3px,color:#111;
    classDef public fill:#e6f0ff,stroke:#2563a8,stroke-width:2px,color:#111;
    classDef private fill:#fff0d6,stroke:#b36b00,stroke-width:2px,color:#111;
    classDef control fill:#f2e7ff,stroke:#7137a8,stroke-width:1px,color:#111;

    class visitor start;
    class cloudfront public;
    class oac,s3 private;
    class public_block,bucket_policy,encryption,versioning control;
```

The S3 bucket is not an S3 website endpoint and cannot be opened directly from the internet. CloudFront uses the bucket's regional REST endpoint because OAC does not support S3 website endpoints.

## Terraform Dependency Flow

Start at **1. Root module**. Solid arrows show resource references that Terraform uses to determine creation order. Dotted arrows show configuration inputs.

```mermaid
flowchart TD
    root["1. Root module<br/>module static_site"]
    inputs["2. Input variables<br/>bucket_name, root object,<br/>price class, tags"]
    caller["AWS caller identity<br/>Current account ID"]
    cache["AWS managed cache policy<br/>CachingOptimized"]

    bucket["aws_s3_bucket.website"]
    pab["aws_s3_bucket_public_access_block.website"]
    ownership["aws_s3_bucket_ownership_controls.website"]
    encryption["aws_s3_bucket_server_side_encryption_configuration.website"]
    versioning["aws_s3_bucket_versioning.website"]

    oac["aws_cloudfront_origin_access_control.website"]
    distribution["aws_cloudfront_distribution.website"]
    policy_doc["aws_iam_policy_document.website"]
    bucket_policy["aws_s3_bucket_policy.website"]
    outputs["3. Outputs<br/>Website URL, distribution ID,<br/>bucket ID and ARNs"]

    root -.-> inputs
    inputs -.-> bucket
    inputs -.-> oac
    inputs -.-> distribution

    bucket --> pab
    bucket --> ownership
    bucket --> encryption
    bucket --> versioning
    bucket --> distribution
    oac --> distribution
    cache --> distribution

    bucket --> policy_doc
    distribution --> policy_doc
    caller --> policy_doc
    policy_doc --> bucket_policy
    bucket --> bucket_policy
    pab -->|"Explicit depends_on"| bucket_policy

    bucket --> outputs
    distribution --> outputs

    classDef start fill:#d9f2d9,stroke:#237a3b,stroke-width:3px,color:#111;
    classDef input fill:#e6f0ff,stroke:#2563a8,stroke-width:1px,color:#111;
    classDef aws fill:#fff0d6,stroke:#b36b00,stroke-width:2px,color:#111;
    classDef result fill:#f2e7ff,stroke:#7137a8,stroke-width:2px,color:#111;

    class root start;
    class inputs,caller,cache input;
    class bucket,pab,ownership,encryption,versioning,oac,distribution,policy_doc,bucket_policy aws;
    class outputs result;
```

## Starting Points

1. **Terraform deployment:** Run Terraform from a live root module that calls `modules/static-site`. Do not run the reusable module directly for a real environment.
2. **Website request:** A visitor starts at the CloudFront HTTPS URL returned by `website_url`.
3. **Website upload:** Upload `index.html` and other static files to the S3 bucket returned by `bucket_id`.
4. **Private access:** CloudFront signs origin requests through OAC. The bucket policy accepts requests only when `AWS:SourceArn` matches this CloudFront distribution.

## Creation Sequence

Terraform builds independent resources in parallel, so the exact order can vary. The effective sequence is:

1. Read module inputs, the AWS account ID, and the managed CloudFront cache policy.
2. Create the S3 bucket and CloudFront OAC.
3. Configure the bucket's public-access block, ownership, encryption, and versioning.
4. Create the CloudFront distribution using the S3 regional endpoint and OAC.
5. Generate and attach the bucket policy after the distribution ARN is known.
6. Return the bucket and CloudFront outputs.
