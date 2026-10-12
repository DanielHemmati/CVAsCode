# Resume Summary API Plan

## Goal

Add a button that requests a short resume summary from Amazon Nova Micro. The browser will call API Gateway, which will invoke a Python Lambda function.

Terraform will manage all AWS resources. The design will limit traffic, Bedrock use, and unexpected cost.

## Resume Input Decision

Use `resume-page/index.md` as the Bedrock input. Markdown gives Nova the resume structure without CSS, JavaScript, or SVG data.

The Lambda package will include `resume-page/index.md`. Python will read the file and send its text in one prompt to Bedrock.

Keep `index.md` synchronized with the visible resume content in `index.html`. Remove presentation-only HTML tags from `index.md` before implementation.

Do not accept resume text or prompt text from the browser. A caller must not control the Bedrock prompt.

## Rate-Limit Decision

Use an API Gateway HTTP API for its lower cost and smaller configuration. Configure a shared route throttle of one request per second with a burst of two requests.

HTTP API throttling is not a per-user limit. One caller can consume the shared allowance, and HTTP APIs do not support usage plans or AWS WAF directly.

Set Lambda reserved concurrency to two as a second cost boundary. Return `429 Too Many Requests` to requests above the API or Lambda limit.

This design limits total Bedrock calls, but it does not identify individual users. If strict per-IP protection becomes a requirement, replace HTTP API with a Regional REST API and attach an AWS WAF rate-based rule.

Do not put an API key in the browser. A public browser API key is visible to every visitor and is not an authentication control.

## Fixed Design

- Terraform `1.16.1` and AWS provider `~> 6.0`.
- One state at `prod/resume-summary/terraform.tfstate`.
- One reusable module at `terraform/modules/resume-summary`.
- One production root at `terraform/live/prod/resume-summary`.
- API Gateway HTTP API with payload format version `2.0`.
- One public `GET /summary` route.
- Python Lambda on the on-demand capacity provider.
- Python `3.13` runtime and `arm64` architecture.
- A ZIP package with only Python source and `resume-page/index.md`.
- Amazon Bedrock Converse API with Amazon Nova Micro.
- One non-streaming Bedrock request for each successful API request.
- An explicit `maxTokens` value of `250`.
- A low temperature, such as `0.2`, for stable output.
- Lambda timeout below the HTTP API hard limit of 30 seconds.
- Lambda reserved concurrency of two.
- API access logs and Lambda logs with 7-day retention.
- No VPC, database, secret, API key, or user authentication.
- No prompt or complete resume content in application logs.

The implementation must discover the available Nova Micro model ID in `us-east-1`. Store the selected ID in a Terraform variable or Lambda environment variable.

Do not hard-code an unverified model ID. Use the base model ID or inference profile that is available in the account and Region.

## Request Flow

1. A visitor selects the summary button.
2. Browser code disables the button while the request is active.
3. The browser sends `GET /summary` with no request body.
4. API Gateway applies the shared route throttle.
5. API Gateway invokes the Lambda function.
6. Lambda reads the packaged `index.md` file.
7. Lambda adds the Markdown resume text to the fixed prompt.
8. Lambda sends one server-controlled prompt to Nova Micro through `bedrock-runtime.converse`.
9. Lambda returns a JSON response with the summary.
10. The page renders the summary in a text container.

Use this response shape:

```json
{
  "summary": [
    "First summary point.",
    "Second summary point."
  ]
}
```

The prompt will request five short points about skills, experience, certifications, education, and selected projects. The handler will treat model output as text and will not render it as HTML.

## Security Boundaries

- Allow Lambda to call only the approved Bedrock model or inference profile.
- Allow API Gateway to invoke only the summary Lambda function.
- Do not grant Lambda access to S3 because the Markdown file is in its ZIP package.
- Do not accept a custom prompt, model ID, output length, or resume body from the request.
- Use an exact production website origin in the HTTP API CORS configuration.
- Permit only `GET` and `OPTIONS` methods.
- Do not use `Access-Control-Allow-Origin: *` in production.
- Return model output through `textContent`, not `innerHTML`.
- Keep Bedrock model invocation logging disabled for this feature.
- Do not log API request headers or resume text.

The Lambda role needs CloudWatch Logs permissions and `bedrock:InvokeModel`. Add `bedrock:InvokeModelWithResponseStream` only if a later phase adds streaming.

## Failure Contract

Return these status codes:

- `200` for a valid summary.
- `405` for an unsupported method if the handler receives one.
- `429` when API Gateway or Lambda throttles the request.
- `502` when Bedrock returns a retryable service failure after SDK retries.
- `500` for an unexpected internal failure.

The browser will show a short error message and enable the button again. It will not retry `429` responses automatically.

