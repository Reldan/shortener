package storage

import (
	"fmt"
	"sync"
)

var AlreadyExistsErr = fmt.Errorf("already exists")
var NotFoundErr = fmt.Errorf("not found")

type Storage struct {
	m sync.Map
}

func (storage *Storage) Save(key string, value string) error {
	_, loaded := storage.m.LoadOrStore(key, value)
	if loaded {
		return AlreadyExistsErr
	}
	return nil
}

func (storage *Storage) Get(key string) (string, error) {
	value, ok := storage.m.Load(key)
	if !ok {
		return "", NotFoundErr
	}
	return value.(string), nil
}
