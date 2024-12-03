package types

import "github.com/templwind/soul/tools/soul/pkg/site/spec"

type Topic struct {
	Topic              string
	ResponseTopic      string
	RawTopic           string
	Name               string
	Const              string
	RequestType        string
	HasReqType         bool
	ResponseType       string
	HasRespType        bool
	LogicFunc          string
	InitiatedByClient  bool
	InitiatedByServer  bool
	HasPointerRequest  bool
	HasArrayRequest    bool
	HasPointerResponse bool
	HasArrayResponse   bool
}

type MethodConfig struct {
	spec.Method
	MethodRawName      string
	Get                bool
	Post               bool
	Put                bool
	Delete             bool
	Options            bool
	HasBaseProps       bool
	HasHTMX            bool
	HasResp            bool
	HasReq             bool
	HasPage            bool
	HasPathInReq       bool
	RequiresSocket     bool
	RequiresPubSub     bool
	RequestType        string
	ResponseType       string
	HasPointerRequest  bool
	HasArrayRequest    bool
	HasPointerResponse bool
	HasArrayResponse   bool
	Request            string
	ReturnString       string
	ResponseString     string
	ReturnsPartial     bool
	ReturnsFullHTML    bool
	ReturnsPlainText   bool
	ReturnsNoOutput    bool
	ReturnsRedirect    bool
	RedirectURL        string
	HandlerName        string
	HasDoc             bool
	Doc                string
	LogicName          string
	LogicType          string
	LogicFunc          string
	IsSocket           bool
	IsDownload         bool
	TopicsFromClient   []Topic
	TopicsFromServer   []Topic
	SocketType         string
	IsPubSub           bool
	PubSubTopic        Topic
	Topic              Topic
	IsSSE              bool
	AssetGroup         string
}
