package spec

import (
	"fmt"

	"github.com/templwind/soul/tools/soul/pkg/site/ast"
)

func BuildSiteSpec(ast ast.SiteAST) *SiteSpec {
	var siteSpec SiteSpec
	for _, s := range ast.Structs {
		fields := make([]Field, len(s.Fields))
		for i, f := range s.Fields {
			fields[i] = Field{
				Name:    f.Name,
				Type:    f.Type,
				Tag:     f.Tags,
				Comment: "",
				Docs:    nil,
			}
		}
		siteSpec.Types = append(siteSpec.Types, NewStructType(s.Name, fields, nil, nil))
	}

	for _, m := range ast.Modules {
		siteSpec.Modules = append(siteSpec.Modules, NewModule(m.Name, m.Attrs))
	}

	for _, s := range ast.Servers {
		server := NewServer(NewAnnotation(s.Attrs))
		for _, srv := range s.Services {
			service := NewService(srv.Name)
			for _, h := range srv.Handlers {
				methods := make([]Method, 0)
				for _, m := range h.Methods {
					methods = append(methods,
						NewMethod(m,
							buildPage(m.Page),
							buildDoc(m.Doc),
							buildSocketNode(m.SocketNode),
							buildPubSubNode(m.PubSubNode),
						),
					)
				}

				handler := NewHandler(h.Name, methods)
				service.Handlers = append(service.Handlers, *handler)
			}
			server.Services = append(server.Services, *service)
		}
		siteSpec.Servers = append(siteSpec.Servers, *server)
	}

	siteSpec.Menus = make(map[string][]MenuEntry)
	for name, entries := range ast.Menus {
		entryMap := buildMenu(entries)
		// fmt.Println("EntryMap", name, entryMap)

		linkMenuEntries(entryMap)

		// Collect the structured menu entries
		var structuredEntries []MenuEntry
		for _, entry := range entryMap {
			// fmt.Println("Entry", entry.Title, entry.URL, entry.Parent)
			if entry.Parent == "" { // Only top-level entries
				structuredEntries = append(structuredEntries, *entry)
			}
		}

		// fmt.Println("Building menu", name, "with", len(structuredEntries), "entries")

		siteSpec.Menus[name] = structuredEntries
	}

	return &siteSpec
}

func buildMenu(entries []ast.MenuEntry) map[string]*MenuEntry {
	entryMap := make(map[string]*MenuEntry)

	for _, entry := range entries {
		menuEntry := NewMenuEntry(entry)
		entryMap[entry.URL] = &menuEntry
	}

	return entryMap
}

func linkMenuEntries(entryMap map[string]*MenuEntry) {
	for _, entry := range entryMap {
		if parentURL, ok := entryMap[entry.Parent]; ok {
			parentURL.Children = append(parentURL.Children, *entry)
		}
	}
}

func buildPage(page *ast.PageNode) *Page {
	if page == nil {
		return nil
	}
	return NewPage(NewAnnotation(page.Attrs))
}

func buildDoc(doc *ast.DocNode) *DocNode {
	if doc == nil {
		return nil
	}
	return NewDocNode(NewAnnotation(doc.Attrs))
}

func buildSocketNode(socketNode *ast.SocketNode) *SocketNode {
	if socketNode == nil {
		return nil
	}
	return NewSocketNode(socketNode.Method, socketNode.Route, socketNode.Topics)
}

func buildPubSubNode(pubSubNode *ast.PubSubNode) *PubSubNode {
	if pubSubNode == nil {
		return nil
	}
	return NewPubSubNode(pubSubNode.Method, pubSubNode.Route, pubSubNode.Topic)
}

func PrintSpec(siteSpec SiteSpec) {
	for _, t := range siteSpec.Types {
		fmt.Printf("Type: %s\n", t.GetName())
		for _, f := range t.(*StructType).Fields {
			fmt.Printf("  Field: %s %s %s\n", f.Name, f.Type, f.Tag)
		}
	}

	for _, m := range siteSpec.Modules {
		fmt.Printf("Module: %s\n", m.Name)
		for k, v := range m.Attr {
			fmt.Printf("  %s: %s\n", k, v)
		}
	}

	for _, s := range siteSpec.Servers {
		fmt.Printf("Server:\n")
		for _, srv := range s.Services {
			fmt.Printf("  Service: %s\n", srv.Name)
			for _, h := range srv.Handlers {
				fmt.Printf("    Handler: %s\n", h.Name)
				for _, m := range h.Methods {
					fmt.Printf("        Method: %s %s %s %s\n", m.Method, m.Route, m.RequestType, m.ResponseType)
				}
			}
		}
	}
}
