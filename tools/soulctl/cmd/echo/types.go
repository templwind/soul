package echo

type Topic struct {
	Topic             string
	RawTopic          string
	Name              string
	Const             string
	RequestType       string
	HasReqType        bool
	ResponseType      string
	HasRespType       bool
	Call              string
	InitiatedByClient bool
	InitiatedByServer bool
}
type MethodConfig struct {
	RequestType      string
	ResponseType     string
	Request          string
	ReturnString     string
	ResponseString   string
	ReturnsPartial   bool
	HasResp          bool
	HasReq           bool
	HandlerName      string
	HasDoc           bool
	Doc              string
	HasPage          bool
	LogicName        string
	LogicType        string
	Call             string
	IsSocket         bool
	TopicsFromClient []Topic
	TopicsFromServer []Topic
	SocketType       string
	Topic            Topic
	AssetGroup       string
}
