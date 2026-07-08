// Command api is the orderflow HTTP API entrypoint.
//
// The shape here — load config, build a logger, start the server, block until a
// signal, then shut down cleanly — is the same skeleton every Go service uses.
// The graceful-shutdown path (SIGTERM -> stop accepting -> drain in-flight ->
// exit) is exactly what Kubernetes relies on when it terminates a pod, so it's
// worth getting right on day one.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"

	"github.com/minhhieu21193/orderflow/internal/config"
	"github.com/minhhieu21193/orderflow/internal/httpapi"
)

func main() {
	// run holds all fallible startup logic so main stays a thin wrapper that
	// turns an error into a non-zero exit code — a common Go pattern.
	if err := run(); err != nil {
		slog.Error("startup failed", slog.Any("error", err))
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: cfg.LogLevel,
	}))

	// NotifyContext gives a context that is cancelled the moment SIGINT or
	// SIGTERM arrives. Everything downstream watches this ctx to know when to
	// stop. stop() releases the signal handler when we're done.
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	srv := &http.Server{
		Addr:    ":" + strconv.Itoa(cfg.Port),
		Handler: httpapi.New(logger),
	}

	// ListenAndServe blocks, so it runs in its own goroutine and reports any
	// startup error back through a channel.
	serverErr := make(chan error, 1)
	go func() {
		logger.Info("server starting", slog.Int("port", cfg.Port))
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			serverErr <- err
		}
	}()

	// Block until either the server fails to run or a shutdown signal arrives.
	select {
	case err := <-serverErr:
		return err
	case <-ctx.Done():
		logger.Info("shutdown signal received, draining")
	}

	// Give in-flight requests up to ShutdownTimeout to finish before forcing
	// the process down. Shutdown stops accepting new connections immediately.
	shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		return err
	}

	logger.Info("shutdown complete")
	return nil
}
