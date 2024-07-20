package parser

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/templwind/soul/tools/soulctl/pkg/site/ast"
	"github.com/templwind/soul/tools/soulctl/pkg/site/lexer"
	"github.com/templwind/soul/tools/soulctl/pkg/site/spec"
)

// Parser represents a parser
type Parser struct {
	lexer     *lexer.Lexer
	curToken  lexer.Token
	peekToken lexer.Token
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
	var astTree ast.SiteAST

	for p.curToken.Type != lexer.EOF {
		// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
		switch p.curToken.Type {
		case lexer.AT_TYPE:
			astTree.Structs = append(astTree.Structs, p.parseStruct())
		case lexer.AT_SERVER:
			astTree.Servers = append(astTree.Servers, p.parseServer())
		// case lexer.AT_MENUS:
		// 	astTree.Menus = append(astTree.Menus, p.parseMenus())
		case lexer.AT_MODULE:
			astTree.Modules = append(astTree.Modules, p.parseModule())
		}
		p.nextToken()
	}

	return astTree
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
	node := ast.NewServerNode(p.parseAttributes())

	// fmt.Println("STARTING SERVER TOKEN", p.curToken.Literal, p.curToken.Type)

	for p.curToken.Type != lexer.CLOSE_BRACE {
		// fmt.Println("Parsing server", p.curToken.Literal, p.curToken.Type)
		if p.curToken.Type == lexer.AT_SERVICE {
			node.Services = append(node.Services, p.parseService())
			// fmt.Println("Parsing server", node)
			// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
		}
	}
	return *node
}

func (p *Parser) parseService() ast.ServiceNode {
	node := ast.NewServiceNode(p.curToken.Literal)
	p.nextToken() // skip 'service'
	// fmt.Println("TOKEN", p.curToken.Literal, p.curToken.Type)
	for p.curToken.Type == lexer.AT_HANDLER {
		node.Handlers = append(node.Handlers, p.parseHandler())
	}
	return *node
}

func (p *Parser) parseHandler() ast.HandlerNode {
	name := p.curToken.Literal
	handler := ast.HandlerNode{}
	handler.Name = name
	handler.Type = ast.NodeTypeHandler
	p.nextToken()

	activeMethod := ast.MethodNode{}
	methods := []ast.MethodNode{}
	for p.curToken.Type == lexer.AT_GET_STATIC_METHOD ||
		p.curToken.Type == lexer.AT_GET_SOCKET_METHOD ||
		p.curToken.Type == lexer.AT_PAGE ||
		p.curToken.Type == lexer.AT_DOC ||
		p.curToken.Type == lexer.AT_GET_METHOD ||
		p.curToken.Type == lexer.AT_POST_METHOD ||
		p.curToken.Type == lexer.AT_PUT_METHOD ||
		p.curToken.Type == lexer.AT_DELETE_METHOD ||
		p.curToken.Type == lexer.AT_PATCH_METHOD {

		if p.curToken.Type == lexer.AT_PAGE {
			activeMethod.Page = p.parsePage()
			// fmt.Println("PAGE", p.curToken.Literal, p.peekToken.Literal, p.curToken.Type)
			continue
		} else if p.curToken.Type == lexer.AT_DOC {
			// fmt.Println("DOC", p.curToken.Literal, p.curToken.Type)
			activeMethod.Doc = p.parseDoc()
			continue
		} else if p.curToken.Type == lexer.AT_GET_STATIC_METHOD ||
			p.curToken.Type == lexer.AT_GET_SOCKET_METHOD ||
			p.curToken.Type == lexer.AT_GET_METHOD ||
			p.curToken.Type == lexer.AT_POST_METHOD ||
			p.curToken.Type == lexer.AT_PUT_METHOD ||
			p.curToken.Type == lexer.AT_DELETE_METHOD ||
			p.curToken.Type == lexer.AT_PATCH_METHOD {

			p.parseMethod(&activeMethod)
			methods = append(methods, activeMethod)
			activeMethod = ast.MethodNode{}
		}

		// fmt.Printf("METHODS %v\n", methods)

		// methods = append(methods, p.parseMethod())

		p.nextToken()
	}

	if methods != nil {
		handler.Methods = methods
	}

	return handler
}

