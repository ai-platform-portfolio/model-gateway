# Model availability and hosting evidence

Checked: 2026-10-11. This is a dated research snapshot, not a deployed catalogue. Exact account access, quotas, routing destinations, and feature compatibility have not been probed.

## Foundry access is not synonymous with Azure hosting

Microsoft distinguishes version 1, hosted on Anthropic infrastructure outside Azure, from version 2, hosted on Azure. Its current table lists Fable 5.1 as Anthropic-hosted preview only; Opus 5.5, Sonnet 5.5, and Haiku 5.5 have both hosting options listed as GA. Current listings cannot retrospectively prove Azure-hosted availability at the instant of launch. [Microsoft model catalogue](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/claude-models).

For Azure-hosted Claude, Microsoft states that ingress, API services, and GPU inference use Azure infrastructure. Anthropic remains seller, operator, and independent processor. Anthropic-hosted deployments may process outside Azure and outside the selected Azure region. [Microsoft data-processing documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/responsible-ai/claude-models/data-privacy).

Anthropic's June 29 announcement explicitly recommends its hosted option for models or features not yet available on Azure and describes parity as a future aim. This supports designing for different hosting catalogues; it does not establish a permanent rule that every new release reaches Azure later. [Anthropic announcement](https://claude.com/resources/articles/claude-in-microsoft-foundry).

## Recent releases, rather than older model families

| Exact release | Dated evidence | Interpretation |
| --- | --- | --- |
| Claude Fable 5.1 | September 1 release; announcement names AWS, Google Cloud, and Microsoft Azure | Distribution language must be reconciled with Foundry's Anthropic-hosted-only listing |
| Claude Sonnet 5.5 | September 28 release; platform documentation names Claude API, Bedrock, Google Cloud, Foundry, and Claude Platform on AWS | Model availability is broad; physical hosting and enabled features remain separate checks |
| Claude Haiku 5.5 | October 7 announcement says available immediately on all platforms, including Microsoft Azure | A universal Azure delay claim is unsupported |
| GPT-6.1 Sol | OpenAI API release and AWS GA announcement both September 29 | Evidence of AWS launch-day access for this release |
| GPT-6 Astra | OpenAI API September 3; AWS GA announcement September 8 | AWS is not universally simultaneous with first-party release |
| Gemini 3.8 Flash | Google Cloud release notes list GA September 2 | Google Cloud inference is a candidate; it does not require a managed agent runtime |

