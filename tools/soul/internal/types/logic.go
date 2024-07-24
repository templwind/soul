package types

import "github.com/templwind/soul/tools/soul/pkg/site/spec"

type Topic struct {
	Topic             string
	RawTopic          string
	Name              string
	Const             string
	RequestType       string
	HasReqType        bool
	ResponseType      string
	HasRespType       bool
	LogicFunc         string
	InitiatedByClient bool
	InitiatedByServer bool
}

type MethodConfig struct {
	spec.Method
	Get            bool
	Post           bool
	Put            bool
	Delete         bool
	Options        bool
	HasBaseProps   bool
	HasHTMX        bool
	HasResp        bool
	HasReq         bool
	HasPage        bool
	HasPathInReq   bool
	RequiresSocket bool

	RequestType      string
	ResponseType     string
	Request          string
	ReturnString     string
	ResponseString   string
	ReturnsPartial   bool
	HandlerName      string
	HasDoc           bool
	Doc              string
	LogicName        string
	LogicType        string
	LogicFunc        string
	IsSocket         bool
	TopicsFromClient []Topic
	TopicsFromServer []Topic
	SocketType       string
	Topic            Topic
	AssetGroup       string
}
