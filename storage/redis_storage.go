package storage

import (
	"context"
	"errors"

	"github.com/redis/go-redis/v9"
)

type RedisStorage struct {
	client *redis.Client
}

// NewRedisStorage creates a new Redis storage instance
func NewRedisStorage(addr string, password string, db int) (*RedisStorage, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	})

	// Test the connection
	ctx := context.Background()
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, err
	}

	return &RedisStorage{
		client: client,
	}, nil
}

// Save stores a key-value pair in Redis.
// Returns AlreadyExistsErr if the key already exists.
func (storage *RedisStorage) Save(key string, value string) error {
	ctx := context.Background()

	// Try to set the key only if it doesn't exist
	success, err := storage.client.SetNX(ctx, key, value, 0).Result()
	if err != nil {
		return err
	}

	if !success {
		return AlreadyExistsErr
	}

	return nil
}

// Get retrieves a value by key from Redis.
// Returns NotFoundErr if the key does not exist.
func (storage *RedisStorage) Get(key string) (string, error) {
	ctx := context.Background()

	value, err := storage.client.Get(ctx, key).Result()
	if errors.Is(err, redis.Nil) {
		return "", NotFoundErr
	}
	if err != nil {
		return "", err
	}

	return value, nil
}
