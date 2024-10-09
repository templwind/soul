package installer

type InstallOptions struct {
	InstallType         string
	NameList            []string
	ProjectNamespace    string
	Framework           string
	Destination         string
	NewName             string
	ProcessedComponents map[string]bool
}

type Option func(*InstallOptions)

func WithInstallType(installType string) Option {
	return func(opts *InstallOptions) {
		opts.InstallType = installType
	}
}

func WithNameList(names []string) Option {
	return func(opts *InstallOptions) {
		opts.NameList = names
	}
}

func WithProjectNamespace(namespace string) Option {
	return func(opts *InstallOptions) {
		opts.ProjectNamespace = namespace
	}
}

func WithFramework(framework string) Option {
	return func(opts *InstallOptions) {
		opts.Framework = framework
	}
}

func WithDestination(destination string) Option {
	return func(opts *InstallOptions) {
		opts.Destination = destination
	}
}

func WithNewName(newName string) Option {
	return func(opts *InstallOptions) {
		opts.NewName = newName
	}
}

func WithProcessedComponents(components map[string]bool) Option {
	return func(opts *InstallOptions) {
		opts.ProcessedComponents = components
	}
}
