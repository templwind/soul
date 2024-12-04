package cache

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/redis/go-redis/v9"
)

var (
	ErrInvalidDelInput = errors.New("invalid input type for Del operation")
	ErrNilClient       = errors.New("redis client is nil")
	ErrEmptyInput      = errors.New("empty input provided")
	ErrNilDB           = errors.New("database connection is nil")
)

// Config holds Redis configuration
type Config struct {
	RedisURL         string
	Password         string
	DB               int
	ConnectTimeout   time.Duration
	OperationTimeout time.Duration
	MaxRetries       int
	MinRetryBackoff  time.Duration
	MaxRetryBackoff  time.Duration
}

// OptFunc defines the signature for an option function
type OptFunc func(*Config)

// WithRedisURL sets the Redis URL
func WithRedisURL(url string) OptFunc {
	return func(c *Config) {
		c.RedisURL = url
	}
}

// WithPassword sets the Redis password
func WithPassword(password string) OptFunc {
	return func(c *Config) {
		c.Password = password
	}
}

// WithDB sets the Redis database number
func WithDB(db int) OptFunc {
	return func(c *Config) {
		c.DB = db
	}
}

// defaultConfig returns the default configuration
func defaultConfig() *Config {
	return &Config{
		RedisURL:         "localhost:6379",
		ConnectTimeout:   5 * time.Second,
		OperationTimeout: 2 * time.Second,
		MaxRetries:       3,
		MinRetryBackoff:  100 * time.Millisecond,
		MaxRetryBackoff:  2 * time.Second,
	}
}

// Persistent contains the persistent Redis and DB connections
type Persistent struct {
	client *redis.Client
	db     *sqlx.DB
	config *Config
}

// MustConnect creates a new Persistent instance with default options
func MustConnect(db *sqlx.DB, opts ...OptFunc) *Persistent {
	options := withOptions(defaultConfig(), opts...)
	return NewWithOptions(db, options)
}

// withOptions builds the options with the given opts
func withOptions(defaultOpts *Config, opts ...OptFunc) *Config {
	for _, opt := range opts {
		opt(defaultOpts)
	}
	return defaultOpts
}

// NewWithOptions creates a new Persistent instance with the given options
func NewWithOptions(db *sqlx.DB, cfg *Config) *Persistent {
	if db == nil {
		panic("database connection is nil")
	}

	client, err := connect(cfg)
	if err != nil {
		panic("Failed to connect to Redis: " + err.Error())
	}

	p := &Persistent{
		client: client,
		db:     db,
		config: cfg,
	}

	// Start connection health check
	go p.ensureConnection()

	return p
}

// connect establishes a new Redis connection
func connect(cfg *Config) (*redis.Client, error) {
	client := redis.NewClient(&redis.Options{
		Addr:            cfg.RedisURL,
		Password:        cfg.Password,
		DB:              cfg.DB,
		DialTimeout:     cfg.ConnectTimeout,
		MaxRetries:      cfg.MaxRetries,
		MinRetryBackoff: cfg.MinRetryBackoff,
		MaxRetryBackoff: cfg.MaxRetryBackoff,
	})

	ctx, cancel := context.WithTimeout(context.Background(), cfg.ConnectTimeout)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to redis: %w", err)
	}

	return client, nil
}

// reconnect attempts to re-establish the Redis connection with exponential backoff
func (p *Persistent) reconnect() error {
	const maxBackoff = 5 * time.Minute
	baseDelay := 500 * time.Millisecond

	for attempts := 0; ; attempts++ {
		client, err := connect(p.config)
		if err == nil {
			p.client = client
			return nil
		}

		if attempts > 0 {
			backoff := time.Duration(math.Pow(2, float64(attempts))) * baseDelay
			if backoff > maxBackoff {
				backoff = maxBackoff
			}
			time.Sleep(backoff)
		}
	}
}

// ensureConnection continuously checks the health of the Redis connection
func (p *Persistent) ensureConnection() {
	for {
		ctx, cancel := context.WithTimeout(context.Background(), p.config.ConnectTimeout)
		if err := p.client.Ping(ctx).Err(); err != nil {
			p.reconnect()
		}
		cancel()
		time.Sleep(1 * time.Minute)
	}
}

func (p *Persistent) Get(ctx context.Context, key string, dest interface{}, query func() error) error {
	val, err := p.client.Get(ctx, key).Result()
	if err == nil {
		return json.Unmarshal([]byte(val), dest)
	}

	if err != redis.Nil {
		return fmt.Errorf("cache error: %w", err)
	}

	if err := query(); err != nil {
		return fmt.Errorf("database query error: %w", err)
	}

	data, err := json.Marshal(dest)
	if err != nil {
		return fmt.Errorf("marshal error: %w", err)
	}

	if err := p.client.Set(ctx, key, data, 24*time.Hour).Err(); err != nil {
		return fmt.Errorf("cache set error: %w", err)
	}

	return nil
}

func (p *Persistent) Set(ctx context.Context, key string, ttl time.Duration, value interface{}, fn func() error) error {
	if fn != nil {
		if err := fn(); err != nil {
			return fmt.Errorf("database operation error: %w", err)
		}
	}

	data, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("marshal error: %w", err)
	}

	if err := p.client.Set(ctx, key, data, ttl).Err(); err != nil {
		return fmt.Errorf("cache set error: %w", err)
	}

	return nil
}

func (p *Persistent) Del(ctx context.Context, input interface{}) error {
	switch v := input.(type) {
	case string:
		return p.client.Del(ctx, v).Err()
	case []string:
		if len(v) == 0 {
			return ErrEmptyInput
		}
		return p.client.Del(ctx, v...).Err()
	case func(*redis.Client) error:
		return v(p.client)
	default:
		return ErrInvalidDelInput
	}
}

func (p *Persistent) DelByPattern(ctx context.Context, pattern string) error {
	iter := p.client.Scan(ctx, 0, pattern, 0).Iterator()
	for iter.Next(ctx) {
		if err := p.client.Del(ctx, iter.Val()).Err(); err != nil {
			return err
		}
	}
	return iter.Err()
}

func (p *Persistent) GetDB() *sqlx.DB {
	return p.db
}

func (p *Persistent) GetRedis() *redis.Client {
	return p.client
}

func (p *Persistent) Close() error {
	if p.client != nil {
		if err := p.client.Close(); err != nil {
			return fmt.Errorf("redis close error: %w", err)
		}
	}
	return nil
}
