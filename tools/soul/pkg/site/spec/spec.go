package spec

import (
	"fmt"

	"github.com/templwind/soul/tools/soul/pkg/site/ast"
)

// Define the constants used in the spec
const RoutePrefixKey = "prefix"

// Define the types used in the spec
type (
	// Doc represents documentation strings
	Doc []string

	// Annotation defines key-value properties for annotations
	Annotation struct {
		Properties map[string]interface{}
	}

	// SiteSpec describes a Site file
	SiteSpec struct {
		Name    string
		Types   []Type
		Servers []Server
		Modules []Module
		Menus   map[string][]MenuEntry
	}

	// Module describes an external module
	Module struct {
		Name   string
		Source string
		Prefix string
		Attr   map[string]interface{}
	}

	// Server describes a server block with its services
	Server struct {
		Annotation Annotation
		Services   []Service
	}

	// Service describes a Site service with its handlers
	Service struct {
		Name     string
		Handlers []Handler
	}

	Method struct {
		Method             string
		Prefix             string
		Route              string
		StaticRouteRewrite string
		Request            string
		RequestType        Type
		Response           string
		ResponseType       Type
		Page               *Page
		Doc                *DocNode
		HandlerDoc         Doc
		HandlerComment     Doc
		DocAnnotation      Annotation
		SocketNode         *SocketNode
		PubSubNode         *PubSubNode
		HasRequestType     bool
		HasResponseType    bool
		HasPage            bool
		ReturnsPartial     bool
		ReturnsPlainText   bool
		ReturnsJson        bool
		IsStatic           bool
		IsStaticEmbed      bool
		IsSocket           bool
		IsDownload         bool
		IsPubSub           bool
		IsSSE              bool
		IsVideoStream      bool
		IsAudioStream      bool
		IsFullHTMLPage     bool
		NoOutput           bool
	}

	SocketNode struct {
		Method string
		Route  string
		Topics []TopicNode
	}

	PubSubNode struct {
		Method string
		Route  string
		Topic  TopicNode
	}

	TopicNode struct {
		Topic             string
		ResponseTopic     string
		InitiatedByClient bool
		RequestType       Type
		ResponseType      Type
	}

	// Handler describes a Site handler
	Handler struct {
		Name    string
		Methods []Method
	}

	// Page represents a page in a handler
	Page struct {
		Annotation Annotation
	}

	// DocNode represents a doc block in a handler
	DocNode struct {
		Annotation Annotation
	}

	// Type defines the types used in the Site spec
	Type interface {
		GetName() string
		GetFields() []Field
		GetComments() []string
		GetDocuments() []string
	}

	// StructType describes a structure type
	StructType struct {
		Name    string
		Fields  []Field
		Docs    Doc
		Comment Doc
	}

	// Field describes the field of a structure
	Field struct {
		Name    string
		Type    string
		Tag     string
		Comment string
		Docs    Doc
	}

	// PrimitiveType describes a primitive type
	PrimitiveType struct {
		Name string
	}

	// MapType describes a map type
	MapType struct {
		Name  string
		Key   string
		Value Type
	}

	// ArrayType describes an array type
	ArrayType struct {
		Name  string
		Value Type
	}

	// PointerType describes a pointer type
	PointerType struct {
		Name string
		Type Type
	}

	// InterfaceType describes an interface type
	InterfaceType struct {
		Name string
	}

	MenuEntry struct {
		Title       string
		Weight      int
		Icon        string
		URL         string
		Subtitle    string
		MobileTitle string
		Lead        string
		InMobile    bool
		IsAtEnd     bool
		IsDropdown  bool
		HxDisable   bool
		Parent      string
		Children    []MenuEntry
	}
)

// NewAnnotation creates a new annotation
func NewAnnotation(properties map[string]interface{}) Annotation {
	return Annotation{
		Properties: properties,
	}
}

// NewDocNode creates a new doc node
func NewDocNode(annotation Annotation) *DocNode {
	return &DocNode{
		Annotation: annotation,
	}
}

// NewPage creates a new page node
func NewPage(annotation Annotation) *Page {
	return &Page{
		Annotation: annotation,
	}
}

// NewServer creates a new server node
func NewServer(annotation Annotation) *Server {
	return &Server{
		Annotation: annotation,
		Services:   []Service{},
	}
}

// NewService creates a new service node
func NewService(name string) *Service {
	return &Service{
		Name:     name,
		Handlers: []Handler{},
	}
}

