package parser

import (
	"fmt"
	"reflect"
	"regexp"
	"strconv"
	"strings"

	"github.com/mitchellh/mapstructure"
	"github.com/templwind/soul/tools/soul/pkg/site/ast"
	"github.com/templwind/soul/tools/soul/pkg/site/lexer"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
)

// Parser represents a parser
type Parser struct {
	lexer     *lexer.Lexer
	curToken  lexer.Token
	peekToken lexer.Token
	siteAST   ast.SiteAST
}

// NewParser initializes a new parser
func NewParser(filename string) (*Parser, error) {
	lex, err := lexer.NewLexer(filename)
	if err != nil {
		return nil, err
	}
	p := &Parser{lexer: lex}
	p.nextToken()
	p.nextToken() // read two tokens, so curToken and peekToken are both set
	return p, nil
}

// nextToken advances to the next token
func (p *Parser) nextToken() {
	p.curToken = p.peekToken
	p.peekToken = p.lexer.NextToken()
}

// Parse returns the parsed AST
func (p *Parser) Parse() ast.SiteAST {
	p.siteAST = ast.SiteAST{}
	p.siteAST.Menus = make(map[string][]ast.MenuEntry)

	for p.curToken.Type != lexer.EOF {
		// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
		switch p.curToken.Type {
		case lexer.AT_TYPE:
			p.siteAST.Structs = append(p.siteAST.Structs, p.parseStruct())
		case lexer.AT_SERVER:
			p.siteAST.Servers = append(p.siteAST.Servers, p.parseServer())
		case lexer.AT_MODULE:
			p.siteAST.Modules = append(p.siteAST.Modules, p.parseModule())
		}
		p.nextToken()
	}

	return p.siteAST
}

func (p *Parser) parseStruct() ast.StructNode {
	node := ast.StructNode{
		BaseNode: ast.NewBaseNode(ast.NodeTypeStruct, p.curToken.Literal),
		Fields:   []ast.StructField{},
	}

	p.nextToken() // advance
	for p.curToken.Type != lexer.CLOSE_BRACE {
		field := p.parseStructField()
		node.Fields = append(node.Fields, field)
		p.nextToken()
	}
	return node
}

func (p *Parser) parseStructField() ast.StructField {
	parts := strings.Fields(p.curToken.Literal)
	if len(parts) < 2 {
		if len(parts) == 1 { // Handle embedded structs
			return ast.StructField{
				Name: parts[0],
				Type: parts[0],
				Tags: "",
			}
		}
		return ast.StructField{}
	}
	name := parts[0]
	fieldType := parts[1]
	tags := ""
	if len(parts) > 2 {
		tags = strings.Join(parts[2:], " ")
	}
	return ast.StructField{
		Name: name,
		Type: fieldType,
		Tags: tags,
	}
}

func (p *Parser) parseServer() ast.ServerNode {
	serverNode := ast.NewServerNode(p.parseAttributes())

	// fmt.Println("STARTING SERVER TOKEN", p.curToken.Literal, p.curToken.Type)

	for p.curToken.Type != lexer.CLOSE_BRACE {
		// fmt.Println("Parsing server", p.curToken.Literal, p.curToken.Type)
		if p.curToken.Type == lexer.AT_SERVICE {
			serverNode.Services = append(serverNode.Services, p.parseService(serverNode))
			// fmt.Println("Parsing server", serverNode)
			// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
		}
	}
	return *serverNode
}

func (p *Parser) parseService(serverNode *ast.ServerNode) ast.ServiceNode {
	node := ast.NewServiceNode(p.curToken.Literal)
	p.nextToken() // skip 'service'
	// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
	for p.curToken.Type == lexer.AT_HANDLER {
		node.Handlers = append(node.Handlers, p.parseHandler(serverNode))
	}
	return *node
}

