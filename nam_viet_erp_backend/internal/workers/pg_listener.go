package workers

import (
	"log"
	"os"
	"time"

	"github.com/lib/pq"
)

type Broadcaster interface {
	Broadcast(message []byte)
}

type PgListener struct {
	listener *pq.Listener
	bc       Broadcaster
}

func NewPgListener(bc Broadcaster) *PgListener {
	conninfo := os.Getenv("DATABASE_URL")
	if conninfo == "" {
		log.Println("DATABASE_URL not set, PgListener disabled")
		return nil
	}

	reportProblem := func(ev pq.ListenerEventType, err error) {
		if err != nil {
			log.Println("Listener error:", err.Error())
		}
	}

	listener := pq.NewListener(conninfo, 10*time.Second, time.Minute, reportProblem)
	return &PgListener{
		listener: listener,
		bc:       bc,
	}
}

func (l *PgListener) Start() {
	if l == nil || l.listener == nil {
		return
	}

	err := l.listener.Listen("clinic_queue_updates")
	if err != nil {
		log.Println("Failed to listen to clinic_queue_updates:", err)
		return
	}
	log.Println("Listening for PostgreSQL notifications on 'clinic_queue_updates'...")

	go func() {
		for {
			select {
			case n := <-l.listener.Notify:
				if n != nil {
					log.Printf("Received Notification on %s: %s", n.Channel, n.Extra)
					// Broadcast to all WS clients
					l.bc.Broadcast([]byte(n.Extra))
				}
			case <-time.After(90 * time.Second):
				// Check connection
				go l.listener.Ping()
			}
		}
	}()
}
