package lexer

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strings"
)

// TokenType represents the type of a token
type TokenType int

func ToTokenType(s string) TokenType {
	switch s {
	case "(":
		return OPEN_PAREN
	case ")":
		return CLOSE_PAREN
	case "{":
		return OPEN_BRACE
	case "}":
		return CLOSE_BRACE
	default:
		return ILLEGAL
	}
}

// Token represents a lexical token
type Token struct {
	Type    TokenType
	Literal string
}

// Token types
const (
	ILLEGAL TokenType = iota
	EOF
	IDENT
	COMMENT
	STRUCT_FIELD
	ATTRIBUTE
	OPEN_BRACE
	CLOSE_BRACE
	OPEN_PAREN
	CLOSE_PAREN
	STRING_LITERAL
	COLON
	AT_TYPE
	AT_SERVER
	AT_SERVICE
	AT_HANDLER
	AT_PAGE
	AT_DOC
	AT_MENUS
	AT_MENU
	AT_GET_METHOD
	AT_GET_STATIC_METHOD
	AT_GET_SOCKET_METHOD
	AT_POST_METHOD
	AT_PUT_METHOD
	AT_DELETE_METHOD
	AT_PATCH_METHOD
	AT_MODULE
)

// Lexer represents a lexical scanner
type Lexer struct {
	scanner *bufio.Scanner
}

// NewLexer initializes a new lexer
func NewLexer(filename string) (*Lexer, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	return &Lexer{scanner: bufio.NewScanner(file)}, nil
}

// NextToken returns the next token
func (l *Lexer) NextToken() Token {
	for l.scanner.Scan() {
		line := strings.TrimSpace(l.scanner.Text())
		if line == "" {
			continue
		}

		// for now, remove the comments
		if strings.HasPrefix(line, "//") {
			continue
		}

		tokenized := l.tokenizeLine(line)
		// fmt.Println("line: ", line, tokenized)
		return tokenized
	}
	if err := l.scanner.Err(); err != nil {
		return Token{Type: ILLEGAL, Literal: err.Error()}
	}
	return Token{Type: EOF, Literal: ""}
}

func (l *Lexer) tokenizeLine(line string) Token {
	switch {
	case line == "{":
		return Token{Type: OPEN_BRACE, Literal: "{"}
	case line == "}":
		return Token{Type: CLOSE_BRACE, Literal: "}"}
	case line == "(":
		return Token{Type: OPEN_PAREN, Literal: "("}
	case line == ")":
		return Token{Type: CLOSE_PAREN, Literal: ")"}
	case strings.HasPrefix(line, "//"):
		fmt.Println("COMMENT", line)
		return Token{Type: COMMENT, Literal: line}
	case strings.HasPrefix(line, "type"):
		return Token{Type: AT_TYPE, Literal: l.cleanPrefix(line, "type")}
	case strings.HasPrefix(line, "@server"):
		return Token{Type: AT_SERVER, Literal: l.cleanPrefix(line, "@server")}
	case strings.HasPrefix(line, "@page"):
		return Token{Type: AT_PAGE, Literal: l.cleanPrefix(line, "@page")}
	case strings.HasPrefix(line, "@doc"):
		return Token{Type: AT_DOC, Literal: l.cleanPrefix(line, "@doc")}
	case strings.HasPrefix(line, "@handler"):
		return Token{Type: AT_HANDLER, Literal: l.cleanPrefix(line, "@handler")}
	case strings.HasPrefix(line, "get static"):
		return Token{Type: AT_GET_STATIC_METHOD, Literal: l.cleanPrefix(line, "get static")}
	case strings.HasPrefix(line, "get socket"):
		return Token{Type: AT_GET_SOCKET_METHOD, Literal: l.cleanPrefix(line, "get socket")}
	case strings.HasPrefix(line, "get"):
		return Token{Type: AT_GET_METHOD, Literal: l.cleanPrefix(line, "get")}
	case strings.HasPrefix(line, "post"):
		return Token{Type: AT_POST_METHOD, Literal: l.cleanPrefix(line, "post")}
	case strings.HasPrefix(line, "put"):
		return Token{Type: AT_PUT_METHOD, Literal: l.cleanPrefix(line, "put")}
	case strings.HasPrefix(line, "delete"):
		return Token{Type: AT_DELETE_METHOD, Literal: l.cleanPrefix(line, "delete")}
	case strings.HasPrefix(line, "patch"):
		return Token{Type: AT_PATCH_METHOD, Literal: l.cleanPrefix(line, "patch")}
	case strings.HasPrefix(line, "@menus"):
		return Token{Type: AT_MENUS, Literal: l.cleanPrefix(line, "@menus")}
	case strings.HasPrefix(line, "menu"):
		return Token{Type: AT_MENU, Literal: l.cleanPrefix(line, "menu")}
	case strings.HasPrefix(line, "@module"):
		return Token{Type: AT_MODULE, Literal: l.cleanPrefix(line, "@module")}
	case strings.HasPrefix(line, "service"):
		return Token{Type: AT_SERVICE, Literal: l.cleanPrefix(line, "service")}
	// case strings.HasPrefix(line, "get") ||
	// 	strings.HasPrefix(line, "post") ||
	// 	strings.HasPrefix(line, "put") ||
	// 	strings.HasPrefix(line, "delete") ||
	// 	strings.HasPrefix(line, "patch") ||
	// 	strings.HasPrefix(line, "options") ||
	// 	strings.HasPrefix(line, "head") ||
	// 	strings.HasPrefix(line, "trace") ||
	// 	strings.HasPrefix(line, "connect"):
	// 	return Token{Type: AT_HANDLER, Literal: line}
	case strings.Contains(line, ":") &&
		!strings.Contains(line, "`") &&
		!strings.Contains(line, "/"):
		return Token{Type: ATTRIBUTE, Literal: line}
	case regexp.MustCompile(`^\w+:`).MatchString(line):
		return Token{Type: STRUCT_FIELD, Literal: line}
	default:
		return Token{Type: IDENT, Literal: line}
	}
}

func (l *Lexer) cleanPrefix(line, prefix string) string {
	line = strings.TrimPrefix(line, prefix)
	line = strings.TrimSuffix(line, "{")
	line = strings.TrimSuffix(line, "(")
	line = strings.TrimSpace(line)
	return line
}
