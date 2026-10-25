package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/minhhieu21193/orderflow/internal/httpapi"
)

func worker(id int, jobs <-chan int, wg *sync.WaitGroup) {
	// LỖ 1: đảm bảo Done() luôn được gọi khi hàm này thoát
	defer wg.Done()
	for job := range jobs {
		time.Sleep(500 * time.Millisecond)
		fmt.Println("worker", id, "processed job", job)
	}
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	// LỖ 2: khai báo channel jobs (kiểu int) và 1 sync.WaitGroup
	jobs := make(chan int)
	var wg sync.WaitGroup

	// LỖ 3: khởi động 3 worker, nhớ Add(1) đúng chỗ đúng lúc (xem lại bài trước nếu quên vì sao)
	for i := 1 ; i <= 3; i++ {
		wg.Add(1)
		go worker(i, jobs, &wg)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	// Readiness probe for the load balancer health check.
	mux.HandleFunc("GET /readyz", httpapi.Readyz)

	mux.HandleFunc("POST /jobs", func(w http.ResponseWriter, r *http.Request) {
		var body struct {
			Job int `json:"job"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		jobs <- body.Job
		// LỖ 4: gửi body.Job vào channel jobs — ĐỒNG BỘ, không dùng "go"
		// (đây là chỗ quyết định srv.Shutdown() có theo dõi đúng được không)

		w.WriteHeader(http.StatusAccepted)
	})

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: mux,
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		err := srv.ListenAndServe()
		if err != nil && err != http.ErrServerClosed {
			logger.Error("server error", "err", err)
		}
	}()

	<-ctx.Done()
	logger.Info("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// LỖ 5: gọi srv.Shutdown(shutdownCtx), bắt lỗi nếu có
	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("Shutdown server error", "err", err)
	}

	// LỖ 6: sau khi Shutdown xong — đóng channel jobs
	close(jobs)
	// LỖ 7: chờ tất cả worker xử lý hết job còn tồn trong hàng đợi (wg)
	wg.Wait()
	logger.Info("server stopped cleanly")
}