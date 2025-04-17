// Sample Module API Definition

info(
	title: "Sample Module API"
	description: "API for the Sample module"
)

type SampleRequest {
	SampleID string `json:"sampleId" validate:"required,uuid"`
}

type SampleResponse {
	Name  string `json:"name"`
	Email string `json:"email"`
	Phone string `json:"phone,optional,omitempty"`
}

@server(
	group: modules/sample
	prefix: /api/module/sample
	jwt: Auth
)
service Sample {
	@handler GetSample
	get /sample (SampleRequest) returns (SampleResponse)
}