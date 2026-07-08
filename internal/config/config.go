// Package config loads runtime configuration from the environment.
//
// Config comes from env vars (12-factor style) so the same binary runs
// unchanged in local, docker-compose, and Kubernetes — only the environment
// differs. Defaults keep `go run .` working with zero setup.
package config

import (
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"time"
)

// Config holds all runtime configuration for the API.
type Config struct {
	Port            int
	LogLevel        slog.Level
	ShutdownTimeout time.Duration
}

// Load reads configuration from the environment, applying defaults for any
// value that is unset. It returns an error only when a value is set but
// malformed — an unset var is never an error, it just uses the default.
func Load() (Config, error) {
	cfg := Config{
		Port:            8080,
		LogLevel:        slog.LevelInfo,
		ShutdownTimeout: 10 * time.Second,
	}

	if v := os.Getenv("PORT"); v != "" {
		p, err := strconv.Atoi(v)
		if err != nil {
			return Config{}, fmt.Errorf("invalid PORT %q: %w", v, err)
		}
		cfg.Port = p
	}

	if v := os.Getenv("LOG_LEVEL"); v != "" {
		var lvl slog.Level
		if err := lvl.UnmarshalText([]byte(v)); err != nil {
			return Config{}, fmt.Errorf("invalid LOG_LEVEL %q: %w", v, err)
		}
		cfg.LogLevel = lvl
	}

	return cfg, nil
}
