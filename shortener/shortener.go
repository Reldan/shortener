package shortener

import (
	"errors"
	"fmt"
	"math/rand"
	"shortener/storage"
)

type Table interface {
	Save(key string, value string) error
	Get(key string) (string, error)
}

type Shortener struct {
	Table Table
}

var letters = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func randomShortString() string {
	n := 2
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

func (shortener Shortener) Shorten(url string) (string, error) {
	retryCount := 3
	possibleUrl := randomShortString()
	var err error
	for i := 0; i < retryCount; i++ {
		err = shortener.Table.Save(possibleUrl, url)
		if errors.Is(err, storage.AlreadyExistsErr) {
			fmt.Printf("Retrying short url '%s' already exists\n", possibleUrl)
			possibleUrl = randomShortString()
			continue
		}
		break
	}

	return possibleUrl, err
}

func (shortener Shortener) Unshorten(shortURL string) (string, error) {
	return shortener.Table.Get(shortURL)
}