func (p *Parser) parseHandler(serverNode *ast.ServerNode) ast.HandlerNode {
	name := p.curToken.Literal
	// fmt.Println("NAME", name)
	handler := ast.HandlerNode{}
	handler.Name = name
	handler.Type = ast.NodeTypeHandler
	p.nextToken()

	var prefix string
	if ok := serverNode.Attrs["prefix"]; ok != nil {
		prefix = serverNode.Attrs["prefix"].(string)

	}

	activeMenuEntries := make(map[string][]*ast.MenuEntry)
	activeMethod := ast.MethodNode{}
	methods := []ast.MethodNode{}
	for p.curToken.Type == lexer.AT_PAGE ||
		p.curToken.Type == lexer.AT_DOC ||
		p.curToken.Type == lexer.AT_MENUS ||
		p.curToken.Type == lexer.AT_GET_METHOD ||
		p.curToken.Type == lexer.AT_POST_METHOD ||
		p.curToken.Type == lexer.AT_PUT_METHOD ||
		p.curToken.Type == lexer.AT_DELETE_METHOD ||
		p.curToken.Type == lexer.AT_PATCH_METHOD ||
		p.curToken.Type == lexer.AT_SUB_TOPIC {

		if p.curToken.Type == lexer.AT_PAGE {
			// fmt.Println("PAGE", p.curToken.Literal, p.peekToken.Literal, p.curToken.Type)
			activeMethod.Page = p.parsePage()
			continue
		} else if p.curToken.Type == lexer.AT_DOC {
			// fmt.Println("DOC", p.curToken.Literal, p.curToken.Type)
			activeMethod.Doc = p.parseDoc()
			continue
		} else if p.curToken.Type == lexer.AT_MENUS {
			// fmt.Println("MENUS", p.curToken.Literal, p.curToken.Type)
			activeMenuEntries = p.parseMenus()
			continue
		} else if p.curToken.Type == lexer.AT_MENUS ||
			p.curToken.Type == lexer.AT_GET_METHOD ||
			p.curToken.Type == lexer.AT_POST_METHOD ||
			p.curToken.Type == lexer.AT_PUT_METHOD ||
			p.curToken.Type == lexer.AT_DELETE_METHOD ||
			p.curToken.Type == lexer.AT_PATCH_METHOD ||
			p.curToken.Type == lexer.AT_SUB_TOPIC {

			p.parseMethod(&activeMethod)
			methods = append(methods, activeMethod)

			// fmt.Println("ACTIVE ENTRIES", activeMenuEntries)
			for name, activeEntries := range activeMenuEntries {
				entries := p.siteAST.Menus[name]
				for _, entry := range activeEntries {
					url := strings.ReplaceAll(fmt.Sprintf("%s%s", prefix, activeMethod.Route), "//", "/")
					// strip the trailing slash
					url = strings.TrimSuffix(url, "/")
					entry.URL = url
					if entry.Title == "" && activeMethod.Page != nil && activeMethod.Page.Attrs["title"] != nil {
						entry.Title = activeMethod.Page.Attrs["title"].(string)
					}

					// fmt.Println("ENTRY", name, entry.URL, entry.Title, entry.Weight)

					p.siteAST.Menus[name] = append(entries, *entry)

					// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
				}
			}

			// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)

			// RESET THE ACTIVE METHOD AND MENU ENTRIES
			activeMethod = ast.MethodNode{}
			activeMenuEntries = make(map[string][]*ast.MenuEntry)
		}
		p.nextToken()
	}

	if methods != nil {
		handler.Methods = methods
	}

	return handler
}