// NewModule creates a new module node
func NewModule(name string, attr map[string]interface{}) Module {
	return Module{
		Name: name,
		Attr: attr,
	}
}

// NewHandler creates a new handler node
func NewHandler(name string, methods []Method) *Handler {
	return &Handler{
		Name:    name,
		Methods: methods,
	}
}

// NewMethod creates a new method for a handler.
// m, buildPage(m.Page), buildDoc(m.Doc), buildSocketNode(m.SocketNode)
func NewMethod(m ast.MethodNode,
	page *Page,
	doc *DocNode,
	socketNode *SocketNode,
	pubSubNode *PubSubNode) Method {
	var (
		reqType Type
		resType Type
	)

	if m.RequestType != nil {
		reqType = m.RequestType.(Type)
	}

	if m.ResponseType != nil {
		resType = m.ResponseType.(Type)
	}

	return Method{
		Method:             m.Method,
		Prefix:             m.Prefix,
		Route:              m.Route,
		StaticRouteRewrite: m.StaticRouteRewrite,
		RequestType:        reqType,
		ResponseType:       resType,
		Page:               page,
		Doc:                doc,
		IsStatic:           m.IsStatic,
		IsStaticEmbed:      m.IsStaticEmbed,
		IsSocket:           m.IsSocket,
		IsDownload:         m.IsDownload,
		IsPubSub:           m.IsPubSub,
		SocketNode:         socketNode,
		PubSubNode:         pubSubNode,
		ReturnsPartial:     m.ReturnsPartial,
		ReturnsPlainText:   m.ReturnsPlainText,
		HasRequestType:     m.HasRequestType,
		HasResponseType:    m.HasResponseType,
		HasPage:            m.HasPage,
		ReturnsJson:        m.ReturnsJson,
		IsSSE:              m.IsSSE,
		IsVideoStream:      m.IsVideoStream,
		IsAudioStream:      m.IsAudioStream,
		IsFullHTMLPage:     m.IsFullHTMLPage,
		NoOutput:           m.NoOutput,
	}
}

func NewSocketNode(method, route string, topicNodes []ast.TopicNode) *SocketNode {
	topics := []TopicNode{}
	for _, topic := range topicNodes {
		topics = append(topics, NewTopicNode(topic.Topic, topic.ResponseTopic, topic.InitiatedByClient, topic.RequestType, topic.ResponseType))
	}

	return &SocketNode{
		Method: method,
		Route:  route,
		Topics: topics,
	}
}

func NewPubSubNode(method, route string, topicNode ast.TopicNode) *PubSubNode {
	topic := NewTopicNode(topicNode.Topic, topicNode.ResponseTopic, topicNode.InitiatedByClient, topicNode.RequestType, topicNode.ResponseType)

	return &PubSubNode{
		Method: method,
		Route:  route,
		Topic:  topic,
	}
}

func NewTopicNode(topic, responseTopic string, initiatedByClient bool, requestType, responseType interface{}) TopicNode {
	var (
		reqType Type
		resType Type
	)

	if requestType != nil {
		reqType = requestType.(Type)
	}

	if responseType != nil {
		resType = responseType.(Type)
	}

	return TopicNode{
		Topic:             topic,
		ResponseTopic:     responseTopic,
		InitiatedByClient: initiatedByClient,
		RequestType:       reqType,
		ResponseType:      resType,
	}
}

func NewMenuEntry(entry ast.MenuEntry) MenuEntry {
	return MenuEntry{
		Title:       entry.Title,
		Weight:      entry.Weight,
		Icon:        entry.Icon,
		URL:         entry.URL,
		Subtitle:    entry.Subtitle,
		MobileTitle: entry.MobileTitle,
		Lead:        entry.Lead,
		InMobile:    entry.InMobile,
		IsAtEnd:     entry.IsAtEnd,
		IsDropdown:  entry.IsDropdown,
		HxDisable:   entry.HxDisable,
		Parent:      entry.Parent,
	}
}

func NewMenuEntries(entries []ast.MenuEntry) []MenuEntry {
	menuEntries := []MenuEntry{}
	for _, entry := range entries {
		menuEntries = append(menuEntries, NewMenuEntry(entry))
	}

	return menuEntries
}

// NewStructType creates a new struct type
func NewStructType(name string, fields []Field, docs, comment Doc) *StructType {
	return &StructType{
		Name:    name,
		Fields:  fields,
		Docs:    docs,
		Comment: comment,
	}
}