Sources: [Fable announcement](https://www.anthropic.com/claude-fable-and-mythos-5-1), [Sonnet platform documentation](https://platform.claude.com/docs/en/models/sonnet-5-5/overview), [Haiku announcement](https://www.anthropic.com/claude-haiku-5-5), [OpenAI API changelog](https://developers.openai.com/api/docs/changelog), [AWS GPT-6.1 announcement](https://aws.amazon.com/about-aws/whats-new/2026/09/openai-gpt-6-1-sol-on-amazon-bedrock/), [AWS Astra announcement](https://aws.amazon.com/blogs/machine-learning/take-on-your-most-ambitious-work-with-gpt-6-astra-on-amazon-bedrock/), [Google release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes).

Azure's current OpenAI catalogue also lists GPT-6.1 Sol and GPT-6 Astra. Model-version dates are not sufficient proof of first deployment availability or entitlement in a particular subscription. [Azure model catalogue](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure).

## AWS features and sensitive-data restrictions

Bedrock has multiple endpoint/API paths. OpenAI's documentation describes Runtime and Mantle differences, including model/location availability and unsupported features. Do not infer full first-party parity from an OpenAI-compatible request shape. [OpenAI Bedrock guide](https://developers.openai.com/api/docs/guides/amazon-bedrock).

The Fable 5.1 card requires an `aws_review` retention setting and distinguishes geographic/global inference profiles from in-region inference. Its runtime catalogue currently shows European source regions with global routing rather than a European geographic option. Verify destinations rather than treating a London endpoint as UK processing. [AWS model card](https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-anthropic-claude-fable-5-1.html).

AWS documents model-specific exceptions to default zero retention: Fable 5/5.1 traffic can be retained up to 30 days, with flagged content potentially reviewed by AWS. Listed GPT families have flagged-traffic retention exceptions and an eligibility process for full ZDR. Program-specific exceptions require verification and can expire. [Bedrock abuse detection](https://docs.aws.amazon.com/bedrock/latest/userguide/abuse-detection.html).

## Required US and UK/EU residency

The initial deployment must support separate US and UK/EU tenant boundaries. UK/EU includes the United Kingdom and EU member states; Switzerland requires additional approval. Provider geography labels must be compared with this explicit country set.

Anthropic's direct API currently offers only US or global inference and US workspace geography. Workspace allowlists can enforce US-only routing. This direct route is not eligible for UK/EU-only workloads. Foundry Claude offers Global and, for supported Azure-hosted models, US Data Zone; Anthropic-hosted deployments do not guarantee the selected Azure region. [Anthropic residency controls](https://platform.claude.com/docs/en/manage-claude/data-residency), [Foundry Claude deployment types](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/how-to/use-foundry-models-claude).

Bedrock's Sonnet 5.5 card lists US and EU geographic profiles. Its EU destination set depends on source: Ireland and Frankfurt sources list EU-member destinations; London includes London; Zurich includes Zurich. Use an approved UK/EU source and inspect GetInferenceProfile before admission. Do not generalize this eligibility to Fable or all Claude versions. [Sonnet 5.5 model card](https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-anthropic-claude-sonnet-5-5.html).

OpenAI direct Europe processing is defined as EEA plus Switzerland, which is broader than the required UK/EU boundary. It is not automatically eligible without approval of that wider scope. Azure OpenAI supported geography-scoped or EU Data Zone deployments are candidates; Global deployments are ineligible. [OpenAI data controls](https://developers.openai.com/api/docs/guides/your-data), [Azure OpenAI processing locations](https://learn.microsoft.com/en-us/azure/foundry/responsible-ai/openai/data-privacy).

For Gemini, assess Google Cloud model-specific ML-processing guarantees and locational or US/EU multi-region endpoints; exclude global endpoints. The Developer API's paid no-training terms alone do not establish UK/EU processing residency. Latest-model and feature eligibility must be checked independently. [Google Cloud residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency), [Gemini Developer API terms](https://ai.google.dev/gemini-api/terms).

## Concrete Azure-origin inference routes

An Azure-hosted application can invoke all three model families without moving its application harness. This does not mean all inference is physically hosted by Azure. The proposed initial routes are:

| Model family | US tenant | UK/EU tenant |
| --- | --- | --- |
| GPT | Azure OpenAI US Data Zone Standard | Azure OpenAI EU Data Zone Standard in an EU resource geography |
| Claude | Bedrock Runtime approved US geographic profile | Bedrock Runtime approved EU geographic profile from Ireland, Frankfurt, or London |
| Gemini | Google Cloud US multi-region model API | Google Cloud EU multi-region model API |

Microsoft's GPT-6.1 Sol announcement explicitly lists US and EU Data Zone Standard; EU provisioned throughput is not established by that launch announcement. Confirm subscription quota and exact deployment compatibility. [Microsoft announcement](https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/introducing-gpt-6-1-sol-in-microsoft-foundry-advanced-intelligence-optimized-for/4560811).

Google documents model API hostnames `aiplatform.us.rep.googleapis.com` and `aiplatform.eu.rep.googleapis.com` for jurisdiction-bound ML processing. The Gemini 3.8 Flash row in the official residency table contains Supported indicators for both US and EU multi-region processing; these indicators were checked in the source HTML because text extraction omitted them. This is Google Cloud inference, not the Gemini Developer API. Calling this API does not require adopting Google's managed agent runtime. [Endpoint documentation](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/locations), [Model-specific residency table](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency).

Residency is not synonymous with zero retention. Google Cloud documents regional abuse-monitoring logs and model-specific exceptions, including advanced-model sharing and retention requirements. Keep the initial approval restricted to the evaluated model and feature set, and assess storage, safety-review, caching, and third-party tools independently. [Google Cloud abuse monitoring](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/abuse-monitoring).

Before production admission, verify account entitlement, quota, deployed SKU, source and all destination countries, provider contractual scope, retention mode, SDK endpoint selection, and feature compatibility. Run synthetic requests and policy-denial/failover checks. A successful request proves access, not the physical GPU location; provider residency commitments establish that location guarantee. No account-level inference probe or deployment has been performed for this research snapshot.

## Design implications

Track model, operator, physical hosting, processing scope, retention, API, version, entitlement, and capabilities separately. Unknown values fail sensitive-workload eligibility. Launch-day discovery leads to synthetic testing and tenant-specific approval, never automatic production promotion.

Choose AWS and Google Cloud as initial external inference integrations while keeping approved Azure, direct, and private paths extensible. Do not claim a cloud permanently wins model launch timing. Record provider announcement time, catalogue observation time, and the first successful account probe separately.