func (p *Parser) parseMethod(method *ast.MethodNode) {
	// fmt.Println("METHOD", p.curToken.Literal, p.curToken.Type)
	switch p.curToken.Type {
	case lexer.AT_GET_METHOD:
		method.Method = "GET"
	case lexer.AT_POST_METHOD:
		method.Method = "POST"
	case lexer.AT_PUT_METHOD:
		method.Method = "PUT"
	case lexer.AT_DELETE_METHOD:
		method.Method = "DELETE"
	case lexer.AT_PATCH_METHOD:
		method.Method = "PATCH"
	case lexer.AT_SUB_TOPIC:
		method.Method = "SUB"
		method.IsPubSub = true
	default:
		return
	}

	literal := strings.Replace(p.curToken.Literal, "(", " (", -1)
	parts := strings.Fields(literal)
	// fmt.Println("PARTS", parts)

	state := "modifier"
	method.BaseNode = ast.NewBaseNode(ast.NodeTypeMethod, method.Method)

	isModifier := func(part string) bool {
		return strings.EqualFold(part, "static") ||
			strings.EqualFold(part, "static-embed") ||
			strings.EqualFold(part, "socket") ||
			strings.EqualFold(part, "sse") ||
			strings.EqualFold(part, "video") ||
			strings.EqualFold(part, "audio") ||
			strings.EqualFold(part, "file")
	}

	cleanType := func(part string) string {
		return strings.NewReplacer("(", "", ")", "").Replace(part)
	}

	for _, part := range parts {
		if state == "modifier" {
			state = "route"
			part := strings.ToLower(part)
			if isModifier(part) {
				switch part {
				case "static", "static-embed":
					if method.Method == "GET" {
						method.IsStatic = true
						if strings.EqualFold(part, "static-embed") {
							method.IsStaticEmbed = true
						}
						// Remove the base path portion to isolate potential rewrite paths
						paths := strings.TrimSpace(strings.Replace(p.curToken.Literal, part, "", 1))
						// Split into path segments to check if a rewrite path exists
						pathSegments := strings.Fields(paths)
						if len(pathSegments) > 1 {
							// If a rewrite path exists, set StaticPathRewrite with the second path onward
							method.StaticRouteRewrite = strings.TrimSpace(pathSegments[1])
						}

						continue
					} else {
						panic("Static paths (get static /path) can only be used with a GET method")
					}
				case "socket":
					if method.Method == "GET" {
						method.IsSocket = true
						continue
					} else {
						panic("Socket paths (get socket /path) can only be used with a GET method")
					}
				case "sse":
					if method.Method == "GET" || method.Method == "POST" {
						method.IsSSE = true
						continue
					} else {
						panic("SSE paths (get|post sse /path) can only be used with GET or POST methods")
					}

				case "video":
					if method.Method == "GET" {
						method.IsVideoStream = true
						continue
					} else {
						panic("Video paths (get video /path) can only be used with a GET method")
					}
				case "audio":
					if method.Method == "GET" {
						method.IsAudioStream = true
						continue
					} else {
						panic("Audio paths (get audio /path) can only be used with a GET method")
					}
				case "file":
					if method.Method == "POST" {
						method.IsUploadFile = true
						continue
					} else {
						panic("File paths (post file /path) can only be used with a POST method")
					}
				}
			}
		}

		if state == "route" {
			state = "requestObject"
			method.Route = part
			continue
		}

		if state == "requestObject" {
			state = "responseObject"
			if strings.Contains(part, "(") {

				if strings.Contains(part, "()") || strings.EqualFold(part, "returns") {
					continue
				} else {
					method.Request = cleanType(part)
					method.HasRequestType = true
					if strings.Contains(method.Request, "[]") {
						method.RequestType = spec.NewArrayType(
							spec.NewStructType(strings.TrimSpace(strings.Replace(method.Request, "[]", "", -1)), nil, nil, nil),
						)
					} else {
						method.RequestType = spec.NewStructType(strings.TrimSpace(strings.Replace(method.Request, "[]", "", -1)), nil, nil, nil)
					}
					state = "responseObject"
				}
			}
			continue
		}

		if state == "responseObject" {
			if strings.EqualFold(part, "returns") {
				state = "responseObject"
				continue
			}
			if strings.Contains(part, "(") {
				method.Response = cleanType(part)
				method.ReturnsJson = true
				method.HasResponseType = true
				if strings.Contains(method.Response, "[]") {
					method.ResponseType = spec.NewArrayType(
						spec.NewStructType(strings.TrimSpace(strings.Replace(method.Response, "[]", "", -1)), nil, nil, nil),
					)
				} else {
					method.ResponseType = spec.NewStructType(strings.TrimSpace(strings.Replace(method.Response, "[]", "", -1)), nil, nil, nil)
				}
			}
			if strings.Contains(part, "partial") {
				method.ReturnsPartial = true
			}
		}
	}

	// if the method has a socket modifier
	if method.IsSocket {
		p.parseSocketMethod(method)
	}

	if method.IsPubSub {
		p.parseSubTopic(method)
	}

	if method.Method == "GET" &&
		(!method.IsSocket &&
			!method.IsSSE &&
			!method.IsVideoStream &&
			!method.IsAudioStream &&
			!method.ReturnsJson &&
			!method.IsPubSub) {
		method.IsFullHTMLPage = true
	}

	// allow the method to be a full html page if it returns partial
	// this enables refreshes of the page
	if method.Method == "GET" &&
		method.ReturnsPartial {
		method.IsFullHTMLPage = true
	}

	if !method.IsFullHTMLPage &&
		!method.ReturnsPartial &&
		!method.ReturnsJson &&
		!method.IsSocket &&
		!method.IsPubSub &&
		!method.IsSSE &&
		!method.IsVideoStream &&
		!method.IsAudioStream {
		method.NoOutput = true
	}

	// json, _ := json.MarshalIndent(method, "", "  ")
	// fmt.Println(string(json))
}

