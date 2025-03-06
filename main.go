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
	// Start the client manager
	var manager = &ClientManager{
		clients:    make(map[*websocket.Conn]bool),
		register:   make(chan *websocket.Conn),
		unregister: make(chan *websocket.Conn),
		broadcast:  make(chan []byte),
	}

	go manager.run()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		handleWebSocket(manager, w, r)
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "index.html")
	})

	fmt.Println("Server starting on :8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// Allow all origins for this example
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

// ClientManager to handle multiple connections
type ClientManager struct {
	clients    map[*websocket.Conn]bool
	register   chan *websocket.Conn
	unregister chan *websocket.Conn
	broadcast  chan []byte
	mutex      sync.Mutex
}

func (m *ClientManager) run() {
	for {
		select {
		case conn := <-m.register:
			m.mutex.Lock()
			m.clients[conn] = true
			m.mutex.Unlock()
			fmt.Println("New client connected. Total clients:", len(m.clients))

		case conn := <-m.unregister:
			m.mutex.Lock()
			if _, ok := m.clients[conn]; ok {
				delete(m.clients, conn)
				conn.Close()
			}
			m.mutex.Unlock()
			fmt.Println("Client disconnected. Total clients:", len(m.clients))

		case message := <-m.broadcast:
			m.mutex.Lock()
			for conn := range m.clients {
				err := conn.WriteMessage(websocket.TextMessage, message)
				if err != nil {
					log.Println("Write error:", err)
					delete(m.clients, conn)
					conn.Close()
				}
			}
			m.mutex.Unlock()
		}
	}
}

func handleWebSocket(manager *ClientManager, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}

	// Register new connection
	manager.register <- conn

	// Clean up when connection closes
	defer func() {
		manager.unregister <- conn
	}()

	for {
		messageType, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			return
		}

		fmt.Printf("Received: %s\n", message)

		// Broadcast message to all clients
		if messageType == websocket.TextMessage {
			manager.broadcast <- message
		}
	}
}
