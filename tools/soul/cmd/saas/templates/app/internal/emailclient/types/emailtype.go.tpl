package types

type EmailType int64

const (
	EmailTypeUnknown EmailType = iota
	EmailTypeCampaign
	EmailTypeTransactional
)

func (e EmailType) Int64() int64 {
	return int64(e)
}
