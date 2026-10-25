package httpapi

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestProbes(t *testing.T) {
	h := New(slog.New(slog.NewTextHandler(io.Discard, nil)))

	tests := []struct {
		method, path string
		wantStatus   int
		wantBody     string
	}{
		{http.MethodGet, "/healthz", http.StatusOK, `{"status":"ok"}` + "\n"},
		{http.MethodGet, "/readyz", http.StatusOK, `{"status":"ready"}` + "\n"},
		{http.MethodPost, "/readyz", http.StatusMethodNotAllowed, ""},
	}
	for _, tt := range tests {
		t.Run(tt.method+" "+tt.path, func(t *testing.T) {
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, httptest.NewRequest(tt.method, tt.path, nil))

			if rec.Code != tt.wantStatus {
				t.Fatalf("status = %d, want %d", rec.Code, tt.wantStatus)
			}
			if tt.wantBody != "" && rec.Body.String() != tt.wantBody {
				t.Fatalf("body = %q, want %q", rec.Body.String(), tt.wantBody)
			}
		})
	}
}