func (p *Parser) parseBidirectionalString(input string) (requestTopic string, requestType interface{}, responseTopic string, responseType interface{}, err error) {
	parts := strings.Split(input, "<<>>")
	if len(parts) != 2 {
		return "", nil, "", nil, fmt.Errorf("invalid input format")
	}

	request := strings.TrimSpace(parts[0])
	response := strings.TrimSpace(parts[1])

	requestParts := strings.SplitN(request, " ", 2)
	if len(requestParts) != 2 {
		return "", nil, "", nil, fmt.Errorf("invalid request format")
	}
	requestTopic = requestParts[0]
	requestTypeStr := strings.Trim(requestParts[1], "()")

	responseParts := strings.SplitN(response, " ", 2)
	if len(responseParts) != 2 {
		return "", nil, "", nil, fmt.Errorf("invalid response format")
	}
	responseTopic = responseParts[0]
	responseTypeStr := strings.Trim(responseParts[1], "()")

	// Convert request type to structured type
	if strings.Contains(requestTypeStr, "[]") {
		requestTypeStr = strings.Replace(requestTypeStr, "[]", "", -1)
		requestType = spec.NewArrayType(
			spec.NewStructType(strings.TrimSpace(requestTypeStr), nil, nil, nil),
		)
	} else {
		requestType = spec.NewStructType(strings.TrimSpace(requestTypeStr), nil, nil, nil)
	}

	// Convert response type to structured type
	if strings.Contains(responseTypeStr, "[]") {
		responseTypeStr = strings.Replace(responseTypeStr, "[]", "", -1)
		responseType = spec.NewArrayType(
			spec.NewStructType(strings.TrimSpace(responseTypeStr), nil, nil, nil),
		)
	} else {
		responseType = spec.NewStructType(strings.TrimSpace(responseTypeStr), nil, nil, nil)
	}

	return
}

