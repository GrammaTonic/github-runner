package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	runnerName    = getEnvOrDefault("RUNNER_NAME", "unknown")
	runnerType    = getEnvOrDefault("RUNNER_TYPE", "standard")
	runnerVersion = "2.329.0"

	// Gauges
	runnerStatus = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "github_runner_status",
			Help: "Runner online status (1=online, 0=offline)",
		},
		[]string{"runner_name", "runner_type"},
	)

	runnerUptime = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "github_runner_uptime_seconds",
			Help: "Runner uptime in seconds",
		},
		[]string{"runner_name", "runner_type"},
	)

	runnerInfo = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "github_runner_info",
			Help: "Runner metadata",
		},
		[]string{"runner_name", "runner_type", "version"},
	)

	// Counters
	jobsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "github_runner_jobs_total",
			Help: "Total jobs executed by status",
		},
		[]string{"runner_name", "runner_type", "status"},
	)

	// Histograms
	jobDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "github_runner_job_duration_seconds",
			Help:    "Job duration in seconds",
			Buckets: prometheus.ExponentialBuckets(10, 2, 10), // 10s to ~2.8h
		},
		[]string{"runner_name", "runner_type", "status"},
	)

	cacheHitRate = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "github_runner_cache_hit_rate",
			Help: "Cache hit rate (0.0 to 1.0)",
		},
		[]string{"runner_name", "runner_type", "cache_type"},
	)
)

func init() {
	// Register metrics
	prometheus.MustRegister(runnerStatus)
	prometheus.MustRegister(runnerUptime)
	prometheus.MustRegister(runnerInfo)
	prometheus.MustRegister(jobsTotal)
	prometheus.MustRegister(jobDuration)
	prometheus.MustRegister(cacheHitRate)
}

func main() {
	log.Printf("Starting metrics exporter for runner: %s (type: %s)", runnerName, runnerType)

	// Set initial status
	runnerStatus.WithLabelValues(runnerName, runnerType).Set(1)
	runnerInfo.WithLabelValues(runnerName, runnerType, runnerVersion).Set(1)

	// Start metrics updater
	go updateMetrics()

	// Start HTTP server
	http.Handle("/metrics", promhttp.Handler())
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	log.Printf("Metrics endpoint listening on :9091")
	if err := http.ListenAndServe(":9091", nil); err != nil {
		log.Fatalf("Failed to start metrics server: %v", err)
	}
}

func updateMetrics() {
	startTime := time.Now()
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		// Update uptime
		uptime := time.Since(startTime).Seconds()
		runnerUptime.WithLabelValues(runnerName, runnerType).Set(uptime)

		// TODO: Add logic to read job logs and update job metrics
		// This would integrate with the runner's job execution logs
		// For now, we just update uptime to demonstrate the exporter works
	}
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