// NewPrimitiveType creates a new primitive type
func NewPrimitiveType(name string) *PrimitiveType {
	return &PrimitiveType{
		Name: name,
	}
}

// NewMapType creates a new map type
func NewMapType(key string, value Type) *MapType {
	return &MapType{
		Key:   key,
		Value: value,
	}
}

// NewArrayType creates a new array type
func NewArrayType(value Type) *ArrayType {
	return &ArrayType{
		Value: value,
	}
}

// NewPointerType creates a new pointer type
func NewPointerType(t Type) *PointerType {
	return &PointerType{
		Type: t,
	}
}

// NewInterfaceType creates a new interface type
func NewInterfaceType(name string) *InterfaceType {
	return &InterfaceType{
		Name: name,
	}
}

// annotation methods
// GetAnnotation returns the value by specified key from @server
func (s Server) GetAnnotation(key string) string {
	if s.Annotation.Properties == nil {
		// fmt.Printf("No properties found for key: %s\n", key)
		return ""
	}

	// fmt.Println("Properties: ", s.Annotation.Properties)

	value, ok := s.Annotation.Properties[key]
	if !ok {
		// fmt.Printf("No value found for key: %s\n", key)
		return ""
	}

	strValue, ok := value.(string)
	if !ok {
		// fmt.Printf("Value for key %s is not a string: %v\n", key, value)
		return ""
	}

	return strValue
}

// Methods to implement the Type interface for StructType
func (t *StructType) GetName() string {
	return t.Name
}

func (t *StructType) GetComments() []string {
	return []string(t.Comment)
}

func (t *StructType) GetDocuments() []string {
	return []string(t.Docs)
}

func (t *StructType) GetFields() []Field {
	return t.Fields
}

// Methods to implement the Type interface for Field
func (t *Field) GetName() string {
	return t.Name
}

func (t *Field) GetComments() []string {
	return []string{t.Comment}
}

func (t *Field) GetDocuments() []string {
	return []string(t.Docs)
}

func (t *Field) GetFields() []Field {
	return nil
}

// Methods to implement the Type interface for PrimitiveType
func (t *PrimitiveType) GetName() string {
	return t.Name
}

func (t *PrimitiveType) GetComments() []string {
	return nil
}

func (t *PrimitiveType) GetDocuments() []string {
	return nil
}

func (t *PrimitiveType) GetFields() []Field {
	return nil
}

// Methods to implement the Type interface for MapType
func (t *MapType) GetName() string {
	return fmt.Sprintf("map[%s]%s", t.Key, t.Value.GetName())
}

func (t *MapType) GetComments() []string {
	return nil
}

func (t *MapType) GetDocuments() []string {
	return nil
}

func (t *MapType) GetFields() []Field {
	return nil
}

// Methods to implement the Type interface for ArrayType
func (t *ArrayType) GetName() string {
	return fmt.Sprintf("[]%s", t.Value.GetName())
}

func (t *ArrayType) GetComments() []string {
	return nil
}

func (t *ArrayType) GetDocuments() []string {
	return nil
}

func (t *ArrayType) GetFields() []Field {
	return nil
}

// Methods to implement the Type interface for PointerType
func (t *PointerType) GetName() string {
	return fmt.Sprintf("*%s", t.Type.GetName())
}

func (t *PointerType) GetComments() []string {
	return nil
}

func (t *PointerType) GetDocuments() []string {
	return nil
}

func (t *PointerType) GetFields() []Field {
	return nil
}

// Methods to implement the Type interface for InterfaceType
func (t *InterfaceType) GetName() string {
	return t.Name
}

func (t *InterfaceType) GetComments() []string {
	return nil
}

func (t *InterfaceType) GetDocuments() []string {
	return nil
}

func (t *InterfaceType) GetFields() []Field {
	return nil
}

// Methods to implement the Type interface for Method
func (m *Method) GetName() string {
	return m.Method
}

func (m *Method) GetComments() []string {
	return nil
}

func (m *Method) GetDocuments() []string {
	return nil
}

func (m *Method) GetFields() []Field {
	return nil
}

// Methods to implement the Type interface for TopicNode
func (m *TopicNode) GetName() string {
	return m.Topic
}

func (m *TopicNode) GetComments() []string {
	return nil
}

func (m *TopicNode) GetDocuments() []string {
	return nil
}

func (m *TopicNode) GetFields() []Field {
	return nil
}