func (p *Parser) parsePubSubString(input string) (subscriptionTopic string, requestType interface{}, publishTopic string, responseType interface{}, err error) {
	parts := strings.Split(input, " pub ")
	if len(parts) != 2 {
		return "", nil, "", nil, fmt.Errorf("invalid input format")
	}

	subscription := strings.TrimSpace(parts[0])
	publication := strings.TrimSpace(parts[1])

	// Parse subscription part
	subParts := strings.SplitN(subscription, " ", 2)
	if len(subParts) != 2 {
		return "", nil, "", nil, fmt.Errorf("invalid subscription format")
	}

	subscriptionTopic = subParts[0]
	requestTypeStr := strings.Trim(subParts[1], "()")

	// Parse publication part
	pubParts := strings.SplitN(publication, " ", 2)
	if len(pubParts) != 2 {
		return "", nil, "", nil, fmt.Errorf("invalid publication format")
	}
	publishTopic = pubParts[0]
	responseTypeStr := strings.Trim(pubParts[1], "()")

	// Convert request type to structured type
	if strings.Contains(requestTypeStr, "[]") {
		requestTypeStr = strings.Replace(requestTypeStr, "[]", "", -1)
		requestType = spec.NewArrayType(
			spec.NewStructType(strings.TrimSpace(requestTypeStr), nil, nil, nil),
		)
	} else {
		requestType = spec.NewStructType(strings.TrimSpace(requestTypeStr), nil, nil, nil)
	}

	// Convert response type to structured type
	if strings.Contains(responseTypeStr, "[]") {
		responseTypeStr = strings.Replace(responseTypeStr, "[]", "", -1)
		responseType = spec.NewArrayType(
			spec.NewStructType(strings.TrimSpace(responseTypeStr), nil, nil, nil),
		)
	} else {
		responseType = spec.NewStructType(strings.TrimSpace(responseTypeStr), nil, nil, nil)
	}

	return
}

// parse pubsub methods
func (p *Parser) parseSubTopic(method *ast.MethodNode) {
	// these are the patterns
	// a subscribe without a resulting publish
	// sub subscribed.topic (TopicRequest)
	// a subscribe with a resulting publish
	// sub subscribed.topic  (TopicRequest) pub published.topic (TopicResponse)

	topic := ast.TopicNode{}

	// fmt.Println("SOCKET METHOD", p.curToken.Literal, p.curToken.Type)

	// for p.curToken.Type != lexer.CLOSE_BRACE {
	// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
	// Split the line into parts by spaces
	literal := p.curToken.Literal
	literal = strings.ReplaceAll(literal, "(", " (")
	re := regexp.MustCompile(`\s+`)
	literal = re.ReplaceAllString(literal, " ")

	// check if the topic has an ending publication
	// sub subscribed.topic  (TopicRequest) pub published.topic (TopicResponse)

	if strings.Contains(literal, " pub ") {
		// let's parse the request and response types
		requestTopic, requestType, responseTopic, responseType, err := p.parsePubSubString(literal)
		if err != nil {
			fmt.Println("ERROR: Cannot parse pubsub method", err)
		}

		// fmt.Println("requestTopic", requestTopic)
		// fmt.Println("responseTopic", responseTopic)
		// fmt.Println("requestType", requestType)
		// fmt.Println("responseType", responseType)
		// p.nextToken()

		topic = ast.NewTopicNode(requestTopic, responseTopic, requestType, responseType, true)
	} else {
		// Handle the case: sub subscribed.topic (TopicRequest)
		parts := strings.SplitN(literal, " ", 3)
		if len(parts) != 2 {
			fmt.Println("ERROR: Invalid sub topic format")
			p.nextToken()
			return
		}

		topicStr := parts[0]
		requestTypeStr := strings.Trim(parts[1], "()")
		var requestType interface{}

		if strings.Contains(requestTypeStr, "[]") {
			requestTypeStr = strings.Replace(requestTypeStr, "[]", "", -1)
			requestType = spec.NewArrayType(
				spec.NewStructType(strings.TrimSpace(requestTypeStr), nil, nil, nil),
			)
		} else {
			requestType = spec.NewStructType(strings.TrimSpace(requestTypeStr), nil, nil, nil)
		}

		topic = ast.NewTopicNode(topicStr, "", requestType, nil, true)

		// topics = append(topics, ast.NewTopicNode(topic, "", requestType, nil, true))
	}

	// add the topics to the method
	// make sure the topics are unique
	// uniqueTopics := []ast.TopicNode{}
	// topicMap := make(map[string]bool)
	// for _, topic := range topics {
	// 	key := fmt.Sprintf("%s-%v", topic.Topic, topic.InitiatedByClient)
	// 	if !topicMap[key] {
	// 		uniqueTopics = append(uniqueTopics, topic)
	// 		topicMap[key] = true
	// 	} else {
	// 		fmt.Println("ERROR: Duplicate topic", key)
	// 	}
	// }
	// os.Exit(0)
	method.PubSubNode = ast.NewPubSubtNode(method.Method, method.Route, topic)
}