## Phase Rules

Implement only one phase at a time.

For each phase:

1. Make only the listed changes.
2. Run the shared validation commands.
3. Create a saved Terraform plan when the phase adds or changes resources.
4. Show the code diff and saved plan to the project owner.
5. Wait for approval before the next phase.
6. Add `✅` to the phase heading after completion.

Do not apply a new plan directly to production without review and approval.

## Phase 1: Confirm AWS and Model Access ✅

Use the AWS MCP tools for AWS operations. Confirm:

- The active AWS account and `us-east-1` Region.
- Amazon Nova Micro availability.
- The correct base model ID or inference profile ID.
- Permission to invoke the selected model.
- The current API Gateway account throttle quota.
- The exact CloudFront website URL for CORS.

Run one small Converse request with an explicit `maxTokens` value. Do not create or change AWS resources in this phase.

Review gate:

- The selected model ID works in `us-east-1`.
- The test uses the `bedrock-runtime` client.
- The model response contains text.
- No credential or account-specific secret enters the repository.

## Phase 2: Lambda Application and Unit Tests ✅

Create a small application directory outside the Terraform module. Include:

- The Lambda handler.
- The Markdown file loader.
- A prompt builder with fixed instructions.
- Unit tests for file loading, prompt construction, success, and Bedrock errors.

Initialize the boto3 client outside the handler. Configure adaptive retries with a small maximum attempt count.

Call `bedrock-runtime.converse` with:

- The verified Nova Micro model ID.
- One user message that contains fixed instructions and the Markdown resume text.
- `maxTokens = 250`.
- `temperature = 0.2`.

The Markdown source must contain the resume headings and visible content in the correct order. It must not contain CSS, JavaScript, SVG data, or presentation-only HTML tags.

Review gate:

- The application has no third-party runtime dependency unless it adds clear value.
- Tests do not call AWS.
- The request body cannot change the prompt.
- Logs do not contain the prompt, resume, or model response.
- The handler returns the approved JSON shape.

## Phase 3: Terraform Module Scaffold ✅

Create these directories:

```text
terraform/modules/resume-summary/
terraform/live/prod/resume-summary/
```

Add standard module and production root files. Configure:

- The backend key `prod/resume-summary/terraform.tfstate`.
- The AWS provider in `us-east-1`.
- Inputs for names, model ID, CORS origin, throttle values, and tags.
- Outputs for the API endpoint, API ID, route, and Lambda function name.
- Production names and standard project tags.

Package the Lambda source and a copy of `resume-page/index.md` with `archive_file`. Use a source hash so that content changes update the function.

Do not create managed AWS resources in this phase.

Review gate:

- Both directories initialize and validate.
- The plan contains no managed resources.
- The module does not depend on local absolute paths.
- The lock file contains the approved provider versions.

## Phase 4: Lambda, IAM, and Logs ✅

Create:

- One Lambda execution role.
- One least-privilege inline IAM policy.
- One CloudWatch log group with 7-day retention.
- One Python Lambda function.

Configure the function with:

- Python `3.13`.
- `arm64`.
- An initial memory size of 512 MiB.
- A timeout of 25 seconds.
- Reserved concurrency of two.
- The verified model ID in an environment variable.
- Active X-Ray tracing only if the added cost and permissions are accepted.

The IAM policy will scope Bedrock access to the selected model resources. Cross-Region inference can require permissions for every destination model in the profile.

Review gate:

- The role does not use `bedrock:*` or broad administrator policies.
- The function has no VPC configuration.
- The timeout is below the HTTP API limit.
- Reserved concurrency protects Bedrock and account capacity.
- The log group retains logs for 7 days.
- The saved plan contains only Lambda, IAM, and logging resources.

## Phase 5: HTTP API and Throttling

Create:

- One API Gateway HTTP API.
- One Lambda proxy integration.
- One `GET /summary` route.
- One `$default` stage with automatic deployment.
- One Lambda permission for API Gateway.
- One API Gateway access log group with 7-day retention.

Configure the stage with:

- A rate limit of one request per second.
- A burst limit of two requests.
- JSON access logs without sensitive request values.
- Detailed metrics if the expected cost is accepted.

Configure CORS with the exact CloudFront website origin. Permit `GET`, `OPTIONS`, and the `Content-Type` header.

Review gate:

- The route invokes only the summary function.
- The Lambda permission uses the API execution ARN.
- The route throttle appears in the saved plan.
- A request from the website origin succeeds.
- A request from an unapproved browser origin does not pass the browser CORS check.
- Repeated requests produce `429` responses at the configured boundary.

## Phase 6: Resume User Interface

Replace the current Claude link behavior with an API request. Keep the current visual button style.

Add:

