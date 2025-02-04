package main

import (
	"fmt"
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

func main() {
	table := &storage.Storage{}
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
}
