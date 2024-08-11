package conf

import "embed"

type (
	// Option defines the method to customize the config options.
	Option func(opt *options)

	options struct {
		env   bool
		hasFS bool
		fs    embed.FS
	}
)

// UseEnv customizes the config to use environment variables.
func UseEnv() Option {
	return func(opt *options) {
		opt.env = true
	}
}

func UseFS(fs embed.FS) Option {
	return func(opt *options) {
		opt.hasFS = true
		opt.fs = fs
	}
}