- A loading state.
- A disabled state while one request is active.
- An accessible live region for the result.
- A short error state for `429`, service failure, and network failure.
- Safe text-only rendering for the five points.
- A short browser cooldown after a successful request.

Update the CloudFront content security policy so `connect-src` permits only the deployed API origin. Remove the old code that opens Claude with the page URL.

Do not treat the browser cooldown as a security control. A caller can bypass browser code.

Review gate:

- The button does not open a new tab.
- One selection sends one API request.
- The result is readable with a keyboard and screen reader.
- Model output cannot inject HTML.
- The page handles `429` without an automatic retry loop.
- Existing duration and motto code still works.

## Phase 7: Observability and Cost Controls

Add CloudWatch alarms for:

- Lambda errors.
- Lambda throttles.
- Lambda duration near the timeout.
- API Gateway `5XX` responses.
- API Gateway `4XX` responses above an expected baseline.

Add a small AWS Budget or document why the project-level budget already covers Bedrock and Lambda. Do not put an email address directly in a reusable module.

Record Bedrock input and output token counts as numeric log fields. Do not log prompt or response text.

Review gate:

- Alarms have clear names and descriptions.
- All CloudWatch log groups retain logs for 7 days.
- Logs contain request IDs, status, latency, and token counts only.
- The cost boundary includes API throttling, Lambda reserved concurrency, and explicit `maxTokens`.
- The saved plan does not add unrelated monitoring resources.

## Phase 8: Integration and Load Verification

After apply:

1. Request the summary from the deployed resume page.
2. Make sure that the response contains five short points.
3. Make sure that the function uses Nova Micro.
4. Send a short controlled burst and observe `429` responses.
5. Make sure that Lambda concurrency does not exceed two.
6. Make sure that API and Lambda logs omit resume and model text.
7. Change the same resume text in `index.html` and `index.md`, then deploy again.
8. Make sure that the Lambda source hash changes.
9. Request the summary and make sure that it uses the changed resume.
10. Inspect alarms, metrics, and estimated cost.

Stop the load test if it causes sustained throttling or unexpected Bedrock cost.

## Shared Validation

Run these commands in every implementation phase:

```bash
terraform fmt -check -recursive -diff terraform/modules
terraform fmt -check -recursive -diff terraform/live
terraform -chdir=terraform/modules/resume-summary init -backend=false -input=false -lockfile=readonly
terraform -chdir=terraform/modules/resume-summary validate
terraform -chdir=terraform/live/prod/resume-summary init -input=false -lockfile=readonly
terraform -chdir=terraform/live/prod/resume-summary validate
tflint --config=.tflint.hcl --init
tflint --chdir=terraform/modules --recursive --config="$(pwd)/.tflint.hcl"
tflint --chdir=terraform/live --recursive --config="$(pwd)/.tflint.hcl"
trivy config terraform/modules
trivy config terraform/live
python -m unittest discover
```

Create and review a saved plan before each apply:

```bash
terraform -chdir=terraform/live/prod/resume-summary plan -out=tfplan
terraform -chdir=terraform/live/prod/resume-summary show tfplan
```

Adjust the Python test command if the project selects another test runner.

## Final Verification

- The resume remains a static CloudFront site.
- The button calls the summary API without a user-supplied prompt.
- Lambda reads resume text from the packaged `index.md` file.
- Nova Micro returns five short summary points.
- API Gateway applies the shared route throttle.
- Lambda reserved concurrency limits downstream calls.
- IAM permissions follow least privilege.
- Logs do not contain the resume, prompt, or response text.
- Terraform can reproduce all AWS resources.
- The README explains the shared throttle and its per-user limitation.

## Rollback

To stop Bedrock calls immediately, set Lambda reserved concurrency to zero through a reviewed Terraform change. Keep logs during investigation.

To remove the feature, first restore the old button behavior or remove the button. Deploy the static assets before deleting the API endpoint.

Create and inspect a destroy plan for the `resume-summary` stack. Remove API Gateway, Lambda permissions, Lambda, alarms, log groups, and IAM resources only after approval.

Do not destroy the static-site or CloudFront logging stacks. Keep the saved plan and relevant CloudWatch metrics as rollback evidence.

## References

- [API Gateway HTTP API throttling](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-throttling.html)
- [API Gateway request throttling](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-request-throttling.html)
- [Lambda concurrency](https://docs.aws.amazon.com/lambda/latest/dg/configuration-concurrency.html)
- [Amazon Bedrock Converse API](https://docs.aws.amazon.com/bedrock/latest/userguide/conversation-inference-call.html)
- [Invoke Amazon Nova with Converse](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-runtime_example_bedrock-runtime_Converse_AmazonNovaText_section.html)
- [Amazon Bedrock model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
