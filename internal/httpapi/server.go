// Package httpapi wires the HTTP routes and handlers for the orderflow API.
package httpapi

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"time"
)

// New builds the http.Handler for the API. Keeping routing in one function
// makes the full surface of the service readable at a glance — as orderflow
// grows (orders, health, metrics), every route is registered here.
//
// The patterns use Go 1.22's method-aware ServeMux: "GET /healthz" only matches
// GET, so a POST to the same path returns 405 automatically. No third-party
// router needed yet.
func New(logger *slog.Logger) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", handleHealthz)

	// Middleware wraps the whole mux so every request is logged once, centrally.
	return requestLogger(logger, mux)
}

// handleHealthz is a liveness probe: it answers "the process is up and serving".
// It deliberately checks nothing external — readiness (DB, Redis reachable)
// will be a separate /readyz endpoint once those dependencies exist.
func handleHealthz(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// requestLogger logs one line per request with method, path, status and latency.
// It captures the status code by wrapping ResponseWriter, since the standard
// ResponseWriter gives no way to read back what status was written.
func requestLogger(logger *slog.Logger, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}

		next.ServeHTTP(rec, r)

		logger.Info("request",
			slog.String("method", r.Method),
			slog.String("path", r.URL.Path),
			slog.Int("status", rec.status),
			slog.Duration("latency", time.Since(start)),
		)
	})
}

// statusRecorder remembers the status code written to the response so the
// logging middleware can report it.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

// writeJSON is the single place responses are serialized, so content-type and
// encoding are handled consistently across every handler.
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