// parse web socket methods
func (p *Parser) parseSocketMethod(method *ast.MethodNode) {
	topics := []ast.TopicNode{}

	// fmt.Println("SOCKET METHOD", p.curToken.Literal, p.curToken.Type)

	p.nextToken()
	for p.curToken.Type != lexer.CLOSE_PAREN {
		// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
		// Split the line into parts by spaces
		literal := p.curToken.Literal
		literal = strings.ReplaceAll(literal, "(", " (")
		re := regexp.MustCompile(`\s+`)
		literal = re.ReplaceAllString(literal, " ")

		// check if the topic is bidirectional
		// client:write-magnet (WriteMagnetRequest) <<>> server:write-magnet-line (WriteMagnetResponse)

		bidirectional := strings.Contains(literal, "<<>>")
		if bidirectional {
			// let's parse the request and response types
			// this is our string client:write-magnet (WriteMagnetRequest) <<>> server:write-magnet-line (WriteMagnetResponse)
			// we need to split the string into the topic and the types

			requestTopic, requestType, responseTopic, responseType, err := p.parseBidirectionalString(literal)
			if err != nil {
				fmt.Println("ERROR: Cannot parse bidirectional socket method", err)
			}

			topics = append(topics, ast.NewTopicNode(requestTopic, responseTopic, requestType, responseType, true))
			topics = append(topics, ast.NewTopicNode(responseTopic, "", responseType, requestType, false))

		} else {
			// split into sections
			isClientInitiated := strings.Contains(literal, ">>")
			// replace the >> and << with \u00A7
			literal = strings.ReplaceAll(literal, "<<", "\u00A7")
			literal = strings.ReplaceAll(literal, ">>", "\u00A7")

			sections := strings.Split(literal, "\u00A7")

			var (
				topic        string
				requestType  interface{}
				responseType interface{}
			)

			requestParts := strings.Split(strings.TrimSpace(sections[0]), " ")
			if len(requestParts) > 0 {
				topic = strings.TrimSpace(requestParts[0])
			}
			if len(requestParts) > 1 {
				rType := strings.Replace(requestParts[1], "(", "", -1)
				rType = strings.Replace(rType, ")", "", -1)
				if strings.Contains(rType, "[]") {
					rType = strings.Replace(rType, "[]", "", -1)
					requestType = spec.NewArrayType(
						spec.NewStructType(strings.TrimSpace(rType), nil, nil, nil),
					)
				} else {
					requestType = spec.NewStructType(strings.TrimSpace(rType), nil, nil, nil)
				}
			}

			responseParts := strings.Split(strings.TrimSpace(sections[1]), " ")
			// fmt.Println("RESPONSE PARTS", responseParts)
			if len(responseParts) > 0 {
				rType := strings.Replace(responseParts[0], "(", "", -1)
				rType = strings.Replace(rType, ")", "", -1)
				if strings.Contains(rType, "[]") {
					rType = strings.Replace(rType, "[]", "", -1)
					responseType = spec.NewArrayType(
						spec.NewStructType(strings.TrimSpace(rType), nil, nil, nil),
					)
				} else {
					responseType = spec.NewStructType(strings.TrimSpace(rType), nil, nil, nil)
				}
			}

			topics = append(topics, ast.NewTopicNode(topic, topic, requestType, responseType, isClientInitiated))
		}
		p.nextToken()
	}

	// add the topics to the method
	// make sure the topics are unique
	uniqueTopics := []ast.TopicNode{}
	topicMap := make(map[string]bool)
	for _, topic := range topics {
		key := fmt.Sprintf("%s-%v", topic.Topic, topic.InitiatedByClient)
		if !topicMap[key] {
			uniqueTopics = append(uniqueTopics, topic)
			topicMap[key] = true
		} else {
			fmt.Println("ERROR: Duplicate topic", key)
		}
	}
	method.SocketNode = ast.NewSocketNode(method.Method, method.Route, uniqueTopics)
}

