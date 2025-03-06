package main

import (
	"fmt"
	"github.com/gorilla/websocket"
	"log"
	"net/http"
	"shortener/shortener"
	"shortener/storage"
	"sync"
)

func startProducer(ch chan string, wg *sync.WaitGroup) {
	defer wg.Done()
	defer close(ch)
	for i := 0; i < 100; i++ {
		ch <- fmt.Sprintf("url-%v", i)
	}
}

func startConsumer(ch chan string, wg *sync.WaitGroup, short shortener.Shortener) {
	defer wg.Done()
	for url := range ch {
		shortUrl, err := short.Shorten(url)
		if err != nil {
			fmt.Println("Error shortening url:", url, err)
			continue
		}
		fmt.Println(shortUrl)
	}
}

func RunShortener() error {
	table, err := storage.NewRedisStorage("localhost:6379", "", 0)
	if err != nil {
		fmt.Println(err)
		return err
	}
	short := shortener.Shortener{Table: table}
	wg := &sync.WaitGroup{}
	ch := make(chan string)
	consumerAmount := 10
	wg.Add(consumerAmount)
	for i := 0; i < consumerAmount; i++ {
		go startConsumer(ch, wg, short)
	}
	wg.Add(1)
	go startProducer(ch, wg)
	wg.Wait()
	return nil
}

func main() {
	RunWebServer()
}

// Socket example

func RunWebServer() {
	// Set up WebSocket route
	http.HandleFunc("/ws", handleWebSocket)

	// Serve static files (HTML) from current directory
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "index.html")
	})

	// Start server
	fmt.Println("Server starting on :8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

// WebSocket upgrader
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// Allow all origins for this example
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

// WebSocket connection handler
func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	// Upgrade HTTP connection to WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer func(conn *websocket.Conn) {
		err := conn.Close()
		if err != nil {
			log.Println("Close error:", err)
		}
	}(conn)

	fmt.Println("Client connected")

	// Main loop to handle messages
	for {
		// Read message from client
		messageType, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			break
		}

		// Print received message
		fmt.Printf("Received: %s\n", message)

		// Echo message back to client
		err = conn.WriteMessage(messageType, message)
		if err != nil {
			log.Println("Write error:", err)
			break
		}
	}

	fmt.Println("Client disconnected")
}