func (p *Parser) parseMethod(method *ast.MethodNode) {
	switch p.curToken.Type {
	case lexer.AT_GET_STATIC_METHOD:
		method.Method = "GET"
		method.IsStatic = true
	case lexer.AT_GET_SOCKET_METHOD:
		method.Method = "GET"
		method.IsSocket = true
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
	default:
		return
	}

	literal := p.curToken.Literal
	literal = strings.ReplaceAll(literal, "(", " (")
	// use regex to replace all spaces with a single space
	re := regexp.MustCompile(`\s+`)
	literal = re.ReplaceAllString(literal, " ")
	// use regex to remove the word returns
	// post /forgot-password(ForgotPasswordRequest) returns (ForgotPasswordResponse)
	re = regexp.MustCompile(`\s+returns\s+`)
	literal = re.ReplaceAllString(literal, " ")

	parts := strings.Fields(literal)

	method.BaseNode = ast.NewBaseNode(ast.NodeTypeMethod, method.Method)
	method.Route = parts[0]

	if method.IsStatic {
		return
	}

	if method.IsSocket {
		if method.IsSocket {
			p.parseSocketMethod(method)
		}

		return
	}

	if len(parts) > 1 {
		method.Request = parts[1][1 : len(parts[1])-1]
		// method.RequestType = spec.NewStructType(method.Request, nil, nil, nil)
		if strings.Contains(method.Request, "[]") {
			method.RequestType = spec.NewArrayType(
				spec.NewStructType(strings.TrimSpace(strings.Replace(method.Request, "[]", "", -1)), nil, nil, nil),
			)
		} else {
			method.RequestType = spec.NewStructType(strings.TrimSpace(strings.Replace(method.Request, "[]", "", -1)), nil, nil, nil)
		}
	}

	if len(parts) > 2 {
		// is this an partial (HTML) response or a json response?
		// json has a response type wrapped in parens ()
		// ssr is a string literal word "partial"

		if strings.EqualFold(parts[2], "partial") {
			method.ReturnsPartial = true
			// fmt.Println("PARTS", parts[2])
			return
		}
		// it's a json response
		method.Response = parts[2][1 : len(parts[2])-1]
		if strings.Contains(method.Response, "[]") {
			method.ResponseType = spec.NewArrayType(
				spec.NewStructType(strings.TrimSpace(strings.Replace(method.Response, "[]", "", -1)), nil, nil, nil),
			)
		} else {
			method.ResponseType = spec.NewStructType(strings.TrimSpace(strings.Replace(method.Response, "[]", "", -1)), nil, nil, nil)
		}
	}
}

func (p *Parser) parseSocketMethod(method *ast.MethodNode) {
	topics := []ast.TopicNode{}

	p.nextToken()
	for p.curToken.Type != lexer.CLOSE_PAREN {
		// Split the line into parts by spaces
		literal := p.curToken.Literal
		literal = strings.ReplaceAll(literal, "(", " (")
		re := regexp.MustCompile(`\s+`)
		literal = re.ReplaceAllString(literal, " ")

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

		topics = append(topics, ast.NewTopicNode(topic, requestType, responseType, isClientInitiated))

		p.nextToken()
	}

	// add the topics to the method
	method.SocketNode = ast.NewSocketNode(method.Method, method.Route, topics)
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

func (p *Parser) skipBlock() {
	openBraces := 1
	for openBraces > 0 {
		p.nextToken()
		if p.curToken.Type == lexer.OPEN_BRACE {
			openBraces++
		} else if p.curToken.Type == lexer.CLOSE_BRACE {
			openBraces--
		}
	}
}

func (p *Parser) parseMenus() ast.MenusNode {
	node := ast.NewMenusNode(ast.NodeTypeMenus)
	for p.curToken.Type != lexer.CLOSE_PAREN {
		if p.curToken.Type == lexer.AT_MENU {
			node.Menus = append(node.Menus, p.parseMenu())
		} else {
			p.nextToken()
		}
	}
	return *node
}

func (p *Parser) parseMenu() ast.MenuNode {
	node := ast.NewMenuNode(ast.NodeTypeMenu)
	p.nextToken()
	for p.curToken.Type != lexer.CLOSE_BRACE {
		attrs := p.parseAttributes()
		fmt.Println("MENU ATTRS", attrs)
	}

	return *node
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