func (p *Parser) parsePage() *ast.PageNode {
	// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
	attrs := p.parseAttributes()
	return ast.NewPageNode(attrs)
}

func (p *Parser) parseDoc() *ast.DocNode {
	attrs := p.parseAttributes()
	return ast.NewDocNode(attrs)
}

// parseAttributes parses attributes including nested ones
func (p *Parser) parseAttributes() map[string]interface{} {
	attrs := make(map[string]interface{})
	p.nextToken()
	for p.curToken.Type != lexer.CLOSE_PAREN {
		// Check for key-value pairs
		parts := strings.SplitN(p.curToken.Literal, ":", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])
			attrs[key] = value
		} else {
			// Check for nested attributes
			parts = strings.SplitN(p.curToken.Literal, "(", 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				nestedAttrs := p.parseAttributes()
				attrs[key] = nestedAttrs
				continue
			}
		}
		p.nextToken()
	}
	p.nextToken() // skip ')'
	return attrs
}

func convertAttributes(attrs map[string]interface{}, targetStruct interface{}) map[string]interface{} {
	converted := make(map[string]interface{})
	targetType := reflect.TypeOf(targetStruct)

	for key, value := range attrs {
		// Find the corresponding struct field by matching the mapstructure tag
		for i := 0; i < targetType.NumField(); i++ {
			field := targetType.Field(i)
			tag := field.Tag.Get("mapstructure")
			if strings.HasPrefix(tag, key) {
				switch field.Type.Kind() {
				case reflect.Int:
					if strVal, ok := value.(string); ok {
						if intVal, err := strconv.Atoi(strVal); err == nil {
							converted[key] = intVal
						} else {
							fmt.Println("ERROR converting", key, ":", err)
						}
					} else {
						converted[key] = value
					}
				case reflect.Bool:
					if strVal, ok := value.(string); ok {
						if boolVal, err := strconv.ParseBool(strVal); err == nil {
							converted[key] = boolVal
						} else {
							fmt.Println("ERROR converting", key, ":", err)
						}
					} else {
						converted[key] = value
					}
				case reflect.String:
					converted[key] = value
				default:
					converted[key] = value
				}
				break
			}
		}
	}

	return converted
}

func (p *Parser) parseMenus() map[string][]*ast.MenuEntry {
	active := make(map[string][]*ast.MenuEntry)

	attrs := p.parseAttributes()
	for name, obj := range attrs {
		if _, ok := p.siteAST.Menus[name]; !ok {
			p.siteAST.Menus[name] = []ast.MenuEntry{}
			active[name] = []*ast.MenuEntry{}
		}

		// Ensure obj is a map
		if objMap, ok := obj.(map[string]interface{}); ok {
			// Convert attributes using reflection
			convertedAttrs := convertAttributes(objMap, ast.MenuEntry{})
			// fmt.Println("CONVERTED", convertedAttrs)
			entry := ast.MenuEntry{}
			if err := mapstructure.Decode(convertedAttrs, &entry); err == nil {
				active[name] = append(active[name], &entry)
			} else {
				fmt.Println("ERROR decoding:", err)
			}
		} else {
			// fmt.Println("ERROR: attributes are not a map[string]interface{}")
			panic("ERROR: menu attributes are not formatted correctly: " + fmt.Sprintf("%v", obj))
		}
	}
	return active
}

func (p *Parser) parseModule() ast.ModuleNode {
	attrs := make(map[string]interface{})
	for p.curToken.Type != lexer.CLOSE_PAREN {
		parts := strings.SplitN(p.curToken.Literal, ":", 2)
		if len(parts) == 2 {
			attrs[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
		}
		p.nextToken()
	}

	// fmt.Println("MODULE ATTRS", attrs)
	node := ast.NewModuleNode(attrs["name"], attrs)
	node.Attrs = attrs
	node.Source = attrs["source"].(string)
	node.Prefix = attrs["prefix"].(string)
	return *node
}
