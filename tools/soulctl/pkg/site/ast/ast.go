package ast

// Define the node types
const (
	NodeTypeStruct    = "struct"
	NodeTypeServer    = "@server"
	NodeTypeService   = "service"
	NodeTypeHandler   = "@handler"
	NodeTypeMethod    = "method"
	NodeTypePage      = "@page"
	NodeTypeDoc       = "@doc"
	NodeTypeAttribute = "attribute"
	NodeTypeMenus     = "@menus"
	NodeTypeMenu      = "@menu"
	NodeTypeModules   = "@modules"
	NodeTypeModule    = "module"
)

// BaseNode represents a base AST node with a generic type.
type BaseNode struct {
	Type     string
	Name     string
	Children []BaseNode
	Attrs    map[string]interface{}
}

// StructField represents a field in a struct.
type StructField struct {
	Name string
	Type string
	Tags string
}

// StructNode represents a custom struct.
type StructNode struct {
	BaseNode
	Fields []StructField
}

// ServerNode represents a server block with its services.
type ServerNode struct {
	BaseNode
	Services []ServiceNode
}

// ServiceNode represents a service with its handlers.
type ServiceNode struct {
	BaseNode
	Handlers []HandlerNode
}

// HandlerNode represents a handler in a service.
type MethodNode struct {
	BaseNode
	Method         string
	Route          string
	Request        string
	RequestType    interface{}
	Response       string
	ResponseType   interface{}
	Page           *PageNode
	Doc            *DocNode
	IsStatic       bool
	IsSocket       bool
	SocketNode     *SocketNode
	ReturnsPartial bool
}

type SocketNode struct {
	BaseNode
	Method string
	Route  string
	Topics []TopicNode
}

type TopicNode struct {
	BaseNode
	Topic             string
	InitiatedByClient bool
	RequestType       interface{}
	ResponseType      interface{}
}

// HandlerNode represents a handler in a service with multiple method definitions.
type HandlerNode struct {
	BaseNode
	Methods []MethodNode
}

// PageNode represents a page in a service.
type PageNode struct {
	BaseNode
}

// DocNode represents a doc block in a handler.
type DocNode struct {
	BaseNode
}

// MenuItem represents an item in a menu.
type MenuItem struct {
	Title string
	URL   string
	Icon  string
}

// MenusNode represents 1 or more menus.
type MenusNode struct {
	BaseNode
	Menus []MenuNode
}

// MenuNode represents a menu with its items.
type MenuNode struct {
	BaseNode
	Items []MenuItem
}

// ModulesNode represents one or more modules.
type ModulesNode struct {
	BaseNode
	Modules []ModuleNode
}

// ModuleNode represents a module with its configuration.
type ModuleNode struct {
	BaseNode
	Source string
	Prefix string
}

// SiteAST represents the entire Abstract Syntax Tree.
type SiteAST struct {
	Name    string
	Structs []StructNode
	Servers []ServerNode
	Menus   []MenusNode
	Modules []ModuleNode
}

// NewBaseNode creates a new base node.
func NewBaseNode(nodeType, name string) BaseNode {
	return BaseNode{
		Type:     nodeType,
		Name:     name,
		Children: []BaseNode{},
		Attrs:    map[string]interface{}{},
	}
}

// NewDocNode creates a new doc node.
func NewDocNode(attrs map[string]interface{}) *DocNode {
	return &DocNode{
		BaseNode: BaseNode{
			Type:  NodeTypeDoc,
			Name:  "doc",
			Attrs: attrs,
		},
	}
}

// NewPageNode creates a new page node.
func NewPageNode(attrs map[string]interface{}) *PageNode {
	return &PageNode{
		BaseNode: BaseNode{
			Type:  NodeTypePage,
			Name:  "page",
			Attrs: attrs,
		},
	}
}

// NewServerNode creates a new server node.
func NewServerNode(attrs map[string]interface{}) *ServerNode {
	return &ServerNode{
		BaseNode: BaseNode{
			Type:  NodeTypeServer,
			Name:  "server",
			Attrs: attrs,
		},
		Services: []ServiceNode{},
	}
}

// NewServiceNode creates a new service node.
func NewServiceNode(name string) *ServiceNode {
	return &ServiceNode{
		BaseNode: BaseNode{
			Type: NodeTypeService,
			Name: name,
		},
		Handlers: []HandlerNode{},
	}
}

// NewMenusNode creates a new menus node.
func NewMenusNode(name string) *MenusNode {
	return &MenusNode{
		BaseNode: BaseNode{
			Type: NodeTypeMenu,
			Name: name,
		},
		Menus: []MenuNode{},
	}
}

// NewMenuNode creates a new menu node.
func NewMenuNode(name string) *MenuNode {
	return &MenuNode{
		BaseNode: BaseNode{
			Type: NodeTypeMenu,
			Name: name,
		},
		Items: []MenuItem{},
	}
}

// NewModuleNode creates a new module node.
func NewModuleNode(name interface{}, attr map[string]interface{}) *ModuleNode {
	return &ModuleNode{
		BaseNode: BaseNode{
			Type:  NodeTypeModule,
			Name:  name.(string),
			Attrs: attr,
		},
	}
}

// NewHandlerNode creates a new handler node with default empty values.
func NewHandlerNode(name string) *HandlerNode {
	return &HandlerNode{
		BaseNode: BaseNode{
			Type:     NodeTypeHandler,
			Name:     name,
			Children: []BaseNode{},
			Attrs:    map[string]interface{}{},
		},
		Methods: []MethodNode{},
	}
}

// NewMethodNode creates a new method node with default empty values.
func NewMethodNode(method, route string, requestType, responseType interface{}) MethodNode {
	return MethodNode{
		Method:       method,
		Route:        route,
		RequestType:  requestType,
		ResponseType: responseType,
	}
}

func NewSocketNode(method, route string, topics []TopicNode) *SocketNode {
	return &SocketNode{
		BaseNode: BaseNode{
			Type: NodeTypeMethod,
			Name: method,
		},
		Method: method,
		Route:  route,
		Topics: topics,
	}
}

func NewTopicNode(topic string, requestType, responseType interface{}, initiatedByClient bool) TopicNode {
	return TopicNode{
		BaseNode: BaseNode{
			Type: NodeTypeMethod,
			Name: topic,
		},
		RequestType:       requestType,
		ResponseType:      responseType,
		InitiatedByClient: initiatedByClient,
		Topic:             topic,
	}
}
