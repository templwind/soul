package lexer

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
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
	IMPORT
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
	AT_GET_METHOD
	AT_POST_METHOD
	AT_PUT_METHOD
	AT_DELETE_METHOD
	AT_PATCH_METHOD
	AT_MODULE
	AT_SUB_TOPIC
)

// Lexer represents a lexical scanner
type Lexer struct {
	scanner *bufio.Scanner
}

// NewLexer initializes a new lexer with import resolution
func NewLexer(filename string) (*Lexer, error) {
	fullContent, err := resolveImports(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve imports: %w", err)
	}
	return &Lexer{scanner: bufio.NewScanner(strings.NewReader(fullContent))}, nil
}

// resolveImports reads a file and resolves its import statements, returning a merged content string
func resolveImports(filename string) (string, error) {
	var contentBuilder strings.Builder

	// Helper function to process a file and append its content
	var processFile func(string) error
	processFile = func(filePath string) error {
		file, err := os.Open(filePath)
		if err != nil {
			return fmt.Errorf("failed to open file %s: %w", filePath, err)
		}
		defer file.Close()

		scanner := bufio.NewScanner(file)
		importRegex := regexp.MustCompile(`^\s*import\s+"(.+\.api)"`)

		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())

			// Check for import statements
			if match := importRegex.FindStringSubmatch(line); len(match) > 1 {
				importFile := match[1]
				importPath := filepath.Join(filepath.Dir(filePath), importFile)
				if err := processFile(importPath); err != nil {
					return fmt.Errorf("failed to process import '%s': %w", importFile, err)
				}
			} else {
				contentBuilder.WriteString(line + "\n")
			}
		}

		return scanner.Err()
	}

	// Start processing from the root file
	if err := processFile(filename); err != nil {
		return "", err
	}

	return contentBuilder.String(), nil
}

// NextToken returns the next token from the merged content
func (l *Lexer) NextToken() Token {
	for l.scanner.Scan() {
		line := strings.TrimSpace(l.scanner.Text())
		if line == "" {
			continue
		}

		// Skip comments
		if strings.HasPrefix(line, "//") {
			continue
		}

		tokenized := l.tokenizeLine(line)
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
		return Token{Type: COMMENT, Literal: line}
	case strings.HasPrefix(line, "import"):
		return Token{Type: IMPORT, Literal: l.cleanPrefix(line, "import")}
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
	case strings.HasPrefix(line, "sub"):
		return Token{Type: AT_SUB_TOPIC, Literal: l.cleanPrefix(line, "sub")}
	case strings.HasPrefix(line, "@menus"):
		return Token{Type: AT_MENUS, Literal: l.cleanPrefix(line, "@menus")}
	case strings.HasPrefix(line, "@module"):
		return Token{Type: AT_MODULE, Literal: l.cleanPrefix(line, "@module")}
	case strings.HasPrefix(line, "service"):
		return Token{Type: AT_SERVICE, Literal: l.cleanPrefix(line, "service")}
	case strings.Contains(line, ":") && !strings.Contains(line, "`") && !strings.Contains(line, "/"):
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
